/**
 * 周次计算：1:1 移植旧版 `lib/Utils/WeekUtil.dart`。
 *
 * 旧版把「某个周一的日期 + 那天的周序号」写进 shared_preferences，之后靠
 * 日期差推算周次。这里沿用同样的 key（lastWeekMonday / weekIndex / tmpWeekIndex）
 * 与同样的算法，保证语义不变。
 */
import { AppPreferences, PrefKeys } from '../app/AppPreferences';
import { DateUtils } from '../common/DateUtils';

export class WeekUtil {
  /** 启动时校正周次：跨周后自动前进。 */
  static async checkWeek(): Promise<void> {
    const lastMondayString: string = await AppPreferences.getString(PrefKeys.LastWeekMonday, '');
    const thisMondayString: string = DateUtils.currentMondayString();
    if (lastMondayString === '') {
      await WeekUtil.initWeek(thisMondayString, 1);
      return;
    }
    const weekBias: number = WeekUtil.weekBias(lastMondayString, thisMondayString);
    if (weekBias !== 0) {
      await WeekUtil.setWeek(thisMondayString, weekBias);
    }
  }

  /** 直接设定当前周（设置页「当前周」用）。 */
  static async setNowWeek(weekNum: number): Promise<void> {
    const monday: string = DateUtils.currentMondayString();
    await WeekUtil.initWeek(monday, weekNum);
  }

  /** 设定学期起始周一后，按本周一推算当前周（旧版 initWeek(String monday, int week)）。 */
  static async initWeek(monday: string, week: number): Promise<void> {
    const thisMondayString: string = DateUtils.currentMondayString();
    const weekBias: number = WeekUtil.weekBias(monday, thisMondayString);
    await WeekUtil.initWeekInternal(thisMondayString, weekBias + week);
  }

  /** 判断某个周一是否与当前折算周一致（旧版 isSameWeek，用于背景图随周变化）。 */
  static async isSameWeek(monday: string, index: number): Promise<boolean> {
    const lastMondayString: string = await AppPreferences.getString(PrefKeys.LastWeekMonday, '');
    if (lastMondayString === '') {
      return true;
    }
    const lastIndex: number = await AppPreferences.getInt(PrefKeys.WeekIndex, 1);
    const weekBias: number = WeekUtil.weekBias(lastMondayString, monday);
    return weekBias === index - lastIndex;
  }

  /** 某天属于第几周（旧版 getWeekNumOfDay）。 */
  static async getWeekNumOfDay(date: Date): Promise<number> {
    const lastMondayString: string = await AppPreferences.getString(PrefKeys.LastWeekMonday, '');
    if (lastMondayString === '') {
      return 1;
    }
    const lastMonday: Date = DateUtils.parseIsoDate(lastMondayString);
    const lastIndex: number = await AppPreferences.getInt(PrefKeys.WeekIndex, 1);
    const targetMonday: Date = DateUtils.mondayOf(date);
    const weekBias: number = Math.floor(DateUtils.daysBetween(lastMonday, targetMonday) / 7);
    return lastIndex + weekBias;
  }

  /** 距离第 1 周还有几周：由 `semester_start_monday` 推算当前周。 */
  static async getWeekFromSemesterStart(monday: string): Promise<number> {
    if (monday === '') {
      return 1;
    }
    const startMonday: Date = DateUtils.parseIsoDate(monday);
    const thisMonday: Date = DateUtils.mondayOf(DateUtils.today());
    const bias: number = Math.floor(DateUtils.daysBetween(startMonday, thisMonday) / 7);
    return bias + 1;
  }

  private static weekBias(lastMondayString: string, thisMondayString: string): number {
    const lastMonday: Date = DateUtils.parseIsoDate(lastMondayString);
    const thisMonday: Date = DateUtils.parseIsoDate(thisMondayString);
    return Math.floor(DateUtils.daysBetween(lastMonday, thisMonday) / 7);
  }

  private static async setWeek(monday: string, bias: number): Promise<void> {
    const nowWeek: number = await AppPreferences.getInt(PrefKeys.WeekIndex, 1);
    await AppPreferences.put(PrefKeys.LastWeekMonday, monday);
    await AppPreferences.put(PrefKeys.WeekIndex, nowWeek + bias);
    await AppPreferences.put(PrefKeys.TmpWeekIndex, nowWeek + bias);
  }

  private static async initWeekInternal(monday: string, week: number): Promise<void> {
    await AppPreferences.put(PrefKeys.LastWeekMonday, monday);
    await AppPreferences.put(PrefKeys.WeekIndex, week);
    await AppPreferences.put(PrefKeys.TmpWeekIndex, week < 1 ? 1 : week);
  }
}
