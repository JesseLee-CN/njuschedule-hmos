/**
 * 周次展示文案：把 `weeks: number[]` 压缩成「1-16周」「单周」「2-16双周」「1,3,5周」这类摘要。
 * 旧版没有统一函数（各页面自己拼字符串），这里收敛成一处，展示口径与旧版课程详情一致。
 */
import { Course } from '../../data/models/Models';
import { LegacyConstant } from '../../common/Constants';

export class WeeksFormat {
  /** 例：[1,2,...,16] → "1-16周"；单双周优先按步长判断。 */
  static describe(weeks: number[]): string {
    if (weeks.length === 0) {
      return '未设置周次';
    }
    const sorted: number[] = weeks.slice().sort((a: number, b: number) => a - b);
    const isContinuous: boolean = WeeksFormat.isStep(sorted, 1);
    const isOdd: boolean = WeeksFormat.isStep(sorted, 2) && sorted[0] % 2 === 1;
    const isEven: boolean = WeeksFormat.isStep(sorted, 2) && sorted[0] % 2 === 0;
    const first: number = sorted[0];
    const last: number = sorted[sorted.length - 1];
    if (isContinuous) {
      return first === last ? `${first}周` : `${first}-${last}周`;
    }
    if (isOdd) {
      return `${first}-${last}单周`;
    }
    if (isEven) {
      return `${first}-${last}双周`;
    }
    return `${sorted.join(',')}周`;
  }

  /** 课程类型标签（对应 course.import_type）。 */
  static importTypeLabel(importType: number): string {
    if (importType === LegacyConstant.ADD_BY_IMPORT) {
      return '教务导入';
    }
    if (importType === LegacyConstant.ADD_BY_LECTURE) {
      return '讲座';
    }
    return '手动添加';
  }

  /** 节次文案，如「第3-4节」；自由时间课程返回「自由时间」。 */
  static periodLabel(course: Course): string {
    if (course.weekTime === 0) {
      return '自由时间';
    }
    const start: number = course.startTime;
    const end: number = course.startTime + course.timeCount;
    if (end <= start) {
      return `第${start}节`;
    }
    return `第${start}-${end}节`;
  }

  static weekdayLabel(weekTime: number): string {
    if (weekTime <= 0 || weekTime > 7) {
      return '';
    }
    return LegacyConstant.WEEK_WITH_BIAS[weekTime];
  }

  private static isStep(sorted: number[], step: number): boolean {
    if (sorted.length <= 1) {
      return true;
    }
    for (let i = 1; i < sorted.length; i++) {
      if (sorted[i] - sorted[i - 1] !== step) {
        return false;
      }
    }
    return true;
  }
}
