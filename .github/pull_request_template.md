## 改动说明

<!-- 说明目的、影响范围与实现思路 -->

## 验证

- [ ] `devecocli build`
- [ ] `devecocli check arkts $(find entry/src/main/ets -name '*.ets' | tr '\n' ' ')`
- [ ] `devecocli check lint`
- [ ] 真机验证（涉及 UI / 导入 / 分享 / 卡片时）

## AI 辅助说明

- [ ] 本次改动未使用 AI 辅助
- [ ] 使用了 AI 辅助，模型：`__________`
- [ ] 我已逐行理解并检查所有改动，能够解释每处修改的原因

## 检查清单

- [ ] 未包含签名材料、证书、口令、设备序列号、真实课表/账号等敏感信息
- [ ] UI / 状态管理仅使用 V2，未新增 V1 装饰器
- [ ] 未新增权限、第三方 SDK、依赖或数据 schema（如有，已在 Issue 中讨论）
- [ ] 改动用户协议/隐私政策时已同步 docs 与 `PRIVACY_VERSION`
- [ ] 新增开源依赖时已同步 `ThirdPartyLicenseData.ets` / `NOTICE`

## 截图（可选，请使用 Demo 数据）
