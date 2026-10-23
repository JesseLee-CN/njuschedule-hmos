/**
 * 隐私政策页（路由名 `privacy`）。
 *
 * 正文见 features/settings/legal/LegalDocuments.ets（与 docs/privacy-policy.md 同步）。
 * 静态展示，不联网、不收集信息。
 */
import { HdsNavDestination } from '@kit.UIDesignKit';
import { AppStore } from '../../app/AppStore';
import { Colors, HdsMetrics, Spacing } from '../../common/design/Tokens';
import { hdsSubPageTitleBar } from '../../common/ui/HdsSubPage';
import { LegalDocumentView } from './legal/LegalDocumentView';
import { PRIVACY_POLICY } from './legal/LegalDocuments';

@ComponentV2
export struct PrivacyPage {
  @Local store: AppStore = AppStore.connect();

  private scroller: Scroller = new Scroller();

  build() {
    HdsNavDestination() {
      Column() {
        Scroll(this.scroller) {
          Column() {
            LegalDocumentView({ doc: PRIVACY_POLICY })
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
    .titleBar(hdsSubPageTitleBar('隐私政策'))
    .bindToScrollable([this.scroller])
  }
}
