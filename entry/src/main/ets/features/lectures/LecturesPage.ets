/**
 * 讲座页：拉取旧版讲座后端（`lecture.idealclover.cn`），支持按校区筛选、分页，
 * 一键把讲座加入当前课表（`import_type = ADD_BY_LECTURE`）。
 *
 * 数据/接口在 `data/Lecture.ets`；加入课表后的周次按讲座开始日期自动换算。
 */
import { HdsNavDestination, HdsNavigationMenuContentOptions, HdsNavigationTitleBarOptions } from '@kit.UIDesignKit';
import { AppState } from '../../app/AppState';
import { DateUtils } from '../../common/DateUtils';
import { LegacyConfig, LegacyConstant } from '../../common/Constants';
import { Colors, FontSize, HdsMetrics, Radius, Spacing } from '../../common/design/Tokens';
import { Feedback } from '../../common/ui/Feedback';
import { AppStore } from '../../app/AppStore';
import { CourseRepository } from '../../data/CourseRepository';
import { Lecture, LectureApi, LecturePage } from '../../data/Lecture';
import { Course } from '../../data/models/Models';
import { WeekUtil } from '../../data/WeekUtil';
import { EmptyState } from '../../common/ui/EmptyState';
import { hdsSubPageTitleBar } from '../../common/ui/HdsSubPage';
import { ArrayDataSource } from '../../common/ui/ArrayDataSource';

@ComponentV2
export struct LecturesPage {
  /** V2 全局 Store（主题色 / 避让区 / 当前课表）。 */
  @Local store: AppStore = AppStore.connect();

  @Local lectures: Lecture[] = [];
  /** List + LazyForEach 数据源（讲座分页可能很长，避免一次构建全部卡片）。 */
  private lecturesSource: ArrayDataSource<Lecture> = new ArrayDataSource<Lecture>();
  @Local tags: string[] = [];
  @Local selectedTag: string = '';
  @Local page: number = 1;
  @Local totalPage: number = 1;
  @Local loading: boolean = true;
  @Local loadingMore: boolean = false;
  @Local errorText: string = '';
  @Local addingId: number = 0;

  private scroller: Scroller = new Scroller();

  aboutToAppear(): void {
    this.refresh();
  }

  private async refresh(): Promise<void> {
    this.loading = true;
    this.errorText = '';
    this.page = 1;
    try {
      if (this.tags.length === 0) {
        this.tags = await LectureApi.getTags();
      }
      const result: LecturePage = await LectureApi.getPage(1, 10, this.selectedTag);
      this.lectures = result.data;
      this.lecturesSource.setData(this.lectures);
      this.totalPage = result.totalPage;
      this.page = 1;
    } catch (err) {
      this.errorText = '讲座列表加载失败，请检查网络后重试';
      this.lectures = [];
      this.lecturesSource.setData(this.lectures);
    } finally {
      this.loading = false;
    }
  }

  private async loadMore(): Promise<void> {
    if (this.loadingMore || this.page >= this.totalPage) {
      return;
    }
    this.loadingMore = true;
    try {
      const next: number = this.page + 1;
      const result: LecturePage = await LectureApi.getPage(next, 10, this.selectedTag);
      this.lectures = this.lectures.concat(result.data);
      this.lecturesSource.setData(this.lectures);
      this.page = next;
      this.totalPage = result.totalPage;
    } catch (err) {
      Feedback.toast(this.getUIContext(), '加载更多失败');
    } finally {
      this.loadingMore = false;
    }
  }

  private selectTag(tag: string): void {
    if (this.selectedTag === tag) {
      return;
    }
    this.selectedTag = tag;
    this.refresh();
  }

  private startDate(lecture: Lecture): Date {
    const parsed: Date = new Date(lecture.startTime);
    return isNaN(parsed.getTime()) ? new Date() : parsed;
  }

  private endDate(lecture: Lecture): Date {
    const parsed: Date = new Date(lecture.endTime);
    return isNaN(parsed.getTime()) ? this.startDate(lecture) : parsed;
  }

  private isExpired(lecture: Lecture): boolean {
    return new Date().getTime() > this.endDate(lecture).getTime();
  }

  /** 讲座正文预览：去掉与卡片重复的「时间/特殊要求/其他信息」行，压成一段。 */
  private infoPreview(lecture: Lecture): string {
    const lines: string[] = lecture.info.split('\n');
    const kept: string[] = [];
    for (let i = 0; i < lines.length; i++) {
      const line: string = lines[i].trim();
      if (line === '' || line.startsWith('时间：') || line.startsWith('特殊要求') ||
        line.startsWith('其他信息')) {
        continue;
      }
      kept.push(line.startsWith('讲座内容：') ? line.substring('讲座内容：'.length) : line);
    }
    let text: string = kept.join(' ');
    if (text.length > 110) {
      text = `${text.substring(0, 110)}…`;
    }
    return text;
  }

  private timeText(lecture: Lecture): string {
    const start: Date = this.startDate(lecture);
    const end: Date = this.endDate(lecture);
    return `${DateUtils.formatMonthDay(start)} ${DateUtils.formatHm(start)}-${DateUtils.formatHm(end)}`;
  }

  private async addToTable(lecture: Lecture): Promise<void> {
    if (this.addingId !== 0) {
      return;
    }
    if (this.isExpired(lecture)) {
      Feedback.toast(this.getUIContext(), '讲座已结束，无法加入课表');
      return;
    }
    this.addingId = lecture.id;
    try {
      const tableId: number = this.store.tableId > 0 ? this.store.tableId : 1;
      const exists: boolean = await CourseRepository.checkHasCourseByName(tableId, lecture.title);
      if (exists) {
        Feedback.toast(this.getUIContext(), '这门讲座已在课表中');
        return;
      }
      const week: number = await WeekUtil.getWeekNumOfDay(this.startDate(lecture));
      if (week < 1 || week > LegacyConfig.MAX_WEEKS) {
        Feedback.toast(this.getUIContext(), '讲座周次超出范围，无法加入');
        return;
      }
      const course: Course = new Course(lecture.title, tableId);
      course.weeks = [week];
      course.weekTime = DateUtils.weekdayOneBased(this.startDate(lecture));
      course.startTime = lecture.startIndex;
      course.timeCount = Math.max(lecture.endIndex - lecture.startIndex, 0);
      course.importType = LegacyConstant.ADD_BY_LECTURE;
      course.teacher = lecture.teacher;
      course.classroom = lecture.classroom;
      course.info = lecture.info;
      course.courseId = -1;
      await CourseRepository.insert(course);
      AppState.bumpDataRevision();
      LectureApi.addCount(lecture.id);
      lecture.count += 1;
      Feedback.toast(this.getUIContext(), '已加入课表');
    } catch (err) {
      console.error(`[Lecture] add failed: ${JSON.stringify(err)}`);
      Feedback.toast(this.getUIContext(), '加入课表失败');
    } finally {
      this.addingId = 0;
    }
  }


  @Builder
  private tagChips() {
    Scroll() {
      Row({ space: Spacing.Sm }) {
        this.tagChip('全部', '')
        ForEach(this.tags, (tag: string) => {
          this.tagChip(tag, tag)
        }, (tag: string) => `tag-${tag}`)
      }
      .padding({ left: Spacing.Lg, right: Spacing.Lg })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .height(40)
  }

  @Builder
  private tagChip(label: string, tag: string) {
    Text(label)
      .fontSize(FontSize.BodySm)
      .fontColor(this.selectedTag === tag ? this.store.accentOn : Colors.TextSecondary)
      .backgroundColor(this.selectedTag === tag ? this.store.accentDisplay : Colors.SurfaceHigh)
      .borderRadius(Radius.Round)
      .padding({ left: Spacing.Md, right: Spacing.Md, top: 6, bottom: 6 })
      .onClick(() => {
        this.selectTag(tag);
      })
  }

  @Builder
  private lectureCard(lecture: Lecture) {
    Column({ space: Spacing.Sm }) {
      Row({ space: Spacing.Sm }) {
        Text(lecture.title)
          .fontSize(FontSize.Body)
          .fontWeight(FontWeight.Medium)
          .fontColor(Colors.TextPrimary)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
        if (this.isExpired(lecture)) {
          Text('已结束')
            .fontSize(FontSize.Caption)
            .fontColor(Colors.TextTertiary)
            .backgroundColor(Colors.SurfaceHigh)
            .borderRadius(Radius.Xs)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      Row({ space: Spacing.Xs }) {
        SymbolGlyph($r('sys.symbol.clock'))
          .fontSize(13)
          .fontColor([Colors.TextTertiary])
        Text(this.timeText(lecture))
          .fontSize(FontSize.Caption)
          .fontColor(Colors.TextSecondary)
      }

      Row({ space: Spacing.Xs }) {
        SymbolGlyph($r('sys.symbol.house'))
          .fontSize(13)
          .fontColor([Colors.TextTertiary])
        Text(lecture.classroom === '' ? '地点待定' : lecture.classroom)
          .fontSize(FontSize.Caption)
          .fontColor(Colors.TextTertiary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
      }

      if (lecture.teacher !== '') {
        Text(lecture.teacher)
          .fontSize(FontSize.Caption)
          .fontColor(Colors.TextTertiary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }

      if (this.infoPreview(lecture) !== '') {
        Text(this.infoPreview(lecture))
          .fontSize(FontSize.Caption)
          .fontColor(Colors.TextTertiary)
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .lineHeight(17)
          .width('100%')
      }

      Row({ space: Spacing.Sm }) {
        Text(`第 ${lecture.startIndex}-${lecture.endIndex} 节`)
          .fontSize(FontSize.Caption)
          .fontColor(Colors.TextTertiary)
        Blank()
        if (lecture.count > 0) {
          Text(`${lecture.count} 人加入`)
            .fontSize(FontSize.Caption)
            .fontColor(Colors.TextTertiary)
        }
        Button(this.addingId === lecture.id ? '加入中…' : (this.isExpired(lecture) ? '已结束' : '加入课表'))
          .height(32)
          .fontSize(FontSize.Caption)
          .backgroundColor(this.isExpired(lecture) ? Colors.SurfaceHigh :
            this.store.accentDisplay)
          .fontColor(this.isExpired(lecture) ? Colors.TextTertiary :
            this.store.accentOn)
          .enabled(!this.isExpired(lecture) && this.addingId === 0)
          .onClick(() => {
            this.addToTable(lecture);
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding(Spacing.Lg)
    .backgroundColor(Colors.Surface)
    .borderRadius(Radius.Lg)
    .border({ width: 1, color: Colors.OutlineLight })
    .alignItems(HorizontalAlign.Start)
  }

  private titleBarOptions(): HdsNavigationTitleBarOptions {
    const menu: HdsNavigationMenuContentOptions = {
      value: [{
        content: {
          icon: $r('sys.symbol.arrow_clockwise'),
          label: '刷新',
          action: () => {
            this.refresh();
          }
        }
      }]
    };
    return hdsSubPageTitleBar('讲座', '南大讲座信息，可一键加入课表', menu);
  }

  build() {
    HdsNavDestination() {
      Column() {
        if (this.loading) {
          Column() {
            LoadingProgress()
              .width(36)
              .height(36)
              .color(this.store.accentDisplay)
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ top: HdsMetrics.contentTopInset(px2vp(this.store.windowTopInset)) })
          .justifyContent(FlexAlign.Center)
        } else if (this.errorText !== '') {
          Column() {
            EmptyState({
              title: '加载失败',
              description: this.errorText,
              icon: $r('sys.symbol.exclamationmark_circle'),
              actionText: '重试',
              onAction: () => {
                this.refresh();
              }
            })
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ top: HdsMetrics.contentTopInset(px2vp(this.store.windowTopInset)) })
          .justifyContent(FlexAlign.Center)
        } else {
          List({ space: Spacing.Md, scroller: this.scroller }) {
            ListItem() {
              Column() {
                this.tagChips()
              }
              .width('100%')
              .padding({
                left: Spacing.Lg,
                right: Spacing.Lg,
                top: HdsMetrics.contentTopInset(px2vp(this.store.windowTopInset)) + Spacing.Sm
              })
            }
            LazyForEach(this.lecturesSource, (lecture: Lecture) => {
              ListItem() {
                Column() {
                  this.lectureCard(lecture)
                }
                .width('100%')
                .padding({ left: Spacing.Lg, right: Spacing.Lg })
              }
            }, (lecture: Lecture) => `lecture-${lecture.id}`)
            if (this.page < this.totalPage) {
              ListItem() {
                Row() {
                  Button(this.loadingMore ? '加载中…' : '加载更多')
                    .width('100%')
                    .height(40)
                    .fontSize(FontSize.BodySm)
                    .backgroundColor(Colors.SurfaceHigh)
                    .fontColor(Colors.TextSecondary)
                    .enabled(!this.loadingMore)
                    .onClick(() => {
                      this.loadMore();
                    })
                }
                .width('100%')
                .padding({ left: Spacing.Lg, right: Spacing.Lg })
              }
            }
            if (this.lectures.length === 0) {
              ListItem() {
                Text('暂无讲座')
                  .fontSize(FontSize.BodySm)
                  .fontColor(Colors.TextTertiary)
                  .width('100%')
                  .textAlign(TextAlign.Center)
                  .padding({ top: Spacing.Xxxl })
              }
            }
            ListItem() {
              Row()
                .width('100%')
                .height(Spacing.Xxl)
            }
          }
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
          .cachedCount(2)
          .layoutWeight(1)
          .width('100%')
          .align(Alignment.TopStart)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Colors.Background)
    }
    .titleBar(this.titleBarOptions())
    .bindToScrollable([this.scroller])
  }
}
