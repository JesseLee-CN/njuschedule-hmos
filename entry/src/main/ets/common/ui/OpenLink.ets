/**
 * 用系统默认方式打开链接（UIAbilityContext.openLink，API 12+）。
 *
 * 用于「关于/致谢/第三方许可证」等外链条目：点击直接跳转浏览器（或系统处理该 scheme 的应用），
 * 不再复制到剪贴板；链接为空或打开失败时给 Toast 提示。
 */
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { UIContext } from '@kit.ArkUI';
import { Feedback } from './Feedback';

export function openUrl(ctx: UIContext, url: string, emptyHint: string = '链接尚未提供'): void {
  if (url === '') {
    Feedback.toast(ctx, emptyHint);
    return;
  }
  const host: common.Context | undefined = ctx.getHostContext();
  if (host === undefined) {
    Feedback.toast(ctx, '无法打开链接');
    return;
  }
  try {
    (host as common.UIAbilityContext).openLink(url).catch((err: BusinessError) => {
      console.warn(`[OpenLink] open failed: ${JSON.stringify(err)}`);
      Feedback.toast(ctx, '无法打开链接');
    });
  } catch (err) {
    console.warn(`[OpenLink] open exception: ${JSON.stringify(err)}`);
    Feedback.toast(ctx, '无法打开链接');
  }
}
