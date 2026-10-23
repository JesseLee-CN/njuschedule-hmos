/**
 * 课表背景图：移植旧版 `ConfigState` 的 `bgImgPath` + 设置页的「背景图」能力。
 *
 * HarmonyOS 侧用系统图库选择器（`photoAccessHelper.PhotoViewPicker`，无需申请读相册权限）
 * 选图后把文件复制进应用沙箱（临时 URI 不能长期使用），路径存 prefs `bgImgPath`，
 * 课表页按路径加载 PixelMap 作为背景。
 */
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { image } from '@kit.ImageKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { AppContext } from '../app/AppContext';
import { AppPreferences, PrefKeys } from '../app/AppPreferences';
import { AppState } from '../app/AppState';

export class BackgroundImage {
  /** 内置背景（rawfile/backgrounds），无需相册权限即可切换。 */
  static readonly PRESETS: string[] = ['bg_mist.png', 'bg_sunset.png', 'bg_forest.png'];

  private static readonly PRESET_PREFIX: string = 'bg_builtin_';

  static presetLabel(name: string): string {
    if (name === 'bg_mist.png') {
      return '晨雾';
    }
    if (name === 'bg_sunset.png') {
      return '晚霞';
    }
    if (name === 'bg_forest.png') {
      return '森林';
    }
    return name;
  }

  /** 当前选中的内置背景（非内置返回空串）。 */
  static currentPreset(): string {
    const path: string = BackgroundImage.currentPath();
    const index: number = path.lastIndexOf(BackgroundImage.PRESET_PREFIX);
    if (index < 0) {
      return '';
    }
    return path.substring(index + BackgroundImage.PRESET_PREFIX.length);
  }

  /** 把内置背景复制到沙箱并设为当前背景。 */
  static async applyPreset(name: string): Promise<void> {
    const context = AppContext.get();
    const content: Uint8Array = await context.resourceManager.getRawFileContent(`backgrounds/${name}`);
    const dest: string = `${context.filesDir}/${BackgroundImage.PRESET_PREFIX}${name}`;
    const file: fs.File = fs.openSync(dest, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
    try {
      const buffer: ArrayBuffer = content.buffer.slice(
        content.byteOffset, content.byteOffset + content.byteLength) as ArrayBuffer;
      fs.writeSync(file.fd, buffer);
    } finally {
      fs.closeSync(file);
    }
    await AppPreferences.put(PrefKeys.BgImgPath, dest);
    AppState.setBackgroundImagePath(dest);
  }

  /** 唤起系统图库选择背景图；返回是否成功设置。 */
  static async pick(): Promise<boolean> {
    const picker: photoAccessHelper.PhotoViewPicker = new photoAccessHelper.PhotoViewPicker();
    const options: photoAccessHelper.PhotoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
    options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    options.maxSelectNumber = 1;
    const result: photoAccessHelper.PhotoSelectResult = await picker.select(options);
    if (result.photoUris.length === 0) {
      return false;
    }
    const uri: string = result.photoUris[0];
    const dest: string = `${AppContext.get().filesDir}/bg_image_${Date.now()}${BackgroundImage.extensionOf(uri)}`;
    const srcFile: fs.File = fs.openSync(uri, fs.OpenMode.READ_ONLY);
    try {
      fs.copyFileSync(srcFile.fd, dest);
    } finally {
      fs.closeSync(srcFile);
    }
    await AppPreferences.put(PrefKeys.BgImgPath, dest);
    AppState.setBackgroundImagePath(dest);
    return true;
  }

  /** 移除背景图：删文件、清 prefs 与 AppStore 状态。 */
  static async clear(): Promise<void> {
    const current: string = BackgroundImage.currentPath();
    if (current !== '') {
      try {
        fs.unlinkSync(current);
      } catch (err) {
        console.warn(`[BackgroundImage] unlink failed: ${JSON.stringify(err)}`);
      }
    }
    await AppPreferences.put(PrefKeys.BgImgPath, '');
    AppState.setBackgroundImagePath('');
  }

  /** 启动时恢复：prefs 里有路径且文件还在才生效。 */
  static async restore(): Promise<void> {
    let path: string = '';
    try {
      path = await AppPreferences.getString(PrefKeys.BgImgPath, '');
    } catch (err) {
      path = '';
    }
    if (path !== '' && !BackgroundImage.exists(path)) {
      path = '';
    }
    AppState.setBackgroundImagePath(path);
  }

  static currentPath(): string {
    return AppState.store().backgroundImagePath;
  }

  /** 按路径解码成受控尺寸的 PixelMap（避免整图进内存）。 */
  static async loadPixelMap(path: string): Promise<image.PixelMap | undefined> {
    if (path === '' || !BackgroundImage.exists(path)) {
      return undefined;
    }
    try {
      const source: image.ImageSource = image.createImageSource(path);
      const options: image.DecodingOptions = {
        desiredSize: { width: 1080, height: 1800 }
      };
      const pixelMap: image.PixelMap = await source.createPixelMap(options);
      await source.release();
      return pixelMap;
    } catch (err) {
      console.error(`[BackgroundImage] decode failed: ${JSON.stringify(err)}`);
      return undefined;
    }
  }

  private static exists(path: string): boolean {
    try {
      return fs.accessSync(path);
    } catch (err) {
      return false;
    }
  }

  private static extensionOf(uri: string): string {
    const questionIndex: number = uri.indexOf('?');
    const clean: string = questionIndex >= 0 ? uri.substring(0, questionIndex) : uri;
    const dotIndex: number = clean.lastIndexOf('.');
    if (dotIndex < 0) {
      return '.jpg';
    }
    const ext: string = clean.substring(dotIndex);
    return ext.length <= 5 ? ext : '.jpg';
  }
}
