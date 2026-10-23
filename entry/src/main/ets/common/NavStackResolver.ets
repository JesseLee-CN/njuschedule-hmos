/**
 * 子页面导航栈解析：`HdsNavDestination.onReady` 之前用外壳传入的 `@Param pageStack`，
 * onReady 之后用 NavDestinationContext.pathStack。各子页统一调用，避免重复实现。
 */
export function resolveNavStack(stack: NavPathStack | null, fallback: NavPathStack): NavPathStack {
  return stack === null ? fallback : stack;
}
