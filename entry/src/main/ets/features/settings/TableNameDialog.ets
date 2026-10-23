/**
 * 课表命名弹窗（新建 / 重命名共用）。
 *
 * 状态管理 V2 下没有 `@CustomDialog`，改为普通 `@ComponentV2` 组件内容，
 * 由调用方（ManageTablesPage）通过 `promptAction.openCustomDialog` 打开/关闭。
 */
import { AppStore } from '../../app/AppStore';
import { Colors, FontSize, Radius, Spacing } from '../../common/design/Tokens';

@ComponentV2
export struct TableNameDialog {
  /** V2 全局 Store（主题色）。 */
  @Local store: AppStore = AppStore.connect();
  /** 弹窗标题，如「新建课表」。 */
  @Param title: string = '';
  /** 输入框初始值（重命名时为原名）。 */
  @Param initialName: string = '';
  /** 确认按钮文字。 */
  @Param confirmText: string = '确定';
  /** 确认回调（关闭由调用方负责）。 */
  @Event onSubmit: (name: string) => void = () => {
  };
  /** 取消/关闭回调。 */
  @Event onCancel: () => void = () => {
  };

  @Local name: string = '';

  aboutToAppear(): void {
    this.name = this.initialName;
  }

  private trimmedName(): string {
    return this.name.trim();
  }

  private submit(): void {
    const value: string = this.trimmedName();
    if (value === '') {
      return;
    }
    this.onSubmit(value);
  }

  build() {
    Column({ space: Spacing.Lg }) {
      Text(this.title)
        .fontSize(FontSize.Title)
        .fontWeight(FontWeight.Medium)
        .fontColor(Colors.TextPrimary)
        .width('100%')

      TextInput({ text: this.name, placeholder: '请输入课表名称' })
        .width('100%')
        .height(44)
        .maxLength(30)
        .fontSize(FontSize.Body)
        .fontColor(Colors.TextPrimary)
        .placeholderColor(Colors.TextTertiary)
        .backgroundColor(Colors.SurfaceHigh)
        .borderRadius(Radius.Md)
        .padding({ left: Spacing.Md, right: Spacing.Md })
        .onChange((value: string) => {
          this.name = value;
        })
        .onSubmit(() => {
          this.submit();
        })

      Row({ space: Spacing.Md }) {
        Button('取消', { type: ButtonType.Capsule })
          .layoutWeight(1)
          .height(40)
          .fontSize(FontSize.Body)
          .fontColor(Colors.TextPrimary)
          .backgroundColor(Colors.SurfaceHigh)
          .onClick(() => {
            this.onCancel();
          })

        Button(this.confirmText, { type: ButtonType.Capsule })
          .layoutWeight(1)
          .height(40)
          .fontSize(FontSize.Body)
          .fontColor(this.trimmedName() === '' ? Colors.TextTertiary : this.store.accentOn)
          .backgroundColor(this.trimmedName() === '' ? Colors.SurfaceHigh : this.store.accentDisplay)
          .enabled(this.trimmedName() !== '')
          .onClick(() => {
            this.submit();
          })
      }
      .width('100%')
    }
    .width('86%')
    .constraintSize({ maxWidth: 420 })
    .padding(Spacing.Xl)
    .backgroundColor(Colors.Dialog)
    .borderRadius(Radius.Xl)
  }
}
