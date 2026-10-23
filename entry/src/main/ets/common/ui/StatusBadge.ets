/**
 * 状态徽标：导入来源、当前周、课程类型等短标签。
 */
import { AppStore } from '../../app/AppStore';
import { Colors, FontSize, Radius, Spacing } from '../design/Tokens';

export enum BadgeTone {
  Neutral = 'neutral',
  Primary = 'primary',
  Success = 'success',
  Warning = 'warning',
  Error = 'error'
}

@ComponentV2
export struct StatusBadge {
  /** V2 全局 Store（主题色）。 */
  @Local store: AppStore = AppStore.connect();
  @Param text: string = '';
  @Param tone: BadgeTone = BadgeTone.Neutral;

  private textColor(): ResourceColor {
    if (this.tone === BadgeTone.Primary) {
      return this.store.accentDisplay;
    }
    if (this.tone === BadgeTone.Success) {
      return Colors.Success;
    }
    if (this.tone === BadgeTone.Warning) {
      return Colors.Warning;
    }
    if (this.tone === BadgeTone.Error) {
      return Colors.Error;
    }
    return Colors.TextSecondary;
  }

  private badgeBackgroundColor(): ResourceColor {
    if (this.tone === BadgeTone.Primary) {
      return this.store.accentSoft;
    }
    if (this.tone === BadgeTone.Success) {
      return Colors.SuccessLight;
    }
    if (this.tone === BadgeTone.Warning) {
      return Colors.WarningLight;
    }
    if (this.tone === BadgeTone.Error) {
      return Colors.ErrorLight;
    }
    return Colors.SurfaceHigh;
  }

  build() {
    Text(this.text)
      .fontSize(FontSize.Caption)
      .fontColor(this.textColor())
      .backgroundColor(this.badgeBackgroundColor())
      .borderRadius(Radius.Xs)
      .padding({ left: Spacing.Sm, right: Spacing.Sm, top: 2, bottom: 2 })
  }
}
