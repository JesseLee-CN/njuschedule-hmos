/**
 * 用户协议页（路由名 `agreement`）。
 *
 * 正文见 features/settings/legal/LegalDocuments.ets（与 docs/user-agreement.md 同步）。
 * 静态展示，不联网、不收集信息。
 */
import { HdsNavDestination } from '@kit.UIDesignKit';
import { AppStore } from '../../app/AppStore';
import { Colors, HdsMetrics, Spacing } from '../../common/design/Tokens';
import { hdsSubPageTitleBar } from '../../common/ui/HdsSubPage';
import { LegalDocumentView } from './legal/LegalDocumentView';
import { USER_AGREEMENT } from './legal/LegalDocuments';

@ComponentV2
export struct UserAgreementPage {
  @Local store: AppStore = AppStore.connect();

  private scroller: Scroller = new Scroller();

  build() {
    HdsNavDestination() {
      Column() {
        Scroll(this.scroller) {
          Column() {
            LegalDocumentView({ doc: USER_AGREEMENT })
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
    .titleBar(hdsSubPageTitleBar('用户协议'))
    .bindToScrollable([this.scroller])
  }
}
