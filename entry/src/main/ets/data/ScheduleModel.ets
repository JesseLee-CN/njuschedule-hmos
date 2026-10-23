/**
 * 课表分类与重叠合并：1:1 移植旧版 `lib/Models/ScheduleModel.dart`。
 *
 * 输出四类课程：
 * - `activeCourses`：当前周上课、且不与其他课程时间重叠的课
 * - `hideCourses`：当前周不上、但仍要在网格上淡显的课
 * - `multiCourses`：同一时段有冲突的课程组；`[0]` 是展示出来的那门
 * - `freeCourses`：`weekTime == 0` 的自由时间课程（不占节次）
 *
 * 旧版算法里的顺序依赖是刻意的（先 active 后 hide，保证冲突组首项尽量是本周课），
 * 移植时保持同样的遍历顺序，不做"优化"。
 */
import { LegacyConstant } from '../common/Constants';
import { Course } from './models/Models';

export class ScheduleModel {
  private courses: Course[];
  private nowWeek: number;

  activeCourses: Course[] = [];
  hideCourses: Course[] = [];
  multiCourses: Course[][] = [];
  freeCourses: Course[] = [];

  constructor(courses: Course[], nowWeek: number) {
    this.courses = courses;
    this.nowWeek = nowWeek;
  }

  init(): void {
    this.classify();
    this.deduplicate();
  }

  private classify(): void {
    for (let i = 0; i < this.courses.length; i++) {
      const course: Course = this.courses[i];
      const weeks: number[] = course.weeks;
      if (course.weekTime === 0) {
        this.freeCourses.push(course);
      } else if (weeks.indexOf(this.nowWeek) >= 0) {
        this.activeCourses.push(course);
      } else if (course.importType === LegacyConstant.ADD_BY_LECTURE && weeks.length > 0 &&
        weeks[0] < this.nowWeek) {
        // 讲座类课程过期后直接不再展示（旧版行为）。
        continue;
      } else {
        this.hideCourses.push(course);
      }
    }
  }

  private deduplicate(): void {
    const deduplicateResult: Course[] = [];
    const needToDelete: Course[] = [];

    // 1) 先把 activeCourses 归入已有的冲突组
    for (let i = 0; i < this.activeCourses.length; i++) {
      const course: Course = this.activeCourses[i];
      let isOverlapped: boolean = false;
      for (let j = 0; j < this.multiCourses.length; j++) {
        const checked: Course[] = this.multiCourses[j];
        if (ScheduleModel.checkIfOverlapping(course, checked[0])) {
          checked.push(course);
          ScheduleModel.checkMultiCoursesElement(checked, this.nowWeek);
          isOverlapped = true;
        }
      }
      if (isOverlapped) {
        continue;
      }
      for (let k = 0; k < deduplicateResult.length; k++) {
        const checked: Course = deduplicateResult[k];
        if (ScheduleModel.checkIfOverlapping(course, checked)) {
          this.multiCourses.push([course, checked]);
          ScheduleModel.checkMultiCoursesElement(this.multiCourses[this.multiCourses.length - 1], this.nowWeek);
          ScheduleModel.removeCourse(deduplicateResult, checked);
          needToDelete.push(checked);
          needToDelete.push(course);
          isOverlapped = true;
          break;
        }
      }
      if (!isOverlapped) {
        deduplicateResult.push(course);
      }
    }
    for (let i = 0; i < needToDelete.length; i++) {
      ScheduleModel.removeCourse(this.activeCourses, needToDelete[i]);
    }
    needToDelete.length = 0;

    // 2) 再把 hideCourses 归入冲突组（同样优先并入已有组）
    for (let i = 0; i < this.hideCourses.length; i++) {
      const course: Course = this.hideCourses[i];
      let isOverlapped: boolean = false;
      for (let j = 0; j < this.multiCourses.length; j++) {
        const checked: Course[] = this.multiCourses[j];
        if (ScheduleModel.checkIfOverlapping(course, checked[0])) {
          checked.push(course);
          ScheduleModel.checkMultiCoursesElement(checked, this.nowWeek);
          isOverlapped = true;
          break;
        }
      }
      if (isOverlapped) {
        continue;
      }
      for (let k = 0; k < deduplicateResult.length; k++) {
        const checked: Course = deduplicateResult[k];
        if (ScheduleModel.checkIfOverlapping(course, checked)) {
          this.multiCourses.push([course, checked]);
          ScheduleModel.checkMultiCoursesElement(this.multiCourses[this.multiCourses.length - 1], this.nowWeek);
          ScheduleModel.removeCourse(deduplicateResult, checked);
          needToDelete.push(checked);
          needToDelete.push(course);
          isOverlapped = true;
          break;
        }
      }
      if (!isOverlapped) {
        deduplicateResult.push(course);
      }
    }
    // 旧版此处两个分支都是 activeCourses.remove(item)，即从本周课程里移除冲突项。
    for (let i = 0; i < needToDelete.length; i++) {
      ScheduleModel.removeCourse(this.activeCourses, needToDelete[i]);
    }
  }

  /** 同一天且节次区间相交。 */
  static checkIfOverlapping(a: Course, b: Course): boolean {
    if (a.weekTime !== b.weekTime) {
      return false;
    }
    const aStart: number = a.startTime;
    const bStart: number = b.startTime;
    const aEnd: number = a.startTime + a.timeCount;
    const bEnd: number = b.startTime + b.timeCount;
    return (aStart >= bStart && aStart <= bEnd) || (bStart >= aStart && bStart <= aEnd);
  }

  /** 冲突组首项尽量放本周在上的、节次跨度最大的课。 */
  private static checkMultiCoursesElement(group: Course[], nowWeek: number): void {
    let maxCount: number = 0;
    let maxIndex: number = 0;
    for (let i = 0; i < group.length; i++) {
      const course: Course = group[i];
      if (course.timeCount > maxCount && course.weeks.indexOf(nowWeek) >= 0) {
        maxCount = course.timeCount;
        maxIndex = i;
      }
    }
    if (maxIndex !== 0) {
      const tmp: Course = group[maxIndex];
      group[maxIndex] = group[0];
      group[0] = tmp;
    }
  }

  static removeCourse(list: Course[], target: Course): void {
    const index: number = list.indexOf(target);
    if (index >= 0) {
      list.splice(index, 1);
    }
  }
}
