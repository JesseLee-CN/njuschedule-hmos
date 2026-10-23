/**
 * 通用卡片容器：统一圆角、表面色、内边距。
 * 用法：AppCard({ contentPadding: Spacing.Lg }) { Column() { ... } }
 * 注意：属性名不能叫 padding（与定制组件基类方法冲突）。
 */
import { AppStore } from '../../app/AppStore';
import { Colors, Radius, Spacing } from '../design/Tokens';

@ComponentV2
export struct AppCard {
  @Param contentPadding: number = Spacing.Lg;
  @Param radius: number = Radius.Lg;
  @BuilderParam content: () => void;

  build() {
    Column() {
      this.content()
    }
    .width('100%')
    .padding(this.contentPadding)
    .backgroundColor(Colors.Surface)
    .borderRadius(this.radius)
    .border({ width: 1, color: Colors.OutlineLight })
  }
}
