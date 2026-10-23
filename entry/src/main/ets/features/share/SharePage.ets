/**
 * 分享课表：把当前课表编码成旧版分享码（`ncs://qr/v2/...`）并生成二维码。
 *
 * 编解码格式见 `data/ShareCodec.ets`，与旧 Flutter 项目
 * `lib/Pages/Share/qr_payload_codec.dart` 完全一致，保证跨端可扫。
 */
import { HdsNavDestination } from '@kit.UIDesignKit';
import { generateBarcode, scanCore } from '@kit.ScanKit';
import { image } from '@kit.ImageKit';
import { pasteboard } from '@kit.BasicServicesKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Colors, FontSize, HdsMetrics, Radius, Spacing } from '../../common/design/Tokens';
import { Feedback } from '../../common/ui/Feedback';
import { AppStore } from '../../app/AppStore';
import { hdsSubPageTitleBar } from '../../common/ui/HdsSubPage';
import { ShareCodec, ShareCodeStats } from '../../data/ShareCodec';
import { CourseRepository } from '../../data/CourseRepository';
import { CourseTableRepository } from '../../data/CourseTableRepository';
import { CourseTable, Course } from '../../data/models/Models';

@ComponentV2
export struct SharePage {
  /** V2 全局 Store（主题色 / 避让区 / 当前课表）。 */
  @Local store: AppStore = AppStore.connect();
  /** 滚动控制器（与 HdsNavDestination 绑定，获得标题栏动态模糊）。 */
  private subScroller: Scroller = new Scroller();


  @Local tableName: string = '';
  @Local courseCount: number = 0;
  @Local code: string = '';
  @Local stats: ShareCodeStats = new ShareCodeStats();
  @Local pixelMap: image.PixelMap | undefined = undefined;
  /** 二维码帧（Scan Kit 单张上限 512 字符，超长分享码需多张）。 */
  @Local qrFrames: string[] = [];
  @Local qrIndex: number = 0;
  @Local busy: boolean = true;
  @Local errorText: string = '';

  aboutToAppear(): void {
    this.load();
  }

  private async load(): Promise<void> {
    this.busy = true;
    this.errorText = '';
    this.pixelMap = undefined;
    try {
      const table: CourseTable | null = await CourseTableRepository.getById(this.store.tableId);
      if (table === null) {
        this.errorText = '当前课表不存在';
        return;
      }
      this.tableName = table.name;
      const courses: Course[] = await CourseRepository.getAll(this.store.tableId);
      this.courseCount = courses.length;
      const stats: ShareCodeStats = await ShareCodec.encode(table.name, table.data, courses);
      this.stats = stats;
      this.code = stats.code;
      this.qrFrames = ShareCodec.splitQrFrames(stats.code);
      this.qrIndex = 0;
      await this.renderQr(this.qrFrames.length > 0 ? this.qrFrames[0] : stats.code);
    } catch (err) {
      const message: string = err instanceof Error ? err.message : '未知错误';
      this.errorText = `生成分享码失败：${message}`;
    } finally {
      this.busy = false;
    }
  }

  private async renderQr(content: string): Promise<void> {
    const options: generateBarcode.CreateOptions = {
      scanType: scanCore.ScanType.QR_CODE,
      width: 720,
      height: 720
    };
    try {
      this.pixelMap = await generateBarcode.createBarcode(content, options);
    } catch (err) {
      // 模拟器不支持 Scan Kit 码图生成，真机可用；分享码本身仍可复制使用。
      const error: BusinessError = err as BusinessError;
      console.warn(`[Share] barcode generation unavailable: ${error.code} ${error.message}`);
    }
  }

  /** 切换二维码帧（多帧分享码）。 */
  private async gotoFrame(next: boolean): Promise<void> {
    const total: number = this.qrFrames.length;
    if (total <= 1) {
      return;
    }
    const index: number = (this.qrIndex + (next ? 1 : total - 1)) % total;
    this.qrIndex = index;
    this.pixelMap = undefined;
    await this.renderQr(this.qrFrames[index]);
  }

  private async copyCode(): Promise<void> {
    if (this.code === '') {
      return;
    }
    try {
      const data: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.code);
      await pasteboard.getSystemPasteboard().setData(data);
      Feedback.toast(this.getUIContext(), '分享码已复制到剪贴板');
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      console.error(`[Share] copy failed: code=${error.code} message=${error.message}`);
      Feedback.toast(this.getUIContext(), '复制失败');
    }
  }


  @Builder
  private qrCard() {
    Column({ space: Spacing.Md }) {
      if (this.busy) {
        LoadingProgress()
          .width(36)
          .height(36)
          .color(this.store.accentDisplay)
          .margin({ top: Spacing.Xxl, bottom: Spacing.Xxl })
      } else if (this.pixelMap !== undefined) {
        Image(this.pixelMap)
          .width(260)
          .height(260)
          .objectFit(ImageFit.Contain)
          .borderRadius(Radius.Md)
          .backgroundColor('#FFFFFF')
          .onClick(() => {
            this.gotoFrame(true);
          })

        if (this.qrFrames.length > 1) {
          Row({ space: Spacing.Md }) {
            Button('上一张')
              .height(32)
              .fontSize(FontSize.Caption)
              .backgroundColor(Colors.SurfaceHigh)
              .fontColor(Colors.TextPrimary)
              .onClick(() => {
                this.gotoFrame(false);
              })
            Text(`第 ${this.qrIndex + 1} / ${this.qrFrames.length} 张 · 点击二维码可切换`)
              .fontSize(FontSize.Caption)
              .fontColor(Colors.TextSecondary)
            Button('下一张')
              .height(32)
              .fontSize(FontSize.Caption)
              .backgroundColor(Colors.SurfaceHigh)
              .fontColor(Colors.TextPrimary)
              .onClick(() => {
                this.gotoFrame(true);
              })
          }
          Text('分享码较长，已拆成多张二维码：请用对方「扫码导入」依次扫描全部二维码，收齐后会自动导入。')
            .fontSize(FontSize.Caption)
            .fontColor(Colors.TextTertiary)
            .textAlign(TextAlign.Center)
            .lineHeight(18)
        }
      } else {
        Column({ space: Spacing.Sm }) {
          SymbolGlyph($r('sys.symbol.qrcode'))
            .fontSize(48)
            .fontColor([Colors.TextTertiary])
          Text('二维码生成失败')
            .fontSize(FontSize.BodySm)
            .fontColor(Colors.TextTertiary)
          Text('可以复制分享码，发给使用呢喃课表或旧版南哪课表的同学导入')
            .fontSize(FontSize.Caption)
            .fontColor(Colors.TextTertiary)
            .textAlign(TextAlign.Center)
        }
        .padding({ top: Spacing.Xxl, bottom: Spacing.Xxl })
      }

      Text(this.tableName)
        .fontSize(FontSize.Title)
        .fontWeight(FontWeight.Medium)
        .fontColor(Colors.TextPrimary)
      Text(`${this.courseCount} 门课程 · 分享码 ${this.stats.base64Chars} 字符`)
        .fontSize(FontSize.BodySm)
        .fontColor(Colors.TextTertiary)

      if (this.errorText !== '') {
        Text(this.errorText)
          .fontSize(FontSize.Caption)
          .fontColor(Colors.Error)
          .textAlign(TextAlign.Center)
      }
    }
    .width('100%')
    .padding(Spacing.Xl)
    .backgroundColor(Colors.Surface)
    .borderRadius(Radius.Lg)
    .border({ width: 1, color: Colors.OutlineLight })
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    HdsNavDestination() {
      Column() {
      Scroll(this.subScroller) {
        Column({ space: Spacing.Lg }) {
          this.qrCard()

          Column({ space: Spacing.Sm }) {
            Button('复制分享码')
              .width('100%')
              .height(44)
              .fontSize(FontSize.Body)
              .backgroundColor(this.store.accentDisplay)
              .fontColor(this.store.accentOn)
              .enabled(!this.busy && this.code !== '')
              .onClick(() => {
                this.copyCode();
              })
            Button('重新生成')
              .width('100%')
              .height(44)
              .fontSize(FontSize.Body)
              .backgroundColor(Colors.SurfaceHigh)
              .fontColor(Colors.TextPrimary)
              .enabled(!this.busy)
              .onClick(() => {
                this.load();
              })
          }
        }
        .width('100%')
        .padding({
          left: Spacing.Lg,
          right: Spacing.Lg,
          top: HdsMetrics.contentTopInset(px2vp(this.store.windowTopInset)) + Spacing.Md,
          bottom: Spacing.Xxl
        })
      }
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
      .align(Alignment.TopStart)
      .layoutWeight(1)
      .width('100%')
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Colors.Background)
    }
    .titleBar(hdsSubPageTitleBar('分享课表', '二维码 / 分享码与旧版南哪课表互通'))
    .bindToScrollable([this.subScroller])
  }
}
