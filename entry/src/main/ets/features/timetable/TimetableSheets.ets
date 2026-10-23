/**
 * 课表周视图的四个半模态内容（TimetableView 的 bindSheet 内容）。
 *
 * 从 TimetableView.ets 拆分而来：bindSheet 开关、数据准备、跳转/删除/切换课表等父组件逻辑
 * 仍留在 TimetableView；内容组件只通过 @Param 接收数据、@Event 回传操作，行为/布局/样式/文案不变。
 * - DetailSheetContent：课程详情（编辑 / 删除入口）；
 * - MultiSheetContent：同一时段多门课程列表（点选打开详情）；
 * - FreeCourseSheetContent：自由时间课程列表（左右滑动分页，点卡片打开详情）；
 * - WeekPickerSheetContent：切换课表 + 课程周数（对齐系统日历「切换课表」样式）。
 *
 * 原来直接从父组件读的全局 Store（主题色高亮、半模态开关）改为：主题色用组件内
 * @Local store 直接连接（与拆分前一致），开关由父组件通过 @Event 收口。
 */
import { AppStore } from '../../app/AppStore';
import { ClassPeriod, LegacyConfig } from '../../common/Constants';
import { Colors, FontSize, Radius, Spacing } from '../../common/design/Tokens';
import { ColorPool } from '../../data/ColorPool';
import { Course, CourseTable } from '../../data/models/Models';
import { WeeksFormat } from './WeeksFormat';

/** 课程详情半模态内容（对齐系统日历半模态样式）。 */
@ComponentV2
export struct DetailSheetContent {
  /** V2 全局 Store（主题色：编辑入口文字）。 */
  @Local store: AppStore = AppStore.connect();
  /** 要展示的课程。 */
  @Param course: Course = new Course();
  /** 当前课表作息（拼「时间」行的具体起止时间）。 */
  @Param periods: ClassPeriod[] = [];
  /** 课程配色池（课程图标颜色）。 */
  @Param pool: number[] = [];
  /** 关闭半模态（父组件负责收起 bindSheet）。 */
  @Event onClose: () => void = () => {
  };
  /** 进入课程编辑页（父组件负责收 sheet + 路由跳转）。 */
  @Event onEdit: (course: Course) => void = () => {
  };
  /** 删除课程（父组件负责二次确认、删库与刷新）。 */
  @Event onDelete: (course: Course) => void = () => {
  };

  /** 课程详情里的「标签：内容」行（内联样式，对齐系统日历）。 */
  @Builder
  private detailTextLine(label: string, value: string) {
    Row({ space: 2 }) {
      Text(`${label}：`)
        .fontSize(FontSize.Body)
        .fontColor(Colors.TextTertiary)
      Text(value === '' ? '—' : value)
        .fontSize(FontSize.Body)
        .fontColor(Colors.TextSecondary)
        .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }

  /** 时间文案：周三 第 5 - 6 节(14:00-15:50)。 */
  private detailTimeText(): string {
    const course: Course = this.course;
    const weekday: string = WeeksFormat.weekdayLabel(course.weekTime);
    const periods: string = WeeksFormat.periodLabel(course);
    const startIndex: number = course.startTime - 1;
    const endIndex: number = Math.min(course.startTime + course.timeCount - 1, this.periods.length - 1);
    if (startIndex >= 0 && endIndex >= startIndex) {
      const start: string = this.periods[startIndex].start;
      const end: string = this.periods[endIndex].end;
      if (start !== '' && end !== '') {
        return `${weekday} ${periods}(${start}-${end})`;
      }
    }
    return `${weekday} ${periods}`;
  }

  build() {
    Column({ space: Spacing.Lg }) {
      // 标题栏：课程详情 + 关闭（对齐系统日历半模态样式）
      Row() {
        Text('课程详情')
          .fontSize(FontSize.Headline)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.TextPrimary)
          .layoutWeight(1)
        Button({ type: ButtonType.Circle }) {
          SymbolGlyph($r('sys.symbol.xmark'))
            .fontSize(18)
            .fontColor([Colors.TextPrimary])
        }
        .width(40)
        .height(40)
        .backgroundColor(Colors.SurfaceHigh)
        .onClick(() => {
          this.onClose();
        })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 课程信息卡：图标 + 课名 + 编辑
      Column({ space: Spacing.Sm }) {
        Row({ space: Spacing.Md }) {
          Row() {
            SymbolGlyph($r('sys.symbol.book'))
              .fontSize(18)
              .fontColor([ColorPool.resolve(this.course, this.pool)])
          }
          .width(36)
          .height(36)
          .borderRadius(Radius.Md)
          .backgroundColor(Colors.SurfaceHigh)
          .justifyContent(FlexAlign.Center)

          Text(this.course.name)
            .fontSize(FontSize.Title)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.TextPrimary)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          Text('编辑')
            .fontSize(FontSize.BodySm)
            .fontColor(this.store.accentDisplay)
            .padding({ left: Spacing.Md, right: Spacing.Md, top: Spacing.Xs, bottom: Spacing.Xs })
            .backgroundColor(Colors.SurfaceHigh)
            .borderRadius(Radius.Round)
            .onClick(() => {
              this.onEdit(this.course);
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        this.detailTextLine('时间', this.detailTimeText())
        this.detailTextLine('周次', WeeksFormat.describe(this.course.weeks))
        if (this.course.classroom !== '') {
          this.detailTextLine('教室', this.course.classroom)
        }
        if (this.course.teacher !== '') {
          this.detailTextLine('教师', this.course.teacher)
        }
        if (this.course.testTime !== '' || this.course.testLocation !== '') {
          this.detailTextLine('考试', `${this.course.testTime} ${this.course.testLocation}`.trim())
        }
        if (this.course.info !== '') {
          this.detailTextLine('备注', this.course.info)
        }
        this.detailTextLine('来源', WeeksFormat.importTypeLabel(this.course.importType))
      }
      .width('100%')
      .padding(Spacing.Lg)
      .backgroundColor(Colors.Surface)
      .borderRadius(Radius.Lg)
      .border({ width: 1, color: Colors.OutlineLight })
      .alignItems(HorizontalAlign.Start)

      // 操作卡：删除课程
      Column() {
        Row({ space: Spacing.Sm }) {
          SymbolGlyph($r('sys.symbol.trash'))
            .fontSize(18)
            .fontColor([Colors.Error])
          Text('删除课程')
            .fontSize(FontSize.Body)
            .fontColor(Colors.Error)
            .layoutWeight(1)
        }
        .width('100%')
        .padding(Spacing.Lg)
        .onClick(() => {
          this.onDelete(this.course);
        })
      }
      .width('100%')
      .backgroundColor(Colors.Surface)
      .borderRadius(Radius.Lg)
      .border({ width: 1, color: Colors.OutlineLight })
    }
    .width('100%')
    .padding({ left: Spacing.Xl, right: Spacing.Xl, top: Spacing.Xl, bottom: Spacing.Xxl })
    .alignItems(HorizontalAlign.Start)
  }
}

/** 同一时段多门课程的半模态内容。 */
@ComponentV2
export struct MultiSheetContent {
  /** 同一时段的课程组（冲突课程）。 */
  @Param group: Course[] = [];
  /** 课程配色池。 */
  @Param pool: number[] = [];
  /** 点选某门课程（父组件打开课程详情）。 */
  @Event onSelect: (course: Course) => void = () => {
  };

  build() {
    Column({ space: Spacing.Sm }) {
      Text('同一时段有多个课程')
        .fontSize(FontSize.Title)
        .fontWeight(FontWeight.Bold)
        .fontColor(Colors.TextPrimary)
        .width('100%')
        .margin({ bottom: Spacing.Sm })
      ForEach(this.group, (course: Course) => {
        Row({ space: Spacing.Sm }) {
          Row()
            .width(10)
            .height(10)
            .borderRadius(Radius.Round)
            .backgroundColor(ColorPool.resolve(course, this.pool))
          Column({ space: 2 }) {
            Text(course.name)
              .fontSize(FontSize.Body)
              .fontColor(Colors.TextPrimary)
              .maxLines(1)
            Text(`${WeeksFormat.weekdayLabel(course.weekTime)} ${WeeksFormat.periodLabel(course)} · ${WeeksFormat.describe(course.weeks)}`)
              .fontSize(FontSize.Caption)
              .fontColor(Colors.TextTertiary)
              .maxLines(1)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize(16)
            .fontColor([Colors.TextTertiary])
        }
        .width('100%')
        .padding(Spacing.Md)
        .backgroundColor(Colors.SurfaceHigh)
        .borderRadius(Radius.Md)
        .onClick(() => {
          this.onSelect(course);
        })
      }, (course: Course) => `multi-${course.id}`)
    }
    .width('100%')
    .padding(Spacing.Xl)
    .alignItems(HorizontalAlign.Start)
  }
}

/** 底部半模态：自由时间课程列表（迷你栏点击后打开，左右滑动分页查看）。 */
@ComponentV2
export struct FreeCourseSheetContent {
  /** 本周自由时间课程。 */
  @Param courses: Course[] = [];
  /** 当前 Swiper 页下标（父组件持有，打开时重置为 0）。 */
  @Param sheetIndex: number = 0;
  /** 课程配色池。 */
  @Param pool: number[] = [];
  /** 关闭半模态（父组件负责收起 bindSheet）。 */
  @Event onClose: () => void = () => {
  };
  /** Swiper 翻页回调（父组件记录下标，用于「N / 总数」文案）。 */
  @Event onIndexChange: (index: number) => void = () => {
  };
  /** 点卡片打开课程详情（父组件先收起本 sheet，再开详情半模态）。 */
  @Event onOpenCourse: (course: Course) => void = () => {
  };

  /** 课程详情里的「标签：内容」行（内联样式，对齐系统日历）。 */
  @Builder
  private detailTextLine(label: string, value: string) {
    Row({ space: 2 }) {
      Text(`${label}：`)
        .fontSize(FontSize.Body)
        .fontColor(Colors.TextTertiary)
      Text(value === '' ? '—' : value)
        .fontSize(FontSize.Body)
        .fontColor(Colors.TextSecondary)
        .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }

  build() {
    Column({ space: Spacing.Lg }) {
      Row() {
        Column({ space: 2 }) {
          Text('自由时间课程')
            .fontSize(FontSize.Headline)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.TextPrimary)
          Text(`共 ${this.courses.length} 门 · 左右滑动查看`)
            .fontSize(FontSize.Caption)
            .fontColor(Colors.TextTertiary)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Button({ type: ButtonType.Circle }) {
          SymbolGlyph($r('sys.symbol.xmark'))
            .fontSize(18)
            .fontColor([Colors.TextPrimary])
        }
        .width(40)
        .height(40)
        .backgroundColor(Colors.SurfaceHigh)
        .onClick(() => {
          this.onClose();
        })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      if (this.courses.length === 0) {
        Text('本周没有自由时间课程')
          .fontSize(FontSize.Body)
          .fontColor(Colors.TextTertiary)
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: Spacing.Xxl, bottom: Spacing.Xxl })
      } else {
        Swiper() {
          ForEach(this.courses, (course: Course) => {
            Column({ space: Spacing.Sm }) {
              Row({ space: Spacing.Sm }) {
                Row()
                  .width(10)
                  .height(10)
                  .borderRadius(Radius.Round)
                  .backgroundColor(ColorPool.resolve(course, this.pool))
                Text(course.name)
                  .fontSize(FontSize.Title)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Colors.TextPrimary)
                  .maxLines(2)
                  .layoutWeight(1)
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)

              this.detailTextLine('时间', `${WeeksFormat.weekdayLabel(course.weekTime)} ${WeeksFormat.periodLabel(course)}`)
              this.detailTextLine('周次', WeeksFormat.describe(course.weeks))
              if (course.classroom !== '') {
                this.detailTextLine('地点', course.classroom)
              }
              if (course.teacher !== '') {
                this.detailTextLine('教师', course.teacher)
              }

              Text('点击卡片查看课程详情或编辑/删除')
                .fontSize(FontSize.Caption)
                .fontColor(Colors.TextTertiary)
                .margin({ top: Spacing.Sm })
            }
            .width('100%')
            .padding(Spacing.Lg)
            .backgroundColor(Colors.Surface)
            .borderRadius(Radius.Lg)
            .border({ width: 1, color: Colors.OutlineLight })
            .alignItems(HorizontalAlign.Start)
            .onClick(() => {
              // 复用课表网格的课程详情半模态（编辑/删除等操作与原有课程完全一致）
              this.onOpenCourse(course);
            })
          }, (course: Course) => `free-sheet-${course.id}`)
        }
        .width('100%')
        .height(240)
        .indicator(false)
        .loop(false)
        .onChange((index: number) => {
          this.onIndexChange(index);
        })

        Text(`${this.sheetIndex + 1} / ${this.courses.length}`)
          .fontSize(FontSize.Caption)
          .fontColor(Colors.TextTertiary)
          .width('100%')
          .textAlign(TextAlign.Center)
      }
    }
    .width('100%')
    .padding({ left: Spacing.Xl, right: Spacing.Xl, top: Spacing.Xl, bottom: Spacing.Xxl })
    .alignItems(HorizontalAlign.Start)
  }
}

/** 底部半模态：切换课表 + 课程周数（对齐系统日历「切换课表」样式）。 */
@ComponentV2
export struct WeekPickerSheetContent {
  /** V2 全局 Store（主题色：选中的课表 / 周次高亮）。 */
  @Local store: AppStore = AppStore.connect();
  /** 全部课表（学期）。 */
  @Param tables: CourseTable[] = [];
  /** 当前选中的课表 id（父组件持有，确认后应用）。 */
  @Param selectedTableId: number = 0;
  /** 当前选中的周次（父组件持有，确认后应用）。 */
  @Param selectedWeek: number = 1;
  /** 关闭半模态（父组件负责收起 bindSheet）。 */
  @Event onClose: () => void = () => {
  };
  /** 点选课表 chip（父组件更新选中 id）。 */
  @Event onSelectTable: (tableId: number) => void = () => {
  };
  /** 点选周次（父组件更新选中周次）。 */
  @Event onSelectWeek: (week: number) => void = () => {
  };
  /** 点「+」新建课表（父组件收起 sheet 并跳转课表管理页）。 */
  @Event onOpenTables: () => void = () => {
  };
  /** 点「✓」确认切换（父组件应用选中课表与周次）。 */
  @Event onConfirm: () => void = () => {
  };

  private weekOptions(): number[] {
    const options: number[] = [];
    for (let i = 1; i <= LegacyConfig.MAX_WEEKS; i++) {
      options.push(i);
    }
    return options;
  }

  build() {
    Column() {
      // 标题栏：关闭 / 标题 / 新建 / 确定（半模态 Sheet 自绘标题栏）
      Row({ space: Spacing.Md }) {
        Button({ type: ButtonType.Circle }) {
          SymbolGlyph($r('sys.symbol.xmark'))
            .fontSize(18)
            .fontColor([Colors.TextPrimary])
        }
        .width(40)
        .height(40)
        .backgroundColor(Colors.SurfaceHigh)
        .onClick(() => {
          this.onClose();
        })

        Text('切换课表')
          .fontSize(FontSize.Headline)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.TextPrimary)
          .layoutWeight(1)

        Button({ type: ButtonType.Circle }) {
          SymbolGlyph($r('sys.symbol.plus'))
            .fontSize(20)
            .fontColor([Colors.TextPrimary])
        }
        .width(40)
        .height(40)
        .backgroundColor(Colors.SurfaceHigh)
        .onClick(() => {
          this.onOpenTables();
        })

        Button({ type: ButtonType.Circle }) {
          SymbolGlyph($r('sys.symbol.checkmark'))
            .fontSize(20)
            .fontColor([Colors.TextPrimary])
        }
        .width(40)
        .height(40)
        .backgroundColor(Colors.SurfaceHigh)
        .onClick(() => {
          this.onConfirm();
        })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .padding({ left: Spacing.Xl, right: Spacing.Xl, top: Spacing.Xl, bottom: Spacing.Lg })

      Scroll() {
        Column({ space: Spacing.Lg }) {
          // 课表（学期）选择 chips
          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
            ForEach(this.tables, (table: CourseTable) => {
              Text(table.name)
                .fontSize(FontSize.BodySm)
                .fontColor(table.id === this.selectedTableId ?
                  this.store.accentOn : Colors.TextSecondary)
                .padding({ left: Spacing.Lg, right: Spacing.Lg, top: Spacing.Sm, bottom: Spacing.Sm })
                .backgroundColor(table.id === this.selectedTableId ?
                  this.store.accentDisplay : Colors.SurfaceHigh)
                .borderRadius(Radius.Round)
                .margin({ right: Spacing.Sm, bottom: Spacing.Sm })
                .onClick(() => {
                  this.onSelectTable(table.id);
                })
            }, (table: CourseTable) => `sheet-table-${table.id}`)
          }
          .width('100%')

          Text('课程周数')
            .fontSize(FontSize.Title)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.TextPrimary)
            .width('100%')

          Grid() {
            ForEach(this.weekOptions(), (value: number) => {
              GridItem() {
                Text(`${value}`)
                  .fontSize(FontSize.Body)
                  .fontColor(value === this.selectedWeek ?
                    this.store.accentOn : Colors.TextPrimary)
                  .width('100%')
                  .height(44)
                  .textAlign(TextAlign.Center)
                  .backgroundColor(value === this.selectedWeek ?
                    this.store.accentDisplay : Colors.SurfaceHigh)
                  .borderRadius(Radius.Md)
                  .onClick(() => {
                    this.onSelectWeek(value);
                  })
              }
            }, (value: number) => `sheet-week-${value}`)
          }
          .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
          .columnsGap(Spacing.Md)
          .rowsGap(Spacing.Md)
          .width('100%')
          .height(5 * 44 + 4 * Spacing.Md)
        }
        .width('100%')
        .padding({ left: Spacing.Xl, right: Spacing.Xl, bottom: Spacing.Xxl })
      }
      .width('100%')
      .layoutWeight(1)
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Colors.Background)
  }
}
