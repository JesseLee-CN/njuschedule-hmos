/**
 * 第三方许可证详情页（路由名 `license-detail`）。
 *
 * 从「关于 → 第三方许可证」点击组件进入，展示该组件许可证全文（可长按选择复制）；
 * 组织逻辑参考同类应用的「第三方许可证详情」：标题栏显示组件名，正文为完整许可证文本。
 */
import { HdsNavDestination } from '@kit.UIDesignKit';
import { AppStore } from '../../app/AppStore';
import { LicenseDetailParam } from '../../common/RouteParams';
import { Colors, FontSize, HdsMetrics, Spacing } from '../../common/design/Tokens';
import { openUrl } from '../../common/ui/OpenLink';
import { hdsSubPageTitleBar } from '../../common/ui/HdsSubPage';
import { AppCard } from '../../common/ui/AppCard';
import { findThirdPartyLicense, ThirdPartyLicense } from './ThirdPartyLicenseData';

@ComponentV2
export struct LicenseDetailPage {
  @Local store: AppStore = AppStore.connect();
  /** 组件信息（含许可证全文）。 */
  @Local license: ThirdPartyLicense | undefined = undefined;

  private scroller: Scroller = new Scroller();

  private titleText(): string {
    return this.license === undefined ? '许可证' : this.license.name;
  }

  private copyUrl(): void {
    if (this.license === undefined) {
      return;
    }
    openUrl(this.getUIContext(), this.license.url);
  }

  @Builder
  private summaryCard() {
    if (this.license !== undefined) {
      AppCard() {
        Column({ space: Spacing.Xs }) {
          Text(`${this.license.license} · ${this.license.copyright}`)
            .fontSize(FontSize.BodySm)
            .fontColor(Colors.TextSecondary)
            .width('100%')
          Text(`用途：${this.license.usage}`)
            .fontSize(FontSize.BodySm)
            .fontColor(Colors.TextTertiary)
            .width('100%')
          Text(this.license.url)
            .fontSize(FontSize.Caption)
            .fontColor(this.store.accentDisplay)
            .width('100%')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text('点击打开项目地址')
            .fontSize(FontSize.Caption)
            .fontColor(Colors.TextTertiary)
            .width('100%')
        }
        .width('100%')
        .onClick(() => {
          this.copyUrl();
        })
      }
    }
  }

  build() {
    HdsNavDestination() {
      Column() {
        Scroll(this.scroller) {
          Column({ space: Spacing.Lg }) {
            this.summaryCard()

            if (this.license !== undefined) {
              AppCard() {
                Column() {
                  Text(this.license.text)
                    .fontSize(FontSize.BodySm)
                    .fontColor(Colors.TextSecondary)
                    .lineHeight(21)
                    .width('100%')
                    .copyOption(CopyOptions.LocalDevice)
                }
                .width('100%')
              }
            } else {
              Text('未找到该组件的许可证信息')
                .fontSize(FontSize.BodySm)
                .fontColor(Colors.TextTertiary)
                .width('100%')
                .textAlign(TextAlign.Center)
                .padding({ top: Spacing.Xxl })
            }
          }
          .width('100%')
          .constraintSize({ maxWidth: 800 })
          .padding({
            left: Spacing.Lg,
            right: Spacing.Lg,
            top: HdsMetrics.contentTopInset(px2vp(this.store.windowTopInset)) + Spacing.Md,
            bottom: Spacing.Xxxl
          })
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
    .titleBar(hdsSubPageTitleBar(this.titleText()))
    .bindToScrollable([this.scroller])
    .onReady((ctx: NavDestinationContext) => {
      const raw: Object | undefined = ctx.pathInfo.param as Object;
      if (raw instanceof LicenseDetailParam) {
        this.license = findThirdPartyLicense(raw.name);
      }
    })
  }
}
