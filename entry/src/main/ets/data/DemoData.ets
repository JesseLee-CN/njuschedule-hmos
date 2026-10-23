/**
 * 示例课表：移植旧版 `ImportFromJWPresenter.getDemoClasses`
 * （lib/Pages/Import/ImportFromJWPresenter.dart）。
 *
 * 用途：新装应用没有课程时，让用户能立刻看到周视图长什么样（旧版在导入页提供
 * 「演示导入」）。数据会写进一张独立的「Demo课表」，不污染用户的真实课表。
 */
import { CourseTable } from './models/Models';
import { Course } from './models/Models';
import { CourseTableRepository } from './CourseTableRepository';
import { CourseRepository } from './CourseRepository';

const DEMO_TABLE_NAME: string = 'Demo课表';

const DEMO_TABLE_DATA: string = '{"class_time_list": [' +
  '{"start": "08:00", "end": "08:50"},' +
  '{"start": "09:00", "end": "09:50"},' +
  '{"start": "10:00", "end": "10:50"},' +
  '{"start": "11:00", "end": "11:50"},' +
  '{"start": "14:00", "end": "14:50"},' +
  '{"start": "15:00", "end": "15:50"},' +
  '{"start": "16:00", "end": "16:50"},' +
  '{"start": "17:00", "end": "17:50"},' +
  '{"start": "18:00", "end": "18:50"},' +
  '{"start": "19:00", "end": "19:50"},' +
  '{"start": "20:00", "end": "20:50"},' +
  '{"start": "21:00", "end": "21:50"},' +
  '{"start": "22:00", "end": "22:50"},' +
  '{"start": "23:00", "end": "23:50"},' +
  '{"start": "00:00", "end": "00:50"}]' +
  '}';

function fullWeeks(): number[] {
  const weeks: number[] = [];
  for (let i = 1; i <= 22; i++) {
    weeks.push(i);
  }
  return weeks;
}

function oddWeeks(): number[] {
  const weeks: number[] = [];
  for (let i = 1; i <= 22; i += 2) {
    weeks.push(i);
  }
  return weeks;
}

function evenWeeks(): number[] {
  const weeks: number[] = [];
  for (let i = 2; i <= 22; i += 2) {
    weeks.push(i);
  }
  return weeks;
}

export class DemoData {
  /** 创建示例课表并写入演示课程，返回课表 id。 */
  static async createDemoTable(): Promise<number> {
    const table: CourseTable = await CourseTableRepository.insert(new CourseTable(DEMO_TABLE_NAME, DEMO_TABLE_DATA));
    const tableId: number = table.id;

    const courses: Course[] = [];
    const allWeeks: number[] = fullWeeks();

    courses.push(DemoData.course(tableId, '自动导入的课程', allWeeks, 3, 5, 1, 0, '测试教师', '测试地点'));
    courses.push(DemoData.course(tableId, '手动导入的课程', allWeeks, 3, 7, 1, 1, '测试教师', '仙林校区'));
    courses.push(DemoData.course(tableId, '单周展示的课程', oddWeeks(), 2, 5, 1, 0, '测试教师', '测试地点'));
    courses.push(DemoData.course(tableId, '双周展示的课程', evenWeeks(), 2, 8, 1, 0, '测试教师', '测试地点'));
    courses.push(DemoData.course(tableId, '有时间冲突的课程1', allWeeks, 4, 2, 1, 0, '测试教师', '测试地点'));
    courses.push(DemoData.course(tableId, '有时间冲突的课程2', allWeeks, 4, 2, 1, 0, '测试教师', '测试地点'));
    courses.push(DemoData.course(tableId, '自由时间课程', allWeeks, 0, 0, 0, 0, '', '测试地点'));

    await CourseRepository.insertMany(courses);
    return tableId;
  }

  private static course(tableId: number, name: string, weeks: number[], weekTime: number,
    startTime: number, timeCount: number, importType: number, teacher: string, classroom: string): Course {
    const course: Course = new Course(name, tableId);
    course.weeks = weeks;
    course.weekTime = weekTime;
    course.startTime = startTime;
    course.timeCount = timeCount;
    course.importType = importType;
    course.teacher = teacher;
    course.classroom = classroom;
    return course;
  }
}
