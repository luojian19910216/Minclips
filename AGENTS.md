# Minclips — Agent 速览

面向新开 Cursor Agent：详细约定在 **`.cursor/rules/*.mdc`**（会自动按范围注入），此处为摘要。

| 主题 | 要点 |
|------|------|
| 主导航 | `MCCNavigationController` → `MCCTabBarController`；tab 内不再嵌多套 nav |
| **命名** | **`mcvc_`** = 控制器自有 + 子页对外字段；**`mcvw_`** = View/Cell/Pop 自有；**`contentView.mcvw_…`**；模块靠类型名区分（详见 `minclips-always.mdc`） |
| 控制器 | 用 `mcvc_*` 生命周期钩子；初始化以 `mcvc_*` 钩子为准 |
| 视图 | `MCCBaseView`：`mcvw_setupUI` / `mcvw_bind`；`MCCViewController` ↔ `contentView` |
| 弹窗 | **底部进入** → `MCCSheetController` + PanModal + `MCCBaseView`；**其他** → `MCCPopController` + `MCCBasePopView` |
| 网络图 | `sd_setImage` 加载 URL 用 **`SDAnimatedImageView`**；纯本地/SF Symbol 用 `UIImageView` |
| 风格 | 新代码避免中文注释与 `// MARK:` |

修改 app 逻辑时以 `Minclips/` 下源码为准；`Pods_Local` 为本地 Pod，改动需与现有模块风格一致。
