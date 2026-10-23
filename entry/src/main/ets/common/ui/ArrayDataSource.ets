/**
 * 通用数组数据源：给 List/Grid/Swiper 的 LazyForEach 用（按需构建 + 数据变化整体重载）。
 *
 * 用法：
 *   private source: ArrayDataSource<Item> = new ArrayDataSource<Item>();
 *   // 数据更新时：this.source.setData(this.items);
 *   List() { LazyForEach(this.source, (item: Item) => { ListItem() {...} }, (item: Item) => key) }
 *
 * 说明：只实现「整体重载」；本项目的列表都是整批数据替换（刷新/翻页 concat），
 * 不需要逐条 add/change 通知，保持实现最小。
 */
export class ArrayDataSource<T> implements IDataSource {
  private data: T[];
  private listeners: DataChangeListener[] = [];

  constructor(data: T[] = []) {
    this.data = data;
  }

  totalCount(): number {
    return this.data.length;
  }

  getData(index: number): T {
    return this.data[index];
  }

  /** 整体替换数据并通知 LazyForEach 重新渲染。 */
  setData(data: T[]): void {
    this.data = data;
    for (let i = 0; i < this.listeners.length; i++) {
      this.listeners[i].onDataReloaded();
    }
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos: number = this.listeners.indexOf(listener);
    if (pos >= 0) {
      this.listeners.splice(pos, 1);
    }
  }
}
