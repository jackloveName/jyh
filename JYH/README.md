# 金瀛花 iOS

金瀛花是基于 SwiftUI 的资金周转 App。UI 对应 Figma 画板
`V79nSgi1Dtw9mwL4W87Ail / APP-UI / node 1315-10445`，接口协议取自
`/Users/kk/Documents/project3/金隆智融`。页面视觉重建自 Figma，未复用
金隆智融项目的 UI 风格；Figma 导出的 4x UI 图保存在 `DesignAssets/`。
登录、首页、我的三个页面均按 Figma
`终稿 Ready for dev` 的 390pt 画板重新实现，运行时图标与插画从对应
Figma 页面区域切片后存入 `JYH/Assets.xcassets`。

Figma 文案中的演示品牌“好享花”已按产品要求替换为“金瀛花”，其余文字、
字号层级、卡片边界、主色、页面间距和滚动结构均以 Figma 为准。

## 已接入接口

临时环境地址：

- API：`https://gateway.tianyuankeji.top`
- OSS：`https://mizhenhl.oss-cn-beijing.aliyuncs.com`
- H5 兜底地址：`https://jyh-h5.tianyuankeji.top`

应用名称、登录使用的 `appBrand`/`tempUid`、API 与 OSS 地址统一维护在
`JYH/AppConfig.swift`。启动时会请求
`/mall_admin/ua/app/sys_config/get/value/config/金瀛花`，解析其中二次编码的
`data` JSON，并将 `h5DownloadUrl` 写入全局 `AppStore` 和本地缓存。

配置接口可从 `h5Routes` 对象下发 H5 二级路径；客户端会规范化路径并缓存，
接口未返回该对象或缺少某个字段时自动使用本地默认值：

`h5DownloadUrl` 始终从现有配置的顶层字段读取，不属于也不要求包含在
`h5Routes` 对象中。以后服务器只新增 `h5Routes` 即可。

```json
{
  "h5DownloadUrl": "https://example.com",
  "h5Routes": {
    "identityCard": "/idCard",
    "certificationResult": "/certificationResult",
    "profileInformation": "/info",
    "status": "/status",
    "borrow": "/borrow",
    "loanApplication": "/loan",
    "loanResult": "/loan/result",
    "bill": "/bill",
    "billDetail": "/bill/detail"
  }
}
```

H5 路由由 `JYH/H5Routing.swift` 统一生成。客户端上下文字段与
`/Users/kk/Developer/hlgIOS` 保持一致：先移除已有的同名参数，再依次附加
`token`、`appName=金瀛花`、`statusHeight=0`。

- 身份证和人脸：`#/idCard`（现有 H5 从同一入口推进两个认证步骤）
- 填写信息：`#/info`
- 账单：`#/bill`
- 单期账单详情：`#/bill/detail?period=N`
- 借款申请与方案选择：`#/loan`
- 审核结果：`#/loan/result`

iOS 不再提供原生实名、人脸和资料录入页面。身份证、人脸及资料步骤统一由 H5
流程承接，宿主只负责读取认证进度并打开对应路由。

- `POST /mall_auth/ua/login`：密码登录，密码使用原项目相同的 AES-ECB 规则加密。
- `POST /mall_auth/ua/login_with_code`：短信验证码登录。
- `PUT /mall_biz/ua/sms/verification_code/login_code`：发送登录验证码。
- `PUT /mall_biz/ua/sms/verification_code/check_update_pwd`：校验修改密码验证码。
- `PUT /mall_auth/ua/forget_password`：设置新密码。
- `GET /mall_biz/ua/oss/get_batch_pre_sign_url`：获取头像 OSS 上传地址。
- `PUT /mall_user/user/set_user_info`：更新用户头像。
- `GET /mall_user/user/ma/user_detail_info`：用户资料与借款标识。
- `POST /mall-connect/goods/list`：借款产品与额度。
- `POST /mall-connect/goods/waitRepayCount`：待还数量。
- `GET /mall-connect/kyc/enterDataSortList`：实名认证步骤。
- `GET /mall_user/user_extension/get_info`：通联会员认证状态。
- `POST /mall_payment/allinpay/member/set_real_name`：实名认证。
- `GET /mall_payment/allinpay/member/query_bank_card`：银行卡列表。
- `POST /mall_payment/allinpay/member/apply_bind_bank_card`：绑定银行卡。
- `PUT /mall_payment/allinpay/member/unbind_bank_card`：解绑银行卡。

借款选择、借款确认、审核结果和还款账单均由 `/Users/kk/Developer/db`
中的金瀛花独立路由承接，通过 App 登录令牌衔接认证和还款流程。

当前无正式账单接口时，宿主与 H5 使用同一组高保真业务参数展示完整流程：
放款本金 7,600 元、12 期、年化综合融资成本（IRR）24%、等额本息，月供
710.24 元，末期 710.25 元，总利息 922.89 元，总还款 8,522.89 元。
首期从当前月份前五个月开始，前 4 期显示“已还款”，第 5 期显示“待还款”，
后续各期显示“未到期”；每期均可进入账单详情查看本金、利息及状态。

登录与 H5 跳转诊断日志统一使用 `[JYH]` 前缀，在 Xcode 控制台筛选
`[JYH]` 即可看到：

- 登录前、登录成功后的 `selectedTab`
- 当前使用的 `h5DownloadUrl` 和 `h5Routes`
- 点击“我的账单”后生成的 URL（token 已脱敏）
- WebView 初始地址、最终地址、标题、页面文本摘要
- H5 `authExpired`、关闭及其他 bridge 事件

也可以从终端持续查看：

```bash
xcrun simctl spawn booted log stream --style compact \
  --predicate 'eventMessage CONTAINS "[JYH]"'
```

## 构建

```bash
xcodebuild \
  -project JYH.xcodeproj \
  -scheme JYH \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  build
```

已分别在 iPhone 17 Pro（iOS 26）和 iPhone 18 Pro（iOS 27）模拟器完成
冷启动验证。首次启动会先显示蓝色“金瀛花”启动画面，随后进入登录页，
未再出现持续白屏。

登录页不提供游客页面浏览入口，使用借款服务前需要完成登录。

首页会根据 `/mall-connect/kyc/enterDataSortList` 的 `collectType` 与
`authenticationStatus` 判断当前步骤，包括继续人脸识别、完善资料和进入借款申请；
App 回到前台或 H5 关闭后会重新读取接口，避免依赖单一的实名状态字段。

## 合规文案

- 登录页默认不勾选协议，并提供《用户协议》《隐私政策》入口。
- 金融相关展示统一使用“额度参考”“以实际审批为准”“年化利率及费用以借款协议为准”等表述。
- 移除“限时领好礼”“快速审批”“安全合规”“首借利率低至”等绝对化或营销承诺。
- 实名认证、银行卡和还款页面明确说明信息用途及逾期风险。
- 合作机构统一展示为“贵阳市云岩区和泰小额贷款有限公司”，页面底部的服务主体盾牌使用 `ProviderShieldIcon`；资源为从 Figma 4× 原图
  精确切出的透明盾牌，主色 `#086CF5`，避免各页面重复使用错误裁切。
- 已加入 `PrivacyInfo.xcprivacy`，声明 UserDefaults 的 Required Reason API 用途。
- “我的”页设置入口提供用户协议、隐私政策、退出登录和账号注销；账号注销调用
  原项目 `/mall_user/user/destroy_user` 接口。

正式提交 App Store 前，仍需由运营主体确认应用名称、App Store 备案信息、隐私
申报、合作机构资质编号、贷款产品年化利率区间和协议最终版本。
