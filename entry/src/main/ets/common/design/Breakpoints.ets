/**
 * 断点模型（沿用 `ref/applications_app_samples` 的 320 / 600 / 840vp 官方阈值，
 * 与 `hydrotoolkit-hmos` 保持一致），并附带按断点取值的 `BreakpointType<T>`。
 */
export enum BreakpointName {
  Xs = 'xs',
  Sm = 'sm',
  Md = 'md',
  Lg = 'lg'
}

export class BreakpointRange {
  static readonly Sm: number = 320;
  static readonly Md: number = 600;
  static readonly Lg: number = 840;
}

export function resolveBreakpoint(widthVp: number): BreakpointName {
  if (widthVp >= BreakpointRange.Lg) {
    return BreakpointName.Lg;
  }
  if (widthVp >= BreakpointRange.Md) {
    return BreakpointName.Md;
  }
  if (widthVp >= BreakpointRange.Sm) {
    return BreakpointName.Sm;
  }
  return BreakpointName.Xs;
}

export function isExpandedBreakpoint(breakpoint: BreakpointName): boolean {
  return breakpoint === BreakpointName.Md || breakpoint === BreakpointName.Lg;
}

export function isTabletBreakpoint(breakpoint: BreakpointName): boolean {
  return breakpoint === BreakpointName.Lg;
}

export class BreakpointType<T> {
  private xsValue: T;
  private smValue: T;
  private mdValue: T;
  private lgValue: T;

  constructor(xs: T, sm: T, md: T, lg: T) {
    this.xsValue = xs;
    this.smValue = sm;
    this.mdValue = md;
    this.lgValue = lg;
  }

  value(breakpoint: BreakpointName): T {
    if (breakpoint === BreakpointName.Lg) {
      return this.lgValue;
    }
    if (breakpoint === BreakpointName.Md) {
      return this.mdValue;
    }
    if (breakpoint === BreakpointName.Sm) {
      return this.smValue;
    }
    return this.xsValue;
  }
}
