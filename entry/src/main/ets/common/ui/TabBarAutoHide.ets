/**
 * 悬浮页签自动收起：手指下滑（内容向下滚）立即收起，手指上滑（内容回滚）立即恢复。
 *
 * 依据 HDS 官方 API：`HdsTabsController.applyHideAnimation(mode)` /
 * `applyShowAnimation(mode)`，`HdsAnimationMode.SCROLL_ANIMATION` 表示「滚动场景触发的显隐动效」
 * （`~/deveco/command-line-tools/sdk/default/hms/ets/api/@hms.hds.hdsBaseComponent.d.ets`）。
 *
 * 判定方式：不依赖 `onDidScroll` 每帧 yOffset 的正负约定，而是直接读 `Scroller.currentOffset().yOffset`
 * 的实际滚动位置并与上一帧比较：
 * - 位置变大（内容向下滚，手指上滑）→ 立即收起
 * - 位置变小（内容向上回滚，手指下滑）→ 立即恢复
 * 这样滑一下就会收起/恢复，不需要滚到底部或顶部。
 */
import { AppState } from '../../app/AppState';

export class TabBarAutoHide {
  /** 触发所需的最小位移（vp），过滤惯性末端的微小抖动。 */
  private static readonly MIN_DELTA: number = 1;
  private static lastScroller: Scroller | undefined = undefined;
  private static lastOffset: number = 0;
  /** 到达顶部/底部后的「边缘锁」：弹簧回弹期间的方向变化不算用户意图。 */
  private static readonly EDGE_LOCK_MS: number = 400;
  private static readonly EDGE_RANGE: number = 40;
  private static edgeLockUntil: number = 0;
  private static edgeOffset: number = 0;

  /** 由各页面 `Scroll.onDidScroll` 调用，传入该 Scroll 的 Scroller。 */
  static onScroll(scroller: Scroller): void {
    let offset: number = 0;
    try {
      offset = scroller.currentOffset().yOffset;
    } catch (err) {
      return;
    }
    if (TabBarAutoHide.lastScroller !== scroller) {
      // 换了滚动容器（切 Tab / 切周页面）：只记录基线，不触发
      TabBarAutoHide.lastScroller = scroller;
      TabBarAutoHide.lastOffset = offset;
      return;
    }
    const delta: number = offset - TabBarAutoHide.lastOffset;
    TabBarAutoHide.lastOffset = offset;
    const now: number = Date.now();

    // 顶部：页签必须显示；同时把顶部回弹期间的抖动锁住
    if (offset <= 0.5) {
      TabBarAutoHide.edgeLockUntil = now + TabBarAutoHide.EDGE_LOCK_MS;
      TabBarAutoHide.edgeOffset = offset;
      TabBarAutoHide.show();
      return;
    }

    // 底部：滚动到底后弹簧回弹不应把页签「弹出来」
    let atEnd: boolean = false;
    try {
      atEnd = scroller.isAtEnd();
    } catch (err) {
      atEnd = false;
    }
    if (atEnd) {
      TabBarAutoHide.edgeLockUntil = now + TabBarAutoHide.EDGE_LOCK_MS;
      TabBarAutoHide.edgeOffset = offset;
      return;
    }

    // 刚到顶部/底部后的回弹：位置仍在边缘附近时忽略方向判断
    if (now < TabBarAutoHide.edgeLockUntil &&
      Math.abs(offset - TabBarAutoHide.edgeOffset) < TabBarAutoHide.EDGE_RANGE) {
      return;
    }

    if (Math.abs(delta) < TabBarAutoHide.MIN_DELTA) {
      return;
    }
    const hidden: boolean = AppState.store().tabBarHidden;
    if (!hidden && delta > 0) {
      // 内容向下滚（用户上滑手指）→ 收起
      AppState.setTabBarHidden(true);
    } else if (hidden && delta < 0) {
      // 内容向上回滚（用户下滑手指）→ 恢复
      AppState.setTabBarHidden(false);
    }
  }

  private static show(): void {
    const hidden: boolean = AppState.store().tabBarHidden;
    if (hidden) {
      AppState.setTabBarHidden(false);
    }
  }

  /** 回到页顶 / 切换 Tab / 页面重新出现时恢复页签。 */
  static resetAndShow(): void {
    TabBarAutoHide.lastScroller = undefined;
    TabBarAutoHide.lastOffset = 0;
    TabBarAutoHide.edgeLockUntil = 0;
    TabBarAutoHide.edgeOffset = 0;
    const hidden: boolean = AppState.store().tabBarHidden;
    if (hidden) {
      AppState.setTabBarHidden(false);
    }
  }
}
