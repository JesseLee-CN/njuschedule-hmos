/**
 * 课程详情页（`NavPathStack` 路由名 `course-detail`，参数 `CourseDetailParam`）。
 *
 * - 根节点是 `HdsNavDestination`：外壳 `HdsNavigation` 的 `destinationBuilder`
 *   直接渲染本组件，标题栏与返回键由 HDS 提供。
 * - 路由参数从 `onReady(ctx).pathInfo.param` 取（外壳 builder 不传 props）；
 *   同时保留 `courseId` prop 入口，便于外壳显式指定。
 * - 编辑页返回后靠 `onShown` 重载；删除走 AlertDialog 二次确认。
 */
import { resolveNavStack } from '../../common/NavStackResolver';
import { Feedback } from '../../common/ui/Feedback';
import { HdsNavDestination } from '@kit.UIDesignKit';
import { Course } from '../../data/models/Models';
import { CourseRepository } from '../../data/CourseRepository';
import { ColorPool } from '../../data/ColorPool';
import { AppState } from '../../app/AppState';
import { CourseDetailParam, CourseEditParam } from '../../common/RouteParams';
import { LegacyConstant } from '../../common/Constants';
import { Colors, FontSize, HdsMetrics, Radius, Spacing } from '../../common/design/Tokens';
import { hdsSubPageTitleBar } from '../../common/ui/HdsSubPage';
import { AppStore } from '../../app/AppStore';
import { EmptyState } from '../../common/ui/EmptyState';
import { StatusBadge, BadgeTone } from '../../common/ui/StatusBadge';
import { WeeksFormat } from '../timetable/WeeksFormat';
import { CourseFormat } from './CourseFormat';

@ComponentV2
export struct CourseDetailPage {
  @Local store: AppStore = AppStore.connect();

  /** 课程行 `id`（= CourseRepository 的主键）；外壳显式传入时优先于路由参数。 */
  /** 路由参数里的课程 id（@Param 不可回写，用本地状态承接）。 */
  @Local pageCourseId: number = 0;
  /** 外壳可选传入的导航栈；正常走 onReady 里的 pathStack。 */
  @Param pageStack: NavPathStack = new NavPathStack();

  @Local course: Course = new Course();
  @Local found: boolean = false;
  @Local loaded: boolean = false;
  @Local accentColor: string = '';
  @Local deleteError: string = '';

  private stack: NavPathStack | null = null;
  private scroller: Scroller = new Scroller();

  private navStack(): NavPathStack {
    return resolveNavStack(this.stack, this.pageStack);
  }

  private async load(): Promise<void> {
    const courseId: number = this.pageCourseId;
    if (courseId <= 0) {
      this.loaded = true;
      this.found = false;
      return;
    }
    try {
      const pool: number[] = await ColorPool.get();
      const course: Course | null = await CourseRepository.getById(courseId);
      if (course === null) {
        this.found = false;
      } else {
        this.course = course;
        this.accentColor = ColorPool.resolve(course, pool);
        this.found = true;
        this.deleteError = '';
      }
    } catch (err) {
      this.found = false;
    }
    this.loaded = true;
  }

  private openEdit(): void {
    this.navStack().pushPathByName('course-edit', new CourseEditParam(this.course.tableId, this.course.id));
  }

  private confirmDelete(): void {
    const name: string = this.course.name;
    Feedback.confirmDanger(this.getUIContext(), '删除课程', `确定删除「${name}」吗？删除后不可恢复。`, '删除', () => {
      this.deleteCourse();
    });
  }

  private async deleteCourse(): Promise<void> {
    try {
      await CourseRepository.delete(this.pageCourseId);
      AppState.bumpDataRevision();
      this.navStack().pop();
    } catch (err) {
      this.deleteError = '删除失败，请重试';
    }
  }

  @Builder
  headerCard() {
    Column({ space: Spacing.Sm }) {
      Row({ space: Spacing.Sm }) {
        Column()
          .width(12)
          .height(12)
          .borderRadius(Radius.Round)
          .backgroundColor(this.accentColor)
        Text(this.course.name)
          .fontSize(FontSize.Headline)
          .fontWeight(FontWeight.Medium)
          .fontColor(Colors.TextPrimary)
          .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Row({ space: Spacing.Sm }) {
        StatusBadge({
          text: WeeksFormat.importTypeLabel(this.course.importType),
          tone: this.course.importType === LegacyConstant.ADD_MANUALLY ? BadgeTone.Neutral : BadgeTone.Primary
        })
        StatusBadge({
          text: WeeksFormat.describe(this.course.weeks),
          tone: BadgeTone.Success
        })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text(CourseFormat.courseTimeText(this.course))
        .fontSize(FontSize.Body)
        .fontColor(Colors.TextSecondary)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(Spacing.Lg)
    .backgroundColor(Colors.Surface)
    .borderRadius(Radius.Lg)
    .border({ width: 1, color: Colors.OutlineLight })
  }

  @Builder
  detailRow(label: string, value: string) {
    Row({ space: Spacing.Md }) {
      Text(label)
        .fontSize(FontSize.BodySm)
        .fontColor(Colors.TextTertiary)
        .width(64)
      Text(value)
        .fontSize(FontSize.Body)
        .fontColor(Colors.TextPrimary)
        .layoutWeight(1)
        .textAlign(TextAlign.Start)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  detailCard() {
    Column({ space: Spacing.Md }) {
      this.detailRow('教师', this.course.teacher.trim() !== '' ? this.course.teacher : '未填写')
      this.detailRow('地点', this.course.classroom.trim() !== '' ? this.course.classroom : '未填写')
      if (this.course.testTime.trim() !== '') {
        this.detailRow('考试时间', this.course.testTime)
      }
      if (this.course.testLocation.trim() !== '') {
        this.detailRow('考试地点', this.course.testLocation)
      }
      if (this.course.info.trim() !== '') {
        Divider()
          .color(Colors.OutlineLight)
        Text('备注')
          .fontSize(FontSize.BodySm)
          .fontColor(Colors.TextTertiary)
        Text(this.course.info)
          .fontSize(FontSize.Body)
          .fontColor(Colors.TextPrimary)
          .width('100%')
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(Spacing.Lg)
    .backgroundColor(Colors.Surface)
    .borderRadius(Radius.Lg)
    .border({ width: 1, color: Colors.OutlineLight })
  }

  @Builder
  actionsCard() {
    Column({ space: Spacing.Sm }) {
      Row({ space: Spacing.Md }) {
        Button('编辑课程')
          .fontSize(FontSize.BodySm)
          .fontColor(this.store.accentOn)
          .backgroundColor(this.store.accentDisplay)
          .height(40)
          .layoutWeight(1)
          .onClick(() => {
            this.openEdit();
          })
        Button('删除课程')
          .fontSize(FontSize.BodySm)
          .fontColor(Colors.Error)
          .backgroundColor(Colors.ErrorLight)
          .height(40)
          .layoutWeight(1)
          .onClick(() => {
            this.confirmDelete();
          })
      }
      .width('100%')

      if (this.deleteError !== '') {
        Text(this.deleteError)
          .fontSize(FontSize.Caption)
          .fontColor(Colors.Error)
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  @Builder
  contentBody() {
    Scroll(this.scroller) {
      Row() {
        Column({ space: Spacing.Lg }) {
          this.headerCard()
          this.detailCard()
          this.actionsCard()
        }
        .width('100%')
        .constraintSize({ maxWidth: 720 })
        .padding({
          left: Spacing.Lg,
          right: Spacing.Lg,
          // HdsNavDestination 的标题栏覆盖在内容上：让出标题栏高度，避免卡片被标题压住。
          top: HdsMetrics.contentTopInset(px2vp(this.store.windowTopInset)) + Spacing.Lg,
          bottom: Spacing.Xxxl
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .layoutWeight(1)
    .align(Alignment.Top)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }

  @Builder
  missingBody() {
    EmptyState({
      title: '课程不存在',
      description: '该课程可能已被删除，或课程数据尚未加载完成',
      actionText: '返回',
      onAction: () => {
        this.navStack().pop();
      }
    })
  }

  build() {
    HdsNavDestination() {
      Column() {
        if (!this.loaded) {
          Column() {
            LoadingProgress()
              .width(36)
              .height(36)
              .color(this.store.accentDisplay)
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else if (!this.found) {
          Column() {
            this.missingBody()
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          this.contentBody()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Colors.Background)
    }
    .titleBar(hdsSubPageTitleBar('课程详情'))
    .bindToScrollable([this.scroller])
    .onReady((ctx: NavDestinationContext) => {
      this.stack = ctx.pathStack;
      const raw: Object | undefined = ctx.pathInfo.param as Object;
      if (raw instanceof CourseDetailParam && this.pageCourseId <= 0) {
        this.pageCourseId = raw.courseId;
      }
      this.load();
    })
    // 首次显示与从编辑页返回都会触发：重载一次拿到最新数据。
    .onShown(() => {
      this.load();
    })
  }
}
