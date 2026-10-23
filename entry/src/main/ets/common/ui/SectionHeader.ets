/**
 * 区块标题：左侧标题 + 可选说明 + 右侧动作文字。
 */
import { AppStore } from '../../app/AppStore';
import { Colors, FontSize, Spacing } from '../design/Tokens';

@ComponentV2
export struct SectionHeader {
  /** V2 全局 Store（主题色）。 */
  @Local store: AppStore = AppStore.connect();
  @Param title: string = '';
  @Param caption: string = '';
  @Param actionText: string = '';
  @Event onAction: () => void = () => {
  };

  build() {
    Row() {
      Column({ space: 2 }) {
        Text(this.title)
          .fontSize(FontSize.Title)
          .fontWeight(FontWeight.Medium)
          .fontColor(Colors.TextPrimary)
        if (this.caption !== '') {
          Text(this.caption)
            .fontSize(FontSize.Caption)
            .fontColor(Colors.TextTertiary)
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      if (this.actionText !== '') {
        Text(this.actionText)
          .fontSize(FontSize.BodySm)
          .fontColor(this.store.accentDisplay)
          .padding({ left: Spacing.Sm, right: Spacing.Sm, top: Spacing.Xs, bottom: Spacing.Xs })
          .onClick(() => {
            this.onAction();
          })
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }
}
