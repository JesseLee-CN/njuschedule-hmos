/**
 * 4x4 桌面小组件：本周课表速览（周一~周五 × 每天最多 3 门）。
 * 数据由 FormExtensionAbility 现场计算（widget/WidgetDataProvider.ets），
 * 与 2x2 / 2x4 共用同一份 payload 的 week 字段。
 */

import { WidgetPalette } from '../WidgetCommon';
interface W4x4Course {
  name: string;
  day: number;
  start: number;
  count: number;
  period: string;
  color: string;
  done: boolean;
}

interface W4x4Payload {
  date: string;
  weekday: string;
  weekLabel: string;
  courses: W4x4Course[];
  week: W4x4Course[];
  weekTotals: number[];
  mode: string;
  accent: string;
}


const ROW_HEIGHT: number = 17;
const MAX_PERIODS: number = 10;
@Entry
@ComponentV2
struct Widget4x4 {
  @Local data: string = '';

  private payload(): W4x4Payload | undefined {
    if (this.data === '') {
      return undefined;
    }
    try {
      return JSON.parse(this.data) as W4x4Payload;
    } catch (err) {
      return undefined;
    }
  }

  private weekCourses(): W4x4Course[] {
    const payload: W4x4Payload | undefined = this.payload();
    if (payload === undefined || payload.week === undefined) {
      return [];
    }
    return payload.week;
  }

  private coursesOfDay(day: number): W4x4Course[] {
    const all: W4x4Course[] = this.weekCourses();
    const result: W4x4Course[] = [];
    for (let i = 0; i < all.length; i++) {
      if (all[i].day === day) {
        result.push(all[i]);
      }
    }
    return result;
  }

  private weekText(): string {
    const payload: W4x4Payload | undefined = this.payload();
    return payload === undefined || payload.weekLabel === undefined ? '本周' : payload.weekLabel;
  }

  private dateText(): string {
    const payload: W4x4Payload | undefined = this.payload();
    if (payload === undefined) {
      return '';
    }
    return `${payload.date} ${payload.weekday}`;
  }

  private dayTotal(day: number): number {
    const payload: W4x4Payload | undefined = this.payload();
    if (payload === undefined || payload.weekTotals === undefined) {
      return 0;
    }
    const total: number = payload.weekTotals[day - 1];
    return total === undefined ? 0 : total;
  }

  private moreText(day: number): string {
    const shown: number = this.coursesOfDay(day).length;
    const total: number = this.dayTotal(day);
    return total > shown ? `+${total - shown}` : '';
  }

  /** 该天空位（以「节」为单位）：第一门课之前 / 两门课之间的间隔。 */
  private gapBefore(day: number, index: number): number {
    const list: W4x4Course[] = this.coursesOfDay(day);
    if (index < 0 || index >= list.length) {
      return 0;
    }
    const start: number = list[index].start;
    if (index === 0) {
      return Math.max(start - 1, 0);
    }
    const prev: W4x4Course = list[index - 1];
    return Math.max(start - (prev.start + prev.count), 0);
  }

  private dayLabel(day: number): string {
    if (day === 1) {
      return '一';
    }
    if (day === 2) {
      return '二';
    }
    if (day === 3) {
      return '三';
    }
    if (day === 4) {
      return '四';
    }
    return '五';
  }

  // ---- 深浅色 / 主题色（payload 下发 mode/accent；调色板实现见 widget/WidgetCommon.ets）----

  private palette(): WidgetPalette {
    const payload: W4x4Payload | undefined = this.payload();
    return new WidgetPalette(payload === undefined ? '' : payload.mode,
      payload === undefined ? '' : payload.accent);
  }

  build() {
    Column() {
      Row() {
        Text(this.weekText())
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.palette().textPrimary())
        Blank()
        Text(this.dateText())
          .fontSize(10)
          .fontColor(this.palette().textTertiary())
      }
      .width('100%')

      Blank().height(8)

      if (this.weekCourses().length === 0) {
        Column() {
          Text('本周还没有课')
            .fontSize(13)
            .fontColor(this.palette().textSecondary())
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Row({ space: 4 }) {
          ForEach([1, 2, 3, 4, 5], (day: number) => {
            Column({ space: 4 }) {
              Text(this.dayLabel(day))
                .fontSize(10)
                .fontColor(this.palette().textTertiary())
                .width('100%')
                .textAlign(TextAlign.Center)

              Column() {
                ForEach(this.coursesOfDay(day), (course: W4x4Course, index: number) => {
                  Column() {
                    if (this.gapBefore(day, index) > 0) {
                      Row().width('100%').height(this.gapBefore(day, index) * ROW_HEIGHT)
                    }
                    Row({ space: 3 }) {
                      Row()
                        .width(2)
                        .height(course.count * ROW_HEIGHT - 4)
                        .borderRadius(1)
                        .backgroundColor(course.color)
                        .opacity(course.done ? 0.35 : 1)
                      Text(course.name)
                        .fontSize(8)
                        .maxLines(course.count * 2)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .fontColor(this.palette().textPrimary())
                        .opacity(course.done ? 0.45 : 1)
                        .layoutWeight(1)
                    }
                    .width('100%')
                    .height(course.count * ROW_HEIGHT)
                    .alignItems(VerticalAlign.Top)
                  }
                  .width('100%')
                  .alignItems(HorizontalAlign.Start)
                }, (course: W4x4Course, index: number) => `${day}-${index}-${course.name}`)
                if (this.moreText(day) !== '') {
                  Text(this.moreText(day))
                    .fontSize(8)
                    .fontColor(this.palette().textTertiary())
                }
              }
              .width('100%')
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
            }
            .layoutWeight(1)
            .height('100%')
            .alignItems(HorizontalAlign.Start)
          }, (day: number) => `day-${day}`)
        }
        .width('100%')
        .layoutWeight(1)
        .alignItems(VerticalAlign.Top)
      }
    }
    .width('100%')
    .height('100%')
    .padding(14)
    .backgroundColor(this.palette().cardBg())
    .borderRadius(16)
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        abilityName: 'EntryAbility',
        params: { target: 'timetable' }
      });
    })
  }
}
