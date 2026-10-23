/**
 * 课程配色池：移植旧版 `lib/Utils/ColorUtil.dart` + `Course.getColor`。
 *
 * 旧版把 14 个色板下标洗牌后以字符串形式存进 prefs `colorPool`（`"[3, 1, 0]"`，
 * 同时是合法 JSON），课程按 `course_id % pool.length` 取色，保证同门课颜色一致、
 * 不同课尽量不撞色。自定义颜色优先。
 */
import { LegacyCourseColors } from '../common/Constants';
import { Course } from '../data/models/Models';
import { AppPreferences } from '../app/AppPreferences';

export class ColorPool {
  private static cached: number[] = [];

  /** 读取配色池；不存在时洗牌生成并持久化（旧版 checkColorPool）。 */
  static async check(): Promise<void> {
    await ColorPool.get();
  }

  static async get(): Promise<number[]> {
    if (ColorPool.cached.length > 0) {
      return ColorPool.cached;
    }
    const raw: string = await AppPreferences.getColorPoolRaw();
    const parsed: number[] = ColorPool.parsePool(raw);
    if (parsed.length > 0) {
      ColorPool.cached = parsed;
      return parsed;
    }
    return ColorPool.shuffle();
  }

  /** 重新洗牌（设置页「重置课程颜色」用）。 */
  static async shuffle(): Promise<number[]> {
    const pool: number[] = [];
    for (let i = 0; i < LegacyCourseColors.COLOR_LIST.length; i++) {
      pool.push(i);
    }
    // Fisher-Yates
    for (let i = pool.length - 1; i > 0; i--) {
      const j: number = Math.floor(Math.random() * (i + 1));
      const tmp: number = pool[i];
      pool[i] = pool[j];
      pool[j] = tmp;
    }
    ColorPool.cached = pool;
    await AppPreferences.setColorPoolRaw(JSON.stringify(pool));
    return pool;
  }

  /**
   * 解析课程颜色：`course.color` 是合法 `#RRGGBB`（或纯 `RRGGBB`）时优先用它，
   * 否则按色池取色。返回 `#RRGGBB` 字符串，可直接作为 ArkUI ResourceColor。
   */
  static resolve(course: Course, pool: number[]): string {
    const raw: string = course.color.trim();
    if (raw !== '') {
      const normalized: string = raw.startsWith('#') ? raw.substring(1) : raw;
      if (ColorPool.isValidHex(normalized)) {
        return raw.startsWith('#') ? raw : `#${raw}`;
      }
    }
    if (course.courseId < 0 || pool.length === 0) {
      return LegacyCourseColors.COLOR_LIST[0];
    }
    const index: number = pool[course.courseId % pool.length];
    return LegacyCourseColors.COLOR_LIST[index];
  }


  private static isValidHex(normalized: string): boolean {
    return new RegExp('^[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$').test(normalized);
  }

  private static parsePool(raw: string): number[] {
    if (raw === '') {
      return [];
    }
    try {
      const parsed: number[] = JSON.parse(raw) as number[];
      if (!Array.isArray(parsed) || parsed.length === 0) {
        return [];
      }
      const result: number[] = [];
      for (let i = 0; i < parsed.length; i++) {
        const value: number = parsed[i];
        if (typeof value === 'number' && !isNaN(value)) {
          result.push(Math.trunc(value));
        }
      }
      return result;
    } catch (err) {
      return [];
    }
  }
}
