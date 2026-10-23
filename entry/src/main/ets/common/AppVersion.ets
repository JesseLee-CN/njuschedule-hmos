/** 读取应用版本号（读不到时返回 fallback）。关于页/许可证页共用。 */
import { bundleManager } from '@kit.AbilityKit';

export async function readVersionName(fallback: string): Promise<string> {
  try {
    const info: bundleManager.BundleInfo =
      await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT);
    return info.versionName.length > 0 ? info.versionName : fallback;
  } catch (err) {
    return fallback;
  }
}
