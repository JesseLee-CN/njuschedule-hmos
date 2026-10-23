/**
 * 课程表单内部通用组件（只被 features/courses 使用）。
 *
 * 刻意不放进 `common/ui`：这些组件带着课程表单的语义（必填星号、周次 chip、
 * 色池色块），不是跨功能通用件。视觉全部走 design/Tokens 令牌。
 */
import { CourseBlockColors, Colors, FontSize, Radius, Spacing } from '../../common/design/Tokens';
import { AppStore } from '../../app/AppStore';

/** 表单分区卡片：标题 + 说明 + 内容。 */
@ComponentV2
export struct FormSection {
  @Param title: string = '';
  @Param caption: string = '';
  @BuilderParam content: () => void;

  build() {
    Column({ space: Spacing.Md }) {
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
      .width('100%')

      this.content()
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(Spacing.Lg)
    .backgroundColor(Colors.Surface)
    .borderRadius(Radius.Lg)
    .border({ width: 1, color: Colors.OutlineLight })
  }
}

/** 文本框：单行输入 / 多行备注共用，V2 下用 `@Param text + @Event onTextChange` 双向同步给父组件。 */
@ComponentV2
export struct CourseTextField {
  @Param label: string = '';
  @Param placeholder: string = '';
  @Param multiline: boolean = false;
  @Param required: boolean = false;
  @Param error: string = '';
  @Param text: string = '';
  @Event onTextChange: (value: string) => void = () => {
  };

  build() {
    Column({ space: Spacing.Xs }) {
      Row({ space: Spacing.Xs }) {
        Text(this.label)
          .fontSize(FontSize.Caption)
          .fontColor(Colors.TextSecondary)
        if (this.required) {
          Text('*')
            .fontSize(FontSize.Caption)
            .fontColor(Colors.Error)
        }
      }
      .alignItems(VerticalAlign.Center)

      if (this.multiline) {
        TextArea({ text: this.text, placeholder: this.placeholder })
          .width('100%')
          .height(96)
          .fontSize(FontSize.Body)
          .fontColor(Colors.TextPrimary)
          .placeholderColor(Colors.TextTertiary)
          .backgroundColor(Colors.SurfaceHigh)
          .borderRadius(Radius.Sm)
          .padding(Spacing.Sm)
          .onChange((value: string) => {
            this.onTextChange(value);
          })
      } else {
        TextInput({ text: this.text, placeholder: this.placeholder })
          .width('100%')
          .height(40)
          .fontSize(FontSize.Body)
          .fontColor(Colors.TextPrimary)
          .placeholderColor(Colors.TextTertiary)
          .backgroundColor(Colors.SurfaceHigh)
          .borderRadius(Radius.Sm)
          .padding({ left: Spacing.Md, right: Spacing.Md })
          .onChange((value: string) => {
            this.onTextChange(value);
          })
      }

      if (this.error !== '') {
        Text(this.error)
          .fontSize(FontSize.Caption)
          .fontColor(Colors.Error)
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }
}

/** 单选 chip：星期、节次、周次类型等短选项。 */
@ComponentV2
export struct SelectChip {
  /** V2 全局 Store（主题色）。 */
  @Local store: AppStore = AppStore.connect();
  @Param label: string = '';
  @Param selected: boolean = false;
  @Event onSelect: () => void = () => {
  };

  build() {
    Text(this.label)
      .fontSize(FontSize.BodySm)
      .fontColor(this.selected ? this.store.accentOn : Colors.TextSecondary)
      .backgroundColor(this.selected ? this.store.accentDisplay : Colors.SurfaceHigh)
      .borderRadius(Radius.Sm)
      .padding({
        left: Spacing.Md,
        right: Spacing.Md,
        top: Spacing.Xs + 2,
        bottom: Spacing.Xs + 2
      })
      .margin({ right: Spacing.Sm, bottom: Spacing.Sm })
      .onClick(() => {
        this.onSelect();
      })
  }
}

/** 颜色色块：色池里的颜色 + 选中态描边。 */
@ComponentV2
export struct ColorSwatch {
  @Param color: string = '';
  @Param selected: boolean = false;
  @Event onSelect: () => void = () => {
  };

  build() {
    Stack() {
      if (this.selected) {
        Text('✓')
          .fontSize(FontSize.BodySm)
          .fontWeight(FontWeight.Bold)
          .fontColor(CourseBlockColors.Text)
      }
    }
    .width(30)
    .height(30)
    .borderRadius(Radius.Round)
    .backgroundColor(this.color)
    .border({
      width: this.selected ? 3 : 1,
      color: this.selected ? Colors.TextPrimary : Colors.Outline
    })
    .margin({ right: Spacing.Sm, bottom: Spacing.Sm })
    .onClick(() => {
      this.onSelect();
    })
  }
}

/** 步进行：左侧说明 + 减 / 值 / 加。周次区间用。 */
@ComponentV2
export struct StepperRow {
  /** V2 全局 Store（主题色）。 */
  @Local store: AppStore = AppStore.connect();
  @Param label: string = '';
  @Param valueText: string = '';
  @Param canDecrease: boolean = true;
  @Param canIncrease: boolean = true;
  @Event onDecrease: () => void = () => {
  };
  @Event onIncrease: () => void = () => {
  };

  build() {
    Row({ space: Spacing.Sm }) {
      Text(this.label)
        .fontSize(FontSize.BodySm)
        .fontColor(Colors.TextSecondary)
        .layoutWeight(1)

      this.stepButton('−', this.canDecrease, () => {
        this.onDecrease();
      })

      Text(this.valueText)
        .fontSize(FontSize.Body)
        .fontColor(Colors.TextPrimary)
        .width(56)
        .textAlign(TextAlign.Center)

      this.stepButton('+', this.canIncrease, () => {
        this.onIncrease();
      })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  stepButton(symbol: string, enabled: boolean, action: () => void) {
    Text(symbol)
      .fontSize(FontSize.Title)
      .fontColor(enabled ? this.store.accentDisplay : Colors.TextTertiary)
      .width(32)
      .height(32)
      .textAlign(TextAlign.Center)
      .backgroundColor(Colors.SurfaceHigh)
      .borderRadius(Radius.Round)
      .opacity(enabled ? 1 : 0.5)
      .onClick(() => {
        if (enabled) {
          action();
        }
      })
  }
}
