/**
 * 桌面小组件共享数据结构与调色板。
 *
 * 卡片渲染进程读不到主应用的 AppStorage，因此深浅色/主题色由 payload 下发
 * `mode` 与 `accent`；这里集中「payload 基础类型 + 深浅色调色板」，
 * 避免 2x2/2x4/4x4 三张卡片各写一份（原先 3 份实现已出现色值与 resources/dark 漂移）。
 */

/** 2x2 / 2x4 卡片里的单门课程（4x4 用 week 结构，单独定义）。 */
export interface WidgetDayCourse {
  name: string;
  place: string;
  teacher: string;
  time: string;
  startTime: string;
  endTime: string;
  period: string;
  color: string;
  state: string;
}

/** 2x2 / 2x4 卡片 payload（2x4 会带 teacher 字段，可选）。 */
export interface WidgetDayPayload {
  date: string;
  weekday: string;
  weekLabel: string;
  courses: WidgetDayCourse[];
  todayHasCourses: boolean;
  todayDone: boolean;
  todayTotal: number;
  nextDate: string;
  nextWeekday: string;
  nextWeekLabel: string;
  nextCourses: WidgetDayCourse[];
  nextFound: boolean;
  mode: string;
  accent: string;
}

/** 卡片调色板：mode = 'dark' | 'light' | ''（空串表示跟随系统资源）。 */
export class WidgetPalette {
  private readonly mode: string;
  private readonly accentHex: string;

  constructor(mode: string, accent: string) {
    this.mode = mode === undefined ? '' : mode;
    this.accentHex = new RegExp('^#[0-9A-Fa-f]{6}$').test(accent) ? accent : '#0095F9';
  }

  isDark(): boolean {
    return this.mode === 'dark';
  }

  isLight(): boolean {
    return this.mode === 'light';
  }

  /** 强调色（payload 下发的生效主题色；非法值回落默认蓝）。 */
  accent(): string {
    return this.accentHex;
  }

  /** 主题色 12% 透明度（ARGB），用于徽标底色，深/浅底上都自然。 */
  accentSoft(): string {
    return `#1F${this.accentHex.substring(1)}`;
  }

  cardBg(): ResourceColor {
    if (this.isDark()) {
      return '#1F1F23';
    }
    if (this.isLight()) {
      return '#FFFFFF';
    }
    return $r('app.color.app_surface');
  }

  surfaceHigh(): ResourceColor {
    if (this.isDark()) {
      return '#2A2A2E';
    }
    if (this.isLight()) {
      return '#F2F2F4';
    }
    return $r('app.color.app_surface_high');
  }

  textPrimary(): ResourceColor {
    if (this.isDark()) {
      return '#F2F2F2';
    }
    if (this.isLight()) {
      return '#1F1F1F';
    }
    return $r('app.color.app_text_primary');
  }

  textSecondary(): ResourceColor {
    if (this.isDark()) {
      return '#C8C8CC';
    }
    if (this.isLight()) {
      return '#6B6B70';
    }
    return $r('app.color.app_text_secondary');
  }

  textTertiary(): ResourceColor {
    if (this.isDark()) {
      return '#9A9AA0';
    }
    if (this.isLight()) {
      return '#8E8E93';
    }
    return $r('app.color.app_text_tertiary');
  }
}
