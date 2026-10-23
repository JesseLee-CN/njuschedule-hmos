/**
 * 旧版 SQLite schema 的 ArkTS 侧镜像（移植自 `lib/Models/Db/DbHelper.dart`，
 * DATABASE_VERSION = 3，库名 `course.db`）。
 *
 * 列名、列类型、表名一律沿用旧版，便于对照与未来迁移。差异只有：
 * 建表语句改用 `IF NOT EXISTS`，避免重复打开时报错。
 */
import { relationalStore } from '@kit.ArkData';
import { AppContext } from '../app/AppContext';

export class LegacySchema {
  static readonly DB_NAME: string = 'course.db';
  static readonly DB_VERSION: number = 3;

  static readonly COURSE_TABLE: string = 'Course';
  static readonly COURSE_ID: string = 'id';
  static readonly COURSE_NAME: string = 'name';
  static readonly COURSE_TABLE_ID: string = 'tableid';
  static readonly COURSE_CLASSROOM: string = 'classroom';
  static readonly COURSE_CLASS_NUMBER: string = 'class_number';
  static readonly COURSE_TEACHER: string = 'teacher';
  static readonly COURSE_TEST_TIME: string = 'test_time';
  static readonly COURSE_TEST_LOCATION: string = 'test_location';
  static readonly COURSE_LINK: string = 'link';
  static readonly COURSE_INFO: string = 'info';
  static readonly COURSE_DATA: string = 'data';
  static readonly COURSE_WEEKS: string = 'weeks';
  static readonly COURSE_WEEK_TIME: string = 'week_time';
  static readonly COURSE_START_TIME: string = 'start_time';
  static readonly COURSE_TIME_COUNT: string = 'time_count';
  static readonly COURSE_IMPORT_TYPE: string = 'import_type';
  static readonly COURSE_COLOR: string = 'color';
  static readonly COURSE_COURSE_ID: string = 'course_id';

  static readonly COURSETABLE_TABLE: string = 'CourseTable';
  static readonly COURSETABLE_ID: string = 'id';
  static readonly COURSETABLE_NAME: string = 'name';
  static readonly COURSETABLE_DATA: string = 'data';

  static readonly SQL_CREATE_COURSES: string =
    'CREATE TABLE IF NOT EXISTS ' + LegacySchema.COURSE_TABLE + ' (' +
      LegacySchema.COURSE_ID + ' INTEGER PRIMARY KEY AUTOINCREMENT,' +
      LegacySchema.COURSE_TABLE_ID + ' INTEGER,' +
      LegacySchema.COURSE_NAME + ' TEXT,' +
      LegacySchema.COURSE_CLASSROOM + ' TEXT,' +
      LegacySchema.COURSE_CLASS_NUMBER + ' TEXT,' +
      LegacySchema.COURSE_TEACHER + ' TEXT,' +
      LegacySchema.COURSE_TEST_TIME + ' TEXT,' +
      LegacySchema.COURSE_TEST_LOCATION + ' TEXT,' +
      LegacySchema.COURSE_LINK + ' TEXT,' +
      LegacySchema.COURSE_INFO + ' TEXT,' +
      LegacySchema.COURSE_DATA + ' TEXT,' +
      LegacySchema.COURSE_WEEKS + ' TEXT,' +
      LegacySchema.COURSE_WEEK_TIME + ' INTEGER,' +
      LegacySchema.COURSE_START_TIME + ' INTEGER,' +
      LegacySchema.COURSE_TIME_COUNT + ' INTEGER,' +
      LegacySchema.COURSE_IMPORT_TYPE + ' INTEGER,' +
      LegacySchema.COURSE_COLOR + ' TEXT,' +
      LegacySchema.COURSE_COURSE_ID + ' INTEGER' +
    ')';

  static readonly SQL_CREATE_COURSETABLE: string =
    'CREATE TABLE IF NOT EXISTS ' + LegacySchema.COURSETABLE_TABLE + ' (' +
      LegacySchema.COURSETABLE_ID + ' INTEGER PRIMARY KEY AUTOINCREMENT,' +
      LegacySchema.COURSETABLE_NAME + ' TEXT,' +
      LegacySchema.COURSETABLE_DATA + ' TEXT' +
    ')';

  /** 旧版 v2 → v3 的三条 ALTER（Course.info、Course.data、CourseTable.data）。 */
  static readonly SQL_UPGRADE_V2_PART_1: string =
    'ALTER TABLE ' + LegacySchema.COURSE_TABLE + ' ADD COLUMN ' + LegacySchema.COURSE_INFO + ' TEXT';
  static readonly SQL_UPGRADE_V2_PART_2: string =
    'ALTER TABLE ' + LegacySchema.COURSE_TABLE + ' ADD COLUMN ' + LegacySchema.COURSE_DATA + ' TEXT';
  static readonly SQL_UPGRADE_V2_COURSETABLE: string =
    'ALTER TABLE ' + LegacySchema.COURSETABLE_TABLE + ' ADD COLUMN ' + LegacySchema.COURSETABLE_DATA + ' TEXT';
}

/**
 * 数据库单例。线程安全（relationalStore 本身线程安全），只在主线程使用。
 */
export class Db {
  private static store: relationalStore.RdbStore | null = null;
  private static opening: Promise<relationalStore.RdbStore> | null = null;

  static async open(): Promise<relationalStore.RdbStore> {
    const ready: relationalStore.RdbStore | null = Db.store;
    if (ready !== null) {
      return ready;
    }
    const pending: Promise<relationalStore.RdbStore> | null = Db.opening;
    if (pending !== null) {
      return pending;
    }
    const opening: Promise<relationalStore.RdbStore> = Db.doOpen();
    Db.opening = opening;
    try {
      const store: relationalStore.RdbStore = await opening;
      Db.store = store;
      return store;
    } finally {
      Db.opening = null;
    }
  }

  private static async doOpen(): Promise<relationalStore.RdbStore> {
    const config: relationalStore.StoreConfig = {
      name: LegacySchema.DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    };
    const store: relationalStore.RdbStore = await relationalStore.getRdbStore(AppContext.get(), config);
    if (store.version === 0) {
      await store.executeSql(LegacySchema.SQL_CREATE_COURSETABLE);
      await store.executeSql(LegacySchema.SQL_CREATE_COURSES);
      store.version = LegacySchema.DB_VERSION;
    } else if (store.version < LegacySchema.DB_VERSION) {
      // 旧版 v2 升级路径，逐条补齐列；重复升级时忽略已存在的列。
      await Db.tryExecute(store, LegacySchema.SQL_UPGRADE_V2_PART_1);
      await Db.tryExecute(store, LegacySchema.SQL_UPGRADE_V2_PART_2);
      await Db.tryExecute(store, LegacySchema.SQL_UPGRADE_V2_COURSETABLE);
      store.version = LegacySchema.DB_VERSION;
    }
    return store;
  }

  private static async tryExecute(store: relationalStore.RdbStore, sql: string): Promise<void> {
    try {
      await store.executeSql(sql);
    } catch (err) {
      // 列已存在（或 schema 已是新版）时忽略；真正的错误由后续读写暴露。
      console.warn(`[Db] executeSql skipped: ${sql} (${JSON.stringify(err)})`);
    }
  }

  static async close(): Promise<void> {
    const ready: relationalStore.RdbStore | null = Db.store;
    if (ready !== null) {
      await ready.close();
      Db.store = null;
    }
  }
}
