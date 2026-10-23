/**
 * 讲座数据与接口：移植旧版 `lib/Models/LectureModel.dart` 与
 * `lib/Pages/Lecture/LecturesView.dart` 的远程接口。
 *
 * 后端沿用旧项目地址 `https://lecture.idealclover.cn`（旧版 `Url.URL_BACKEND`）：
 * - GET /getTag            → {"data": ["仙林", "鼓楼", ...]}
 * - GET /getAll?limit&page&tag → {"total_page": n, "data": [LectureRow...]}
 * - GET /addCount?id=      → 记录「加入课表」次数（尽力而为，失败不影响导入）
 */
import { http } from '@kit.NetworkKit';
import { LegacyUrl } from '../common/Constants';

export class Lecture {
  id: number = 0;
  title: string = '';
  teacher: string = '';
  classroom: string = '';
  tag: string = '';
  department: string = '';
  info: string = '';
  /** 后端返回的本地时间字符串，如 `2026-10-23T16:20:00`。 */
  startTime: string = '';
  endTime: string = '';
  /** 起始节 / 结束节（1 基，endIndex 含）。 */
  startIndex: number = 0;
  endIndex: number = 0;
  accurate: boolean = false;
  count: number = 0;
}

export class LecturePage {
  totalPage: number = 1;
  data: Lecture[] = [];
}

export class LectureApi {
  private static readonly BASE: string = LegacyUrl.BACKEND;

  static async getTags(): Promise<string[]> {
    const body: string = await LectureApi.get('/getTag');
    const json: Record<string, Object> = JSON.parse(body) as Record<string, Object>;
    const raw: Object | undefined = json.data;
    if (raw === undefined || !Array.isArray(raw)) {
      return [];
    }
    const result: string[] = [];
    const list: Object[] = raw as Object[];
    for (let i = 0; i < list.length; i++) {
      result.push(`${list[i]}`);
    }
    return result;
  }

  static async getPage(page: number, limit: number, tag: string): Promise<LecturePage> {
    let path: string = `/getAll?limit=${limit}&page=${page}`;
    if (tag !== '') {
      path += `&tag=${encodeURIComponent(tag)}`;
    }
    const body: string = await LectureApi.get(path);
    const json: Record<string, Object> = JSON.parse(body) as Record<string, Object>;
    const result: LecturePage = new LecturePage();
    const totalPage: Object | undefined = json.total_page;
    result.totalPage = totalPage === undefined ? 1 : parseInt(`${totalPage}`, 10);
    const raw: Object | undefined = json.data;
    if (raw === undefined || !Array.isArray(raw)) {
      return result;
    }
    const list: Object[] = raw as Object[];
    for (let i = 0; i < list.length; i++) {
      result.data.push(LectureApi.toLecture(list[i] as Record<string, Object>));
    }
    return result;
  }

  static async addCount(lectureId: number): Promise<void> {
    try {
      await LectureApi.get(`/addCount?id=${lectureId}`);
    } catch (err) {
      console.warn(`[Lecture] addCount failed: ${JSON.stringify(err)}`);
    }
  }

  private static toLecture(row: Record<string, Object>): Lecture {
    const lecture: Lecture = new Lecture();
    lecture.id = LectureApi.num(row, 'id', 0);
    lecture.title = LectureApi.str(row, 'title');
    lecture.teacher = LectureApi.str(row, 'teacher');
    lecture.classroom = LectureApi.str(row, 'classroom');
    lecture.tag = LectureApi.str(row, 'tag');
    lecture.department = LectureApi.str(row, 'department');
    lecture.info = LectureApi.str(row, 'info');
    lecture.startTime = LectureApi.str(row, 'startTime');
    lecture.endTime = LectureApi.str(row, 'endTime');
    lecture.startIndex = LectureApi.num(row, 'startIndex', 0);
    lecture.endIndex = LectureApi.num(row, 'endIndex', 0);
    lecture.accurate = row.accurate === true;
    lecture.count = LectureApi.num(row, 'count', 0);
    if (lecture.startIndex <= 0) {
      lecture.startIndex = 1;
    }
    if (lecture.endIndex < lecture.startIndex) {
      lecture.endIndex = lecture.startIndex;
    }
    return lecture;
  }

  private static str(row: Record<string, Object>, key: string): string {
    const value: Object | undefined = row[key];
    return value === undefined || value === null ? '' : `${value}`;
  }

  private static num(row: Record<string, Object>, key: string, fallback: number): number {
    const value: Object | undefined = row[key];
    if (value === undefined || value === null) {
      return fallback;
    }
    const parsed: number = parseInt(`${value}`, 10);
    return isNaN(parsed) ? fallback : parsed;
  }

  private static get(path: string): Promise<string> {
    return new Promise<string>((resolve: (value: string) => void, reject: (reason: Error) => void) => {
      const request: http.HttpRequest = http.createHttp();
      request.request(LectureApi.BASE + path, {
        method: http.RequestMethod.GET,
        connectTimeout: 10000,
        readTimeout: 10000,
        expectDataType: http.HttpDataType.STRING
      }).then((response: http.HttpResponse) => {
        request.destroy();
        if (response.responseCode !== 200) {
          reject(new Error(`HTTP ${response.responseCode}`));
          return;
        }
        resolve(`${response.result}`);
      }).catch((err: Error) => {
        request.destroy();
        reject(err);
      });
    });
  }
}
