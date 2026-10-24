/**
 * 应用外壳：唯一 @Entry。
 *
 * 结构照 `hydrotoolkit-hmos` 的约定：HdsNavigation（系统材质标题栏）+ HdsTabs
 * （底部悬浮胶囊 Tab）+ NavPathStack 路由表。三个主 Tab：课表 / 课程 / 设置。
 *
 * 路由表见 docs/porting/architecture.md。子页面自行提供标题栏
 * （HdsNavDestination / NavDestination 自带 titleBar），这里只负责分发。
 */
import {
  HdsNavigation,
  HdsNavigationTitleMode,
  HdsNavigationTitle,
  HdsTabs,
  HdsTabsController,
  HdsAnimationMode,
  hdsMaterial,
  ScrollEffectType
} from '@kit.UIDesignKit';
import { SymbolGlyphModifier } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { AppPreferences, PrefKeys } from '../app/AppPreferences';
import { AppState } from '../app/AppState';
import { AppStore } from '../app/AppStore';
import { AppBootstrap } from '../app/AppBootstrap';
import { TabBarAutoHide } from '../common/ui/TabBarAutoHide';

import { CourseTableRepository } from '../data/CourseTableRepository';
import { CourseTable } from '../data/models/Models';
import { BreakpointName, resolveBreakpoint } from '../common/design/Breakpoints';
import { Colors, FontSize, HdsMetrics, Radius, Spacing } from '../common/design/Tokens';
import { CourseDetailPage } from '../features/courses/CourseDetailPage';
import { CourseEditPage } from '../features/courses/CourseEditPage';
import { CoursesView } from '../features/courses/CoursesView';
import { ImportView } from '../features/import/ImportView';
import { LecturesPage } from '../features/lectures/LecturesPage';
import { ImportWebPage } from '../features/import/ImportWebPage';
import { AboutPage } from '../features/settings/AboutPage';
import { OpenSourceLicensesPage } from '../features/settings/OpenSourceLicensesPage';
import { AcknowledgementsPage } from '../features/settings/AcknowledgementsPage';
import { LicenseDetailPage } from '../features/settings/LicenseDetailPage';
import { PrivacyPage } from '../features/settings/PrivacyPage';
import { LegalDocumentView } from '../features/settings/legal/LegalDocumentView';
import { PRIVACY_POLICY } from '../features/settings/legal/LegalDocuments';
import { ImportCodePage } from '../features/share/ImportCodePage';
import { SharePage } from '../features/share/SharePage';
import { ManageTablesPage } from '../features/settings/ManageTablesPage';
import { MoreSettingsPage } from '../features/settings/MoreSettingsPage';
import { SettingsView } from '../features/settings/SettingsView';
import { TimetableView } from '../features/timetable/TimetableView';

@Entry
@ComponentV2
struct Index {
  private hdsTabsController: HdsTabsController = new HdsTabsController();
  /** 每个 Tab 独立的 Scroller，只把当前 Tab 的绑定给导航做滚动模糊联动（官方 FAQ 场景二）。 */
  private timetableScroller: Scroller = new Scroller();
  /** 课表 25 个周页面各自的滚动容器（全部绑定给标题栏模糊联动）。 */
  private weekScrollers: Scroller[] = [];
  private coursesScroller: Scroller = new Scroller();
  private settingsScroller: Scroller = new Scroller();
  /** 首启弹窗内查看隐私政策全文时的滚动容器。 */
  private legalDocScroller: Scroller = new Scroller();
  private pageStack: NavPathStack = new NavPathStack();
  private tabLabels: string[] = ['课表', '课程', '设置'];

  /** V2 全局 Store。 */
  @Local store: AppStore = AppStore.connect();
  /** 当前课表名（标题栏副标题显示「课表名 + 第 N 周」）。 */
  @Local tableName: string = '我的课表';
  @Local activeTabIndex: number = 0;
  /** 首启弹窗是否正在查看隐私政策全文。 */
  @Local showPrivacyDoc: boolean = false;
  /** 只把「当前 Tab 正在使用的」Scroller 绑定给 HdsNavigation（官方 FAQ 场景二），避免 25 个周页面互相干扰。 */
  @Local navScrollables: Scroller[] = [];
  /** 当前绑定给课表 Tab 的滚动容器（25 个周页面轮换）。 */
  private boundTimetableScroller: Scroller | undefined = undefined;

  aboutToAppear(): void {
    for (let i = 0; i < 25; i++) {
      this.weekScrollers.push(new Scroller());
    }
    this.hdsTabsController.bindScroller(1, this.coursesScroller);
    this.hdsTabsController.bindScroller(2, this.settingsScroller);
    this.navScrollables = [this.timetableScroller];
    this.loadTableName();
    this.updateBreakpoint();
  }

  aboutToDisappear(): void {
    this.hdsTabsController.unbindScroller(this.coursesScroller);
    this.hdsTabsController.unbindScroller(this.settingsScroller);
    if (this.boundTimetableScroller !== undefined) {
      this.hdsTabsController.unbindScroller(this.boundTimetableScroller);
      this.boundTimetableScroller = undefined;
    }
  }

  /** 滚动方向变化 → HDS 页签栏显隐动画（官方 HdsTabsController.applyHide/ShowAnimation）。 */
  @Monitor('store.tabBarHidden')
  private onTabBarHiddenChanged(_monitor: IMonitor): void {
    try {
      if (this.store.tabBarHidden) {
        this.hdsTabsController.applyHideAnimation(HdsAnimationMode.SCROLL_ANIMATION);
      } else {
        this.hdsTabsController.applyShowAnimation(HdsAnimationMode.SCROLL_ANIMATION);
      }
    } catch (err) {
      console.warn(`[Index] tab bar animation failed: ${JSON.stringify(err)}`);
    }
  }

  /** 课表页切换周页面时，把当前页的 Scroller 重新绑定给 HdsTabs，并同步给 HdsNavigation 标题栏模糊。 */
  private bindTimetableScroller(scroller: Scroller): void {
    if (this.boundTimetableScroller === scroller) {
      return;
    }
    try {
      if (this.boundTimetableScroller !== undefined) {
        this.hdsTabsController.unbindScroller(this.boundTimetableScroller);
      }
      this.hdsTabsController.bindScroller(0, scroller);
      this.boundTimetableScroller = scroller;
      if (this.activeTabIndex === 0) {
        this.navScrollables = [scroller];
      }
    } catch (err) {
      console.warn(`[Index] bind timetable scroller failed: ${JSON.stringify(err)}`);
    }
  }

  /** 当前 Tab 对应的滚动容器（HdsNavigation 标题栏模糊只绑当前这一个，官方 FAQ 场景二）。 */
  private currentTabScroller(): Scroller[] {
    if (this.activeTabIndex === 0) {
      const active: Scroller = this.boundTimetableScroller !== undefined ?
        this.boundTimetableScroller : this.timetableScroller;
      return [active];
    }
    if (this.activeTabIndex === 1) {
      return [this.coursesScroller];
    }
    return [this.settingsScroller];
  }

  @Monitor('store.windowWidth')
  onWindowWidthChange(_monitor: IMonitor): void {
    this.updateBreakpoint();
  }

  private contentTopSpace(): number {
    // 沉浸布局下内容从窗口顶部开始，需要额外让出状态栏高度
    return HdsMetrics.TitleBarHeight + HdsMetrics.TitleBarBreathing + px2vp(this.store.windowTopInset);
  }

  private updateBreakpoint(): void {
    const widthVp: number = this.store.windowWidth > 0 ? this.getUIContext().px2vp(this.store.windowWidth) : 360;
    const next: BreakpointName = resolveBreakpoint(widthVp);
    if (next !== this.store.breakpoint) {
      AppState.setBreakpoint(next);
    }
  }

  private async loadTableName(): Promise<void> {
    if (this.store.tableId <= 0) {
      return;
    }
    try {
      const table: CourseTable | null = await CourseTableRepository.getById(this.store.tableId);
      if (table !== null) {
        this.tableName = table.name;
      }
    } catch (err) {
      console.warn(`[Index] load table name failed: ${JSON.stringify(err)}`);
    }
  }

  @Monitor('store.tableId')
  private onTitleTableChanged(_monitor: IMonitor): void {
    this.loadTableName();
  }

  @Monitor('store.dataRevision')
  private onDataRevisionChanged(_monitor: IMonitor): void {
    this.loadTableName();
  }

  /** 标题栏标题内容：课表页不显示副标题（由 bottomBuilder 取代），其他 Tab 仍显示 Tab 名。 */
  private titleContent(): HdsNavigationTitle {
    if (this.activeTabIndex === 0) {
      // 直接替换原来的「课表」副标题：课表名 + 当前周（点击由顶部透明热区打开周次选择器）
      return { mainTitle: '呢喃课表', subTitle: `${this.tableName} · 第 ${this.store.tmpWeekIndex} 周` };
    }
    return { mainTitle: '呢喃课表', subTitle: this.tabLabels[this.activeTabIndex] };
  }

  /** 底部页签样式：选中态跟随主题强调色（图标 + 文字）。 */
  private bottomTabBar(icon: Resource, label: string): BottomTabBarStyle {
    return new BottomTabBarStyle({
      normal: new SymbolGlyphModifier(icon).fontColor([Colors.TextSecondary]),
      selected: new SymbolGlyphModifier(icon).fontColor([this.store.accentDisplay])
    }, label).labelStyle({
      selectedColor: this.store.accentDisplay,
      unselectedColor: Colors.TextSecondary
    });
  }

  @Builder
  private destinationBuilder(name: string) {
    if (name === 'course-detail') {
      CourseDetailPage({ pageStack: this.pageStack })
    } else if (name === 'course-edit') {
      CourseEditPage({ pageStack: this.pageStack })
    } else if (name === 'tables') {
      ManageTablesPage({pageStack: this.pageStack})
    } else if (name === 'more-settings') {
      MoreSettingsPage({pageStack: this.pageStack, tableId: this.store.tableId})
    } else if (name === 'privacy') {
      PrivacyPage({})
    } else if (name === 'about') {
      AboutPage({pageStack: this.pageStack})
    } else if (name === 'licenses') {
      OpenSourceLicensesPage({pageStack: this.pageStack})
    } else if (name === 'license-detail') {
      LicenseDetailPage({})
    } else if (name === 'acknowledgements') {
      AcknowledgementsPage({})
    } else if (name === 'import') {
      ImportView({ pageStack: this.pageStack })
    } else if (name === 'import-web') {
      ImportWebPage({ pageStack: this.pageStack })
    } else if (name === 'lectures') {
      LecturesPage({})
    } else if (name === 'share') {
      SharePage({})
    } else if (name === 'import-code') {
      ImportCodePage({pageStack: this.pageStack})
    }
  }

  /** 首启确认：摘要面板 + 可切换到隐私政策全文（不离开弹窗即可阅读）。 */
  @Builder
  private privacyOverlay() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(Colors.Scrim)

      if (!this.showPrivacyDoc) {
        this.privacyConsentPanel()
      } else {
        this.privacyDocumentPanel()
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private privacyConsentPanel() {
    Column({ space: Spacing.Lg }) {
      Text('隐私政策')
        .fontSize(FontSize.Headline)
        .fontWeight(FontWeight.Bold)
        .fontColor(Colors.TextPrimary)
        .width('100%')

      Scroll() {
        Column({ space: Spacing.Sm }) {
          Text('欢迎使用「呢喃课表」！在开始之前，请了解：')
            .fontSize(FontSize.BodySm)
            .fontColor(Colors.TextSecondary)
            .width('100%')
          Text('· 我们不会收集、上传你的任何个人信息；没有账号体系，也没有自建服务器。')
            .fontSize(FontSize.BodySm)
            .fontColor(Colors.TextSecondary)
            .width('100%')
          Text('· 课表、课程、设置、背景图与小组件数据全部保存在本机，卸载即删除。')
            .fontSize(FontSize.BodySm)
            .fontColor(Colors.TextSecondary)
            .width('100%')
          Text('· 网络仅用于你主动使用的教务导入与讲座列表；分享码在本机生成。')
            .fontSize(FontSize.BodySm)
            .fontColor(Colors.TextSecondary)
            .width('100%')
          Text('· 本应用不集成任何第三方 SDK，仅申请网络权限。')
            .fontSize(FontSize.BodySm)
            .fontColor(Colors.TextSecondary)
            .width('100%')
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }
      .height(168)
      .width('100%')
      .scrollBar(BarState.Off)
      .align(Alignment.Top)

      Button('查看完整隐私政策')
        .width('100%')
        .height(40)
        .fontSize(FontSize.Caption)
        .backgroundColor(Colors.SurfaceHigh)
        .fontColor(Colors.TextPrimary)
        .onClick(() => {
          this.showPrivacyDoc = true;
        })

      Text('点击「同意」即表示你已阅读并同意《隐私政策》的全部内容。')
        .fontSize(FontSize.Caption)
        .fontColor(Colors.TextTertiary)
        .width('100%')

      Row({ space: Spacing.Md }) {
        Button('不同意并退出')
          .layoutWeight(1)
          .height(44)
          .fontSize(FontSize.BodySm)
          .backgroundColor(Colors.SurfaceHigh)
          .fontColor(Colors.TextSecondary)
          .onClick(() => {
            this.declinePrivacy();
          })
        Button('同意')
          .layoutWeight(1)
          .height(44)
          .fontSize(FontSize.BodySm)
          .backgroundColor(this.store.accentDisplay)
          .fontColor(this.store.accentOn)
          .onClick(() => {
            this.acceptPrivacy();
          })
      }
      .width('100%')
    }
    .width('86%')
    .constraintSize({ maxWidth: 520 })
    .padding(Spacing.Xl)
    .backgroundColor(Colors.Dialog)
    .borderRadius(Radius.Xl)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private privacyDocumentPanel() {
    Column({ space: Spacing.Md }) {
      Row({ space: Spacing.Sm }) {
        Text('‹ 返回')
          .fontSize(FontSize.BodySm)
          .fontColor(this.store.accentDisplay)
          .onClick(() => {
            this.showPrivacyDoc = false;
          })
        Text('隐私政策')
          .fontSize(FontSize.Title)
          .fontWeight(FontWeight.Medium)
          .fontColor(Colors.TextPrimary)
          .layoutWeight(1)
          .textAlign(TextAlign.End)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Scroll(this.legalDocScroller) {
        Column() {
          LegalDocumentView({ doc: PRIVACY_POLICY })
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)

      Button('返回')
        .width('100%')
        .height(44)
        .fontSize(FontSize.BodySm)
        .backgroundColor(Colors.SurfaceHigh)
        .fontColor(Colors.TextPrimary)
        .onClick(() => {
          this.showPrivacyDoc = false;
        })
    }
    .width('92%')
    .height('88%')
    .constraintSize({ maxWidth: 720 })
    .padding(Spacing.Xl)
    .backgroundColor(Colors.Dialog)
    .borderRadius(Radius.Xl)
    .alignItems(HorizontalAlign.Start)
  }

  private acceptPrivacy(): void {
    this.showPrivacyDoc = false;
    AppPreferences.put(PrefKeys.PrivacyVersion, AppBootstrap.PRIVACY_VERSION).then(() => {
      AppState.setPrivacyAccepted(true);
    }).catch((err: Error) => {
      console.warn(`[Index] save privacy acceptance failed: ${JSON.stringify(err)}`);
      AppState.setPrivacyAccepted(true);
    });
  }

  private declinePrivacy(): void {
    try {
      const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
      context.terminateSelf();
    } catch (err) {
      console.warn(`[Index] terminateSelf failed: ${JSON.stringify(err)}`);
    }
  }

  build() {
    Stack() {
      Column() {
      HdsNavigation(this.pageStack) {
        HdsTabs({ controller: this.hdsTabsController }) {
          TabContent() {
            Column() {
              TimetableView({
                pageStack: this.pageStack,
                scroller: this.timetableScroller,
                weekScrollers: this.weekScrollers,
                onActiveScrollerChange: (scroller: Scroller) => {
                  this.bindTimetableScroller(scroller);
                }
              })
            }
            .width('100%')
            .height('100%')
            .padding({ top: 0 })
            .backgroundColor(Colors.Background)
          }
          .tabBar(this.bottomTabBar($r('sys.symbol.calendar'), this.tabLabels[0]))

          TabContent() {
            Column() {
              CoursesView({ pageStack: this.pageStack, tableId: this.store.tableId, scroller: this.coursesScroller })
            }
            .width('100%')
            .height('100%')
            .padding({ top: 0 })
            .backgroundColor(Colors.Background)
          }
          .tabBar(this.bottomTabBar($r('sys.symbol.book'), this.tabLabels[1]))

          TabContent() {
            Column() {
              SettingsView({ pageStack: this.pageStack, scroller: this.settingsScroller })
            }
            .width('100%')
            .height('100%')
            .padding({ top: 0 })
            .backgroundColor(Colors.Background)
          }
          .tabBar(this.bottomTabBar($r('sys.symbol.gearshape'), this.tabLabels[2]))
        }
        .animationDuration(250)
        .vertical(false)
        .scrollable(false)
        .barPosition(BarPosition.End)
        // 悬浮胶囊页签栏：需要 barOverlap(true) 才能浮在内容之上
        .barOverlap(true)
        .barFloatingStyle({
          barWidth: { smallWidth: 220, mediumWidth: 300, largeWidth: 360 },
          barBottomMargin: Math.max(px2vp(this.store.windowBottomInset) + 8, 24),
          systemMaterialEffect: {
            materialType: hdsMaterial.MaterialType.IMMERSIVE,
            materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
          }
        })
        .onChange((index: number) => {
          this.activeTabIndex = index;
          // 切 Tab 时恢复悬浮页签（避免在别的页面保持收起状态）
          TabBarAutoHide.resetAndShow();
          // 标题栏模糊只绑定当前 Tab 的滚动容器
          this.navScrollables = this.currentTabScroller();
        })
        .width('100%')
        .height('100%')
        .backgroundColor(Colors.Background)
      }
      .mode(NavigationMode.Stack)
      .hideBackButton(true)
      .titleMode(HdsNavigationTitleMode.MINI)
      .titleBar({
        avoidLayoutSafeArea: true,
        content: {
          title: this.titleContent(),
        },
        style: {
          // 与 hydrotoolkit 相同：静止透明，内容滚到标题栏下方时渐变模糊
          scrollEffectOpts: {
            scrollEffectType: ScrollEffectType.GRADIENT_BLUR
          },
          systemMaterialEffect: {
            materialType: hdsMaterial.MaterialType.ADAPTIVE,
            materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
          }
        }
      })
      .bindToScrollable(this.navScrollables)
      .navDestination(this.destinationBuilder)
      .width('100%')
      .height('100%')
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Colors.Background)

      // 标题栏副标题热区：点击「课表名 · 第 N 周」打开周次选择器
      // （HDS 的 subTitleBuilder 只支持 MODAL 模式，MINI 模式用透明热区复用副标题位置）
      if (this.activeTabIndex === 0) {
        Row()
          .width('100%')
          .height(30)
          .position({ x: 0, y: this.contentTopSpace() - 30 })
          .hitTestBehavior(HitTestMode.Default)
          .onClick(() => {
            AppState.setWeekPickerOpen(true);
          })
      }

      if (!this.store.privacyAccepted) {
        this.privacyOverlay()
      }
    }
    .width('100%')
    .height('100%')
  }
}
