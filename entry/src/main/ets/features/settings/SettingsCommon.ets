/**
 * 设置模块内部复用的行组件与标题栏。
 *
 * 只服务于 features/settings，不放 common/ui（那是跨模块通用组件）。
 * 样式统一走 Tokens：卡片表面色 + 行内左右 Spacing.Lg / 上下 Spacing.Md。
 */
import { Colors, FontSize, Radius, Spacing } from '../../common/design/Tokens';
import { AppStore } from '../../app/AppStore';

/** 开关行：左侧标题/说明，右侧 Toggle。 */
@ComponentV2
export struct SettingsSwitchRow {
  /** V2 全局 Store（主题色 / 避让区）。 */
  @Local store: AppStore = AppStore.connect();
  /** 行首图标（HarmonyOS 系统图标库 sys.symbol.*）。 */
  @Param icon: Resource | undefined = undefined;
  @Param title: string = '';
  @Param subtitle: string = '';
  @Param isOn: boolean = false;
  @Event onToggle: (isOn: boolean) => void = () => {
  };

  build() {
    Row({ space: Spacing.Md }) {
      if (this.icon !== undefined) {
        SymbolGlyph(this.icon)
          .fontSize(20)
          .fontColor([Colors.TextSecondary])
      }
      Column({ space: 2 }) {
        Text(this.title)
          .fontSize(FontSize.Body)
          .fontColor(Colors.TextPrimary)
          .width('100%')
        if (this.subtitle !== '') {
          Text(this.subtitle)
            .fontSize(FontSize.BodySm)
            .fontColor(Colors.TextTertiary)
            .width('100%')
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Toggle({ type: ToggleType.Switch, isOn: this.isOn })
        .selectedColor(this.store.accentDisplay)
        .switchPointColor(Colors.Surface)
        .onChange((isOn: boolean) => {
          this.onToggle(isOn);
        })
    }
    .width('100%')
    .padding({ left: Spacing.Lg, right: Spacing.Lg, top: Spacing.Md, bottom: Spacing.Md })
    .alignItems(VerticalAlign.Center)
  }
}

/** 设置行：跳转/信息/动作通用。图标 + 标题/说明 + 可选右侧值/箭头；danger 时标题/图标用错误色。 */
@ComponentV2
export struct SettingsRow {
  /** 行首图标（HarmonyOS 系统图标库 sys.symbol.*）。 */
  @Param icon: Resource | undefined = undefined;
  @Param title: string = '';
  @Param subtitle: string = '';
  @Param trailingText: string = '';
  /** 右侧箭头（跳转型页面用 true）。 */
  @Param showArrow: boolean = true;
  /** 危险操作（删除/清空）：标题与图标用错误色。 */
  @Param danger: boolean = false;
  @Event onTap: () => void = () => {
  };

  build() {
    Row({ space: Spacing.Md }) {
      if (this.icon !== undefined) {
        SymbolGlyph(this.icon)
          .fontSize(20)
          .fontColor([this.danger ? Colors.Error : Colors.TextSecondary])
      }
      Column({ space: 2 }) {
        Text(this.title)
          .fontSize(FontSize.Body)
          .fontColor(this.danger ? Colors.Error : Colors.TextPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        if (this.subtitle !== '') {
          Text(this.subtitle)
            .fontSize(FontSize.BodySm)
            .fontColor(Colors.TextTertiary)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      if (this.trailingText !== '') {
        Text(this.trailingText)
          .fontSize(FontSize.BodySm)
          .fontColor(Colors.TextTertiary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .constraintSize({ maxWidth: 160 })
      }
      if (this.showArrow) {
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(16)
          .fontColor([Colors.TextTertiary])
      }
    }
    .width('100%')
    .padding({ left: Spacing.Lg, right: Spacing.Lg, top: Spacing.Md, bottom: Spacing.Md })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.onTap();
    })
  }
}

/** 加减stepper：用于当前周调整。 */
@ComponentV2
export struct SettingsStepper {
  /** V2 全局 Store（主题色 / 避让区）。 */
  @Local store: AppStore = AppStore.connect();
  @Param value: number = 1;
  @Param minValue: number = 1;
  @Param maxValue: number = 25;
  /** 显示文本，如「第 3 周」。 */
  @Param displayText: string = '';
  @Event onStep: (delta: number) => void = () => {
  };

  build() {
    Row({ space: Spacing.Sm }) {
      Row() {
        SymbolGlyph($r('sys.symbol.minus'))
          .fontSize(16)
          .fontColor([this.value <= this.minValue ? Colors.TextTertiary : this.store.accentDisplay])
      }
      .width(36)
      .height(36)
      .borderRadius(Radius.Round)
      .backgroundColor(Colors.SurfaceHigh)
      .justifyContent(FlexAlign.Center)
      .opacity(this.value <= this.minValue ? 0.45 : 1)
      .onClick(() => {
        if (this.value > this.minValue) {
          this.onStep(-1);
        }
      })

      Text(this.displayText)
        .fontSize(FontSize.Body)
        .fontWeight(FontWeight.Medium)
        .fontColor(Colors.TextPrimary)
        .textAlign(TextAlign.Center)
        .constraintSize({ minWidth: 64 })

      Row() {
        SymbolGlyph($r('sys.symbol.plus'))
          .fontSize(16)
          .fontColor([this.value >= this.maxValue ? Colors.TextTertiary : this.store.accentDisplay])
      }
      .width(36)
      .height(36)
      .borderRadius(Radius.Round)
      .backgroundColor(Colors.SurfaceHigh)
      .justifyContent(FlexAlign.Center)
      .opacity(this.value >= this.maxValue ? 0.45 : 1)
      .onClick(() => {
        if (this.value < this.maxValue) {
          this.onStep(1);
        }
      })
    }
    .alignItems(VerticalAlign.Center)
  }
}

/** 行分隔线：与行内文字左对齐。 */
@ComponentV2
export struct SettingsRowDivider {
  build() {
    Divider()
      .color(Colors.OutlineLight)
      .strokeWidth(1)
      .margin({ left: Spacing.Lg, right: Spacing.Lg })
  }
}
