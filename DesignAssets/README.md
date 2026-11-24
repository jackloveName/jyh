# 金瀛花 Figma UI 交付图

本目录只保存从 Figma `APP UI / 终稿 Ready for dev` 导出的 4x UI 图，
不再引用金隆智融项目的页面视觉资源。

| 文件 | Figma 画板 |
| --- | --- |
| `figma-login@4x.png` | 登录，390×844 |
| `figma-home@4x.png` | 首页，390×1108 |
| `figma-profile@4x.png` | 我的，390×844 |
| `figma-repayment@4x.png` | 还款，390×900 |
| `figma-verification@4x.png` | 实名认证，390×844 |
| `figma-bank-card@4x.png` | 绑定银行卡，390×1085 |

`figma-login-coin@4x.png` 是从 Figma 组件
`HXH / Asset / Login / 金融钱币` 内部导出的透明登录钱币切图，App 运行时
位于 `JYH/Assets.xcassets/login-coin.imageset`。

其余运行时图标与插画均按上述 Figma 终稿页面的实际位置切片，保存在
`JYH/Assets.xcassets`。`tools/crop_figma_assets.py` 可重新生成这些资源。
界面不使用整页截图作为背景，文字、输入框、按钮和滚动均保持可交互。
