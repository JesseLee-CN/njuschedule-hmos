/**
 * 教务导入入口页（路由名 `import`，无路由参数）。
 *
 * 对应旧版 `lib/Pages/Import/ImportView.dart` 的「在线学校列表」部分：
 * - 学校列表改为从随包 rawfile 读取（见 SchoolRepository）；
 * - 旧版三条内置路径（Cer/JW/XK）远端开关当前全关，这里只保留 BE 学校列表路径；
 * - 旧版没有搜索框，这里新增按 title / pinyin / description 过滤；
 * - 追加旧版 `getDemoClasses` 的触达入口（示例课表，数据层在 `data/DemoData.ets`）。
 *
 * 根节点是 `HdsNavDestination`：标题栏统一由 common/ui/HdsSubPage 的系统标题栏提供
 * （动态模糊 / 返回键 / 安全区由 HDS 处理），本页只负责内容。
 */
import { resolveNavStack } from '../../common/NavStackResolver';
import { HdsNavDestination } from '@kit.UIDesignKit';
import { AppPreferences } from '../../app/AppPreferences';
import { AppState } from '../../app/AppState';
import { Colors, FontSize, HdsMetrics, Radius, Spacing } from '../../common/design/Tokens';
import { Feedback } from '../../common/ui/Feedback';
import { AppStore } from '../../app/AppStore';
import { AppCard } from '../../common/ui/AppCard';
import { hdsSubPageTitleBar } from '../../common/ui/HdsSubPage';
import { EmptyState } from '../../common/ui/EmptyState';
import { BadgeTone, StatusBadge } from '../../common/ui/StatusBadge';
import { DemoData } from '../../data/DemoData';
import { ImportWebParam } from './ImportParams';
import { SchoolConfig } from './SchoolConfig';
import { SchoolRepository } from './SchoolRepository';

const ROUTE_IMPORT_WEB: string = 'import-web';

@ComponentV2
export struct ImportView {
  /** V2 全局 Store（主题色 / 避让区 / 当前课表）。 */
  @Local store: AppStore = AppStore.connect();

  /** 外壳注入的导航栈；正常也走 onReady 里的 pathStack。 */
  @Param pageStack: NavPathStack = new NavPathStack();

  @Local schools: SchoolConfig[] = [];
  @Local keyword: string = '';
  @Local loading: boolean = true;
  @Local loadError: string = '';
  @Local demoBusy: boolean = false;

  /** 入口页参数里的 tableId（本页不直接使用；导入会新建并切换到新表）。 */
  private entryTableId: number = 0;
  private stack: NavPathStack | null = null;
  private scroller: Scroller = new Scroller();

  aboutToAppear(): void {
    this.loadSchools(false);
  }

  private navStack(): NavPathStack {
    return resolveNavStack(this.stack, this.pageStack);
  }


  private async loadSchools(forceReload: boolean): Promise<void> {
    this.loading = true;
    this.loadError = '';
    try {
      const list: SchoolConfig[] = await SchoolRepository.loadAll(forceReload);
      this.schools = SchoolRepository.sortedByPinyin(list);
    } catch (err) {
      this.schools = [];
      this.loadError = err instanceof Error ? err.message : '读取学校列表失败';
      console.error(`[Import] 学校列表加载失败: ${this.loadError}`);
    } finally {
      this.loading = false;
    }
  }

  private filteredSchools(): SchoolConfig[] {
    return SchoolRepository.search(this.schools, this.keyword);
  }

  private openSchool(school: SchoolConfig): void {
    if (!school.isUsable()) {
      Feedback.toast(this.getUIContext(), '该学校当前不可用');
      return;
    }
    this.navStack().pushPathByName(ROUTE_IMPORT_WEB, new ImportWebParam(school));
  }

  /** 旧版 getDemoClasses 的入口：创建 Demo 课表并切为当前课表。 */
  private async createDemoTable(): Promise<void> {
    if (this.demoBusy) {
      return;
    }
    this.demoBusy = true;
    try {
      const tableId: number = await DemoData.createDemoTable();
      await AppState.switchTable(tableId);
      Feedback.toast(this.getUIContext(), '示例课表已创建，已切换到该课表');
      this.navStack().pop();
    } catch (err) {
      const message: string = err instanceof Error ? err.message : '未知错误';
      console.error(`[Import] 创建示例课表失败: ${message}`);
      Feedback.toast(this.getUIContext(), '创建示例课表失败');
    } finally {
      this.demoBusy = false;
    }
  }

  // ---- UI ----

  @Builder
  private demoCard() {
    AppCard({ contentPadding: 0 }) {
      Row({ space: Spacing.Md }) {
        Row() {
          SymbolGlyph($r('sys.symbol.book_pages'))
            .fontSize(20)
            .fontColor([this.store.accentDisplay])
        }
        .width(40)
        .height(40)
        .borderRadius(Radius.Round)
        .backgroundColor(this.store.accentSoft)
        .justifyContent(FlexAlign.Center)

        Column({ space: 2 }) {
          Text('没有教务账号？先用示例课表看看')
            .fontSize(FontSize.Body)
            .fontColor(Colors.TextPrimary)
            .width('100%')
          Text('创建一张 Demo 课表，立刻体验周视图与课程块')
            .fontSize(FontSize.BodySm)
            .fontColor(Colors.TextTertiary)
            .maxLines(2)
            .width('100%')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        if (this.demoBusy) {
          LoadingProgress()
            .width(22)
            .height(22)
            .color(this.store.accentDisplay)
        } else {
          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize(16)
            .fontColor([Colors.TextTertiary])
        }
      }
      .width('100%')
      .padding({ left: Spacing.Lg, right: Spacing.Md, top: Spacing.Md, bottom: Spacing.Md })
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.createDemoTable();
      })
    }
  }

  /** 从分享码导入：走旧版 ncs://qr 协议（与分享页配对）。 */
  @Builder
  private shareCodeCard() {
    AppCard({ contentPadding: 0 }) {
      Row({ space: Spacing.Md }) {
        Row() {
          SymbolGlyph($r('sys.symbol.qrcode'))
            .fontSize(20)
            .fontColor([this.store.accentDisplay])
        }
        .width(40)
        .height(40)
        .borderRadius(Radius.Round)
        .backgroundColor(this.store.accentSoft)
        .justifyContent(FlexAlign.Center)

        Column({ space: 2 }) {
          Text('从分享码导入')
            .fontSize(FontSize.Body)
            .fontColor(Colors.TextPrimary)
            .width('100%')
          Text('粘贴同学分享的 ncs://qr 课表编码')
            .fontSize(FontSize.BodySm)
            .fontColor(Colors.TextTertiary)
            .maxLines(2)
            .width('100%')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(16)
          .fontColor([Colors.TextTertiary])
      }
      .width('100%')
      .padding({ left: Spacing.Lg, right: Spacing.Md, top: Spacing.Md, bottom: Spacing.Md })
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.navStack().pushPathByName('import-code', null);
      })
    }
  }

  @Builder
  private searchBox() {
    Search({ value: this.keyword, placeholder: '搜索学校名称或拼音' })
      .width('100%')
      .height(44)
      .backgroundColor(Colors.Surface)
      .borderRadius(Radius.Md)
      .placeholderColor(Colors.TextTertiary)
      .textFont({ size: FontSize.Body })
      .onChange((value: string) => {
        this.keyword = value;
      })
  }

  @Builder
  private schoolRow(school: SchoolConfig) {
    Row({ space: Spacing.Md }) {
      Row() {
        SymbolGlyph($r('sys.symbol.book'))
          .fontSize(18)
          .fontColor([school.disabled ? Colors.TextTertiary : this.store.accentDisplay])
      }
      .width(36)
      .height(36)
      .borderRadius(Radius.Round)
      .backgroundColor(school.disabled ? Colors.SurfaceHigh : this.store.accentSoft)
      .justifyContent(FlexAlign.Center)

      Column({ space: 3 }) {
        Row({ space: Spacing.Sm }) {
          Text(school.title)
            .fontSize(FontSize.Body)
            .fontColor(Colors.TextPrimary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .constraintSize({ maxWidth: '80%' })
          if (school.disabled) {
            StatusBadge({ text: '暂不可用', tone: BadgeTone.Neutral })
          }
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Text(school.description)
          .fontSize(FontSize.BodySm)
          .fontColor(Colors.TextTertiary)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(16)
        .fontColor([Colors.TextTertiary])
    }
    .width('100%')
    .padding({ left: Spacing.Lg, right: Spacing.Md, top: Spacing.Md, bottom: Spacing.Md })
    .alignItems(VerticalAlign.Center)
    .opacity(school.disabled ? 0.5 : 1)
    .onClick(() => {
      this.openSchool(school);
    })
  }

  @Builder
  private schoolList() {
    AppCard({ contentPadding: 0 }) {
      Column() {
        ForEach(this.filteredSchools(), (school: SchoolConfig, index: number) => {
          if (index > 0) {
            Divider()
              .color(Colors.OutlineLight)
              .strokeWidth(1)
              .margin({ left: Spacing.Lg + 36 + Spacing.Md })
          }
          this.schoolRow(school)
        }, (school: SchoolConfig) => `${school.pinyin}|${school.title}`)
      }
      .width('100%')
    }
  }

  build() {
    HdsNavDestination() {
      Column() {
        Scroll(this.scroller) {
          Column() {
            Column({ space: Spacing.Md }) {
              this.demoCard()
              this.shareCodeCard()
              this.searchBox()

              if (this.loading) {
                Column({ space: Spacing.Sm }) {
                  LoadingProgress()
                    .width(30)
                    .height(30)
                    .color(this.store.accentDisplay)
                  Text('正在读取学校列表…')
                    .fontSize(FontSize.BodySm)
                    .fontColor(Colors.TextTertiary)
                }
                .width('100%')
                .height(160)
                .justifyContent(FlexAlign.Center)
              } else if (this.loadError !== '') {
                EmptyState({
                  title: '学校列表加载失败',
                  description: this.loadError,
                  icon: $r('sys.symbol.exclamationmark_circle'),
                  actionText: '重新加载',
                  onAction: () => {
                    this.loadSchools(true);
                  }
                })
              } else if (this.filteredSchools().length === 0) {
                EmptyState({
                  title: '没有匹配的学校',
                  description: '换个关键字试试，或清空搜索框查看全部学校',
                  icon: $r('sys.symbol.magnifyingglass')
                })
              } else {
                this.schoolList()
              }

            }
            .width('100%')
            .constraintSize({ maxWidth: 800 })
            .padding({
              left: Spacing.Lg,
              right: Spacing.Lg,
              top: HdsMetrics.contentTopInset(px2vp(this.store.windowTopInset)) + Spacing.Sm,
              bottom: Spacing.Xxxl
            })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .layoutWeight(1)
        .align(Alignment.Top)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Colors.Background)
    }
    .titleBar(hdsSubPageTitleBar('教务导入', '选择学校并登录教务系统，进入课表页后自动导入'))
    .bindToScrollable([this.scroller])
    .onReady((ctx: NavDestinationContext) => {
      this.stack = ctx.pathStack;
    })
  }
}
