/**
 * 学校列表仓储：从 rawfile 读取 `import/schoolList.json`，解析成 `SchoolConfig[]`。
 *
 * 与旧版的差异（按移植规格 §11.3）：
 * - 旧版从 CDN 拉 `schoolList.json` 并做 azlistview 分组；这里改为随包内置
 *   rawfile（离线可用、不会因远端变更导致导入页空白），解析与字段语义保持一致。
 * - 排序：按 `pinyin` 升序（南大 4 条因为 pinyin 以 `1` 开头，自然排在最前）；
 *   分组索引 `tagIndex` 保留在 DTO 里，UI 需要时再分组。
 * - 搜索：旧版没有搜索框，这里按 title / pinyin / description 子串过滤。
 */
import { util } from '@kit.ArkTS';
import { AppContext } from '../../app/AppContext';
import { SchoolConfig } from './SchoolConfig';

const SCHOOL_LIST_PATH: string = 'import/schoolList.json';

export class SchoolRepository {
  private static cache: SchoolConfig[] = [];
  private static cacheValid: boolean = false;

  /**
   * 读取并解析内置学校列表（带进程内缓存）。
   * @param forceReload 为 true 时忽略缓存重新读取
   */
  static async loadAll(forceReload: boolean = false): Promise<SchoolConfig[]> {
    if (SchoolRepository.cacheValid && !forceReload) {
      return SchoolRepository.cache.slice();
    }

    let text: string = '';
    try {
      const context = AppContext.get();
      const bytes: Uint8Array = await context.resourceManager.getRawFileContent(SCHOOL_LIST_PATH);
      text = util.TextDecoder.create('utf-8').decodeToString(bytes);
    } catch (err) {
      throw new Error(`读取内置学校列表失败：${errorMessage(err)}`);
    }

    const list: SchoolConfig[] = SchoolRepository.parse(text);
    SchoolRepository.cache = list;
    SchoolRepository.cacheValid = true;
    return list.slice();
  }

  /** 按 pinyin 升序排序后的新数组（不修改入参）。 */
  static sortedByPinyin(list: SchoolConfig[]): SchoolConfig[] {
    const copy: SchoolConfig[] = list.slice();
    copy.sort((a: SchoolConfig, b: SchoolConfig): number => {
      if (a.pinyin === b.pinyin) {
        return 0;
      }
      return a.pinyin < b.pinyin ? -1 : 1;
    });
    return copy;
  }

  /** 关键字过滤：空关键字返回原数组；匹配 title / pinyin / description / tagIndex。 */
  static search(list: SchoolConfig[], keyword: string): SchoolConfig[] {
    const query: string = keyword.trim().toLowerCase();
    if (query === '') {
      return list;
    }
    const matched: SchoolConfig[] = [];
    for (let i = 0; i < list.length; i++) {
      const school: SchoolConfig = list[i];
      if (school.title.toLowerCase().indexOf(query) >= 0 ||
        school.pinyin.toLowerCase().indexOf(query) >= 0 ||
        school.description.toLowerCase().indexOf(query) >= 0 ||
        school.tagIndex.toLowerCase().indexOf(query) >= 0) {
        matched.push(school);
      }
    }
    return matched;
  }

  private static parse(text: string): SchoolConfig[] {
    let parsed: Record<string, Object>;
    try {
      parsed = JSON.parse(text) as Record<string, Object>;
    } catch (err) {
      throw new Error('内置学校列表格式错误（JSON 解析失败）');
    }
    if (parsed === null) {
      throw new Error('内置学校列表为空');
    }
    const data: Object | undefined = parsed['data'];
    if (!Array.isArray(data)) {
      throw new Error('内置学校列表缺少 data 数组');
    }
    const items: Object[] = data as Object[];
    const list: SchoolConfig[] = [];
    for (let i = 0; i < items.length; i++) {
      const item: Object = items[i];
      if (item === null || typeof item !== 'object' || Array.isArray(item)) {
        continue;
      }
      list.push(SchoolConfig.fromJson(item as Record<string, Object>));
    }
    if (list.length === 0) {
      throw new Error('内置学校列表为空');
    }
    return list;
  }
}

function errorMessage(err: Object): string {
  if (err instanceof Error) {
    return err.message;
  }
  return err.toString();
}
