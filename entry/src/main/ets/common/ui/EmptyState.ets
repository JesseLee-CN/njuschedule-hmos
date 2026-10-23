/**
 * 空状态：无课程 / 无课表 / 导入失败等场景。
 */
import { AppStore } from '../../app/AppStore';
import { Colors, FontSize, Spacing } from '../design/Tokens';

@ComponentV2
export struct EmptyState {
  /** V2 全局 Store（主题色）。 */
  @Local store: AppStore = AppStore.connect();
  @Param title: string = '';
  @Param description: string = '';
  @Param icon: Resource = $r('sys.symbol.calendar');
  @Param actionText: string = '';
  @Event onAction: () => void = () => {
  };
  /** 可选第二动作（例如空课程页的「教务导入」）。 */
  @Param secondaryText: string = '';
  @Event onSecondary: () => void = () => {
  };

  build() {
    Column({ space: Spacing.Sm }) {
      SymbolGlyph(this.icon)
        .fontSize(44)
        .fontColor([Colors.TextTertiary])
      Text(this.title)
        .fontSize(FontSize.Body)
        .fontColor(Colors.TextSecondary)
        .textAlign(TextAlign.Center)
      if (this.description !== '') {
        Text(this.description)
          .fontSize(FontSize.BodySm)
          .fontColor(Colors.TextTertiary)
          .textAlign(TextAlign.Center)
      }
      if (this.actionText !== '' || this.secondaryText !== '') {
        Row({ space: Spacing.Md }) {
          if (this.actionText !== '') {
            Button(this.actionText)
              .fontSize(FontSize.BodySm)
              .height(36)
              .backgroundColor(this.store.accentDisplay)
              .fontColor(this.store.accentOn)
              .onClick(() => {
                this.onAction();
              })
          }
          if (this.secondaryText !== '') {
            Button(this.secondaryText)
              .fontSize(FontSize.BodySm)
              .height(36)
              .backgroundColor(Colors.SurfaceHigh)
              .fontColor(Colors.TextPrimary)
              .onClick(() => {
                this.onSecondary();
              })
          }
        }
        .justifyContent(FlexAlign.Center)
        .margin({ top: Spacing.Sm })
      }
    }
    .width('100%')
    .padding({ top: Spacing.Xxxl * 2, bottom: Spacing.Xxxl * 2 })
    .justifyContent(FlexAlign.Center)
  }
}
