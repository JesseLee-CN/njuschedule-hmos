/**
 * 导入模块内部的路由参数。
 *
 * 只放 features/import 自己用的参数类（入口页 `import` 的 `ImportParam` 在
 * `common/RouteParams.ets`，属于外壳约定，不在这里重复定义）。
 *
 * NavPathStack 的参数必须是 Object，ArkTS 不允许把对象字面量直接传给 Object
 * 形参，因此用带构造器的类。
 */
import { SchoolConfig } from './SchoolConfig';

/** 路由名 `import-web`：带着学校配置进入 WebView 导入页。 */
export class ImportWebParam {
  config: SchoolConfig = new SchoolConfig();

  constructor(config: SchoolConfig) {
    this.config = config;
  }
}
