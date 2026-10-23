/**
 * relationalStore 读取小工具：把 ResultSet 的一行读成带默认值的字段。
 * 旧版 Dart 侧是 `Map<String, dynamic>`，null 很常见，这里统一收敛 null 处理。
 */
import { relationalStore } from '@kit.ArkData';

export class RdbUtil {
  static str(resultSet: relationalStore.ResultSet, column: string, fallback: string = ''): string {
    const index: number = resultSet.getColumnIndex(column);
    if (index < 0 || resultSet.isColumnNull(index)) {
      return fallback;
    }
    return resultSet.getString(index);
  }

  static num(resultSet: relationalStore.ResultSet, column: string, fallback: number = 0): number {
    const index: number = resultSet.getColumnIndex(column);
    if (index < 0 || resultSet.isColumnNull(index)) {
      return fallback;
    }
    return resultSet.getLong(index);
  }

  static isNull(resultSet: relationalStore.ResultSet, column: string): boolean {
    const index: number = resultSet.getColumnIndex(column);
    return index < 0 || resultSet.isColumnNull(index);
  }

  /** 解析旧版写入的整数数组字符串（`"[1, 2, 3]"`，也是合法 JSON）。 */
  static parseIntArray(raw: string): number[] {
    if (raw === '') {
      return [];
    }
    try {
      const parsed: number[] = JSON.parse(raw) as number[];
      if (!Array.isArray(parsed)) {
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
      console.warn(`[RdbUtil] 无法解析周次数组: ${raw}`);
      return [];
    }
  }
}
