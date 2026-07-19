# 礼小记 1.2 升级全量测试报告

> 测试日期：2026-07-12  
> 当前分支：`upgrade/product-audit-20260711`  
> 线上基线：`main`，即当前线上 App 版本  
> 测试目标：验证已上线版本数据升级到当前升级版本后的兼容性、功能完整性、产品体验关键路径和发布构建可用性。

## 1. 结论

本轮本地与真机测试结论：当前升级版本已通过自动化回归、旧版本数据升级、Release 升级链路、iPhone 14/iPad UI、产品关键路径、深色模式、大字号和 Archive 构建验证。按 2026-07-12 最终确认的范围，必测真机为 iPhone 14 和 iPad，iPhone 15 与压力测试均不再作为本次发布门槛。Production CloudKit、真实 Sandbox 交易与 TestFlight 处理完成状态仍未验收，因此当前结论是条件性通过，不能作为无条件上线批准。

关键结果：

| 项目 | 结果 |
|---|---:|
| 最终候选 build | `1.2 (2026071205)` |
| 全量 CI 测试 | 通过，`300/300`，失败 `0`，跳过 `0` |
| 必测真机矩阵 | iPhone 14 + iPad，均已完成最终候选全量回归 |
| iPadOS 17 最终候选全量 | `2026071205` 通过，`300/300`，失败 `0`，并复核 190 条历史数据 |
| iPhone 14 最终候选全量回归 | `2026071205` 通过，`300/300`，失败 `0`，跳过 `0` |
| iPhone 14 真机历史升级 | 通过，`185/185` 条记录完整保留并回填 |
| iPhone 14 候选增量升级 | `2026071202 -> 2026071204` 通过，核心数据计数一致，数据库完整性 `ok` |
| 旧版 Debug 中量数据升级 | 通过，升级前后核心数据计数一致 |
| 旧版 Release 真实 UI 小数据升级 | 通过，升级前后核心数据计数一致 |
| 数据库兼容迁移 / 回填 | 通过，新增表与关键字段回填正常 |
| 产品关键路径冒烟 | 通过，付费门槛、数据安全、截图路径已覆盖 |
| 深色模式 + 超大字号 | 通过 |
| Archive | 通过，`build/LiShangJi.xcarchive` 生成成功 |
| App Store Connect | `2026071205` 上传成功，进入 Processing；未提交审核、未发布 |
| 压力测试 | 经产品负责人确认从本次范围移除，不作为发布门槛 |
| iPhone 15 | 经产品负责人确认从必测矩阵移除，不要求最终 UI 复跑 |

当前仍不应声称已经完成的范围：

- 尚未完成 Production CloudKit 双设备与 1.0/1.2 混合版本同步。执行前仍需读取 Production Schema；当前浏览器自动化通道不可用，`cktool` 缺少 CloudKit Management Token。
- 尚未完成真实 StoreKit Sandbox 最终购买确认、冷启动权益、卸载重装恢复和服务端撤销场景。需要 TestFlight `2026071205` 处理完成并完成 iPhone 镜像的本机认证。
- TestFlight `2026071205` 已上传并进入 Processing，但尚未确认已经处理完成并可供测试。

范围说明：用户已明确移除 7 天浸泡测试及替代的 2 小时真机加速压力测试，也已将 iPhone 15 从必测设备矩阵移除。这两项不再计为未完成项，不影响本报告的条件性结论。

## 1.1 最终候选 `2026071205` 增量结果

本节记录初版报告之后继续执行的发布验证；后文保留此前证据路径。

| 检查 | 结果 |
|---|---|
| 最终模拟器 CI | `300/300`，失败 `0`，跳过 `0` |
| 最终 CI xcresult | `/tmp/lsj-upgrade-test/final-ci-2026071205-r3.xcresult` |
| 最终签名 Archive | `/tmp/lsj-upgrade-test/LiShangJi-2026071205.xcarchive` |
| TestFlight 上传 | `2026071205`：`Uploaded package is processing` / `Upload succeeded` |
| App Store 签名 | Cloud Managed Apple Distribution；`get-task-allow=false`；CloudKit `Production`；推送 `production` |
| Privacy Manifest | 已包含；不跟踪、不声明额外收集；`UserDefaults` Required Reason `CA92.1` |
| iPhone 14 最终候选全量回归 | `/tmp/lsj-upgrade-test/candidate-1205-iphone14-final-r2.xcresult`；`300/300`，失败 `0`，跳过 `0` |
| iPad 6 最终候选全量回归 | `/tmp/lsj-upgrade-test/candidate-1205-ipad-final.xcresult`；`300/300`，失败 `0`，跳过 `0` |
| App Store 本地导出 | `/tmp/lsj-upgrade-test/app-store-export-2026071205`；版本、签名、Production CloudKit 权限通过 |

iPhone 14 候选增量升级新增证据：

| 项目 | `2026071202` | `2026071204` |
|---|---:|---:|
| 记录 | 185 | 185 |
| 联系人 | 30 | 30 |
| 账本 | 6 | 6 |
| 事件模板 | 13 | 13 |
| 分类 | 13 | 13 |

- 升级前容器：`/tmp/lsj-upgrade-test/containers/iphone14-build1202-before-1204`。
- 升级后容器：`/tmp/lsj-upgrade-test/containers/iphone14-build1204-after-1202-upgrade`。
- `185/185` 记录的金额 minor、币种和联系人名称快照完整。
- `30/30` 联系人的标准化名称完整。
- 升级后数据库 `PRAGMA integrity_check` 返回 `ok`。
- 真机已核对实际安装版本为 `1.2 (2026071205)`。
- 最终容器：`/tmp/lsj-upgrade-test/containers/iphone14-build1205-final`；185 条记录及关键回填仍完整，数据库完整性 `ok`。
- iPad `1205` 回归前后容器分别为 `/tmp/lsj-upgrade-test/containers/ipad-before-1205-final` 和 `/tmp/lsj-upgrade-test/containers/ipad-after-1205-final`；190 条记录、30 个联系人、6 个账本、13 个事件模板和 13 个分类保持一致，关键字段完整，数据库完整性 `ok`。

真机升级新增证据：

| 项目 | 升级前 1.0 | 升级后 1.2 |
|---|---:|---:|
| 记录 | 190 | 190 |
| 联系人 | 30 | 30 |
| 账本 | 6 | 6 |
| 事件模板 | 13 | 13 |
| 分类 | 13 | 13 |

- 设备：iPad 6，iPadOS 17.7.11。
- 升级前容器：`/tmp/lsj-upgrade-test/containers/v1-ipad-before-upgrade`。
- 升级后容器：`/tmp/lsj-upgrade-test/containers/v2-ipad-after-upgrade`。
- 升级后完整 UI：`/tmp/lsj-upgrade-test/candidate-ipad-upgraded-data-ui.xcresult`，`24/24` 通过。
- `190/190` 记录的金额 minor、联系人名称、名称快照和联系人外键已回填。
- `30/30` 联系人的标准化名称和缓存计数已回填。
- 自动恢复点存在，恢复点内仍为旧 Schema 且保留 190 条记录。

本轮真机发现并修复：

1. iPad 竖屏自动收起侧栏且页面隐藏导航栏，导致账本/往来/我的不可达；改为显式全栏和平衡分栏，最终完整 UI 通过。
2. iPad 截图流程误把 `ToggleSidebar` 当返回按钮；测试改为语义定位，产品链路复测通过。
3. 关于页 build 固定为 `(1)`；改为从 Bundle 动态读取。
4. 清空数据文案与自动恢复点矛盾；统一说明本机恢复点、完整备份和 iCloud 删除传播风险。
5. OCR/语音缺少人工核对提示；已补充识别边界和帮助/更新说明。
6. Release 包缺少 Privacy Manifest；已补充并验证实际归档包含该文件。
7. GitHub Pages 的隐私、协议和支持页仍是旧权益与旧日期；本地页面源已同步到 1.2，部署前必须随代码提交发布。
8. StoreKit 交易监听原先会把退款/撤销更新错误视为新授权；现改为完成交易后重新读取当前权益，并显式拒绝撤销、过期和错误商品 ID。新增 5 条权益判定测试。
9. 真机横屏设置列表的整页滑动会跨过懒加载分区；测试改为绑定列表的小步拖动，并新增横屏下数据管理、导出和帮助入口可达性专项。

性能基线：

| 设备 | 冷启动平均值 |
|---|---:|
| iPhone 14 / iOS 26.5 | `0.191s` |
| iPhone 15 / iOS 26.5 | `0.178s` |
| iPad 6 / iPadOS 17.7.11 | `0.752s` |

iPhone 15 数据为范围调整前取得的补充基线，不属于最终必测设备矩阵，也不要求继续执行 UI 测试。

iPad 旧数据数据库由 1.0 的 `156KB` 增长到迁移后的 `208KB`，完整 UI 回归后仍为 `208KB`，未发现持续增长。

## 5.4 2026-07-19 iPhone 14 真机续测

本轮使用已安装的当前升级版本，在 iPhone 14（iOS 26.5.2，UDID `00008110-000A2D043C8A401E`）上继续验证 iCloud、付费入口和提醒入口。用户数据未执行清空、卸载或不可逆删除。

| 场景 | 结果 | 证据 / 说明 |
|---|---|---|
| iCloud 开启前页面 | 通过 | 页面显示本地模式；记录 `192`、联系人 `33`、账本 `7`，SQLite 基线完整 |
| 开启确认层 | 通过（产品） | 真机可见“开启 iCloud 同步”确认层；该层在 iOS 26 AX 树中不是 `Alert` 类型，原 `app.alerts` 断言属于测试定位错误 |
| 创建恢复点并开启 | 通过 | 真机可见“iCloud 配置”结果层，提示恢复点已创建、下次启动生效 |
| 重启后 iCloud 生效 | 通过 | 页面显示“iCloud 已开启”，状态图标为已同步状态，App 正常进入首页 |
| CloudKit 初次合并 | 发现高风险行为 | 重启后统计变为记录 `786`、联系人 `84`、账本 `17`；说明当前 CloudKit 容器存在本机基线之外的云端数据并已合并。需产品确认这是预期的跨设备合并，还是测试/历史数据污染；不能仅以“开关成功”作为上线结论 |
| 关闭 iCloud 配置 | 通过 | 真机可见“关闭 iCloud 同步”确认层和恢复点结果层 |
| 关闭后重启 | 通过 | 设置页显示“iCloud 同步 已关闭”，未出现数据恢复页；合并后的本机数据未自动删除 |
| OCR / 语音入口 | 部分通过 | 免费/未恢复权益状态可打开高级版说明页；非 Xcode 启动的真机包中 StoreKit 商品持续加载，未完成真实 Sandbox 购买，不能据此判定 OCR/语音主流程通过 |
| 提醒入口 | 部分通过 | 真机可打开提醒列表和新建事件表单，日期、全天开关和提醒设置区可见；本轮未完成未来时间通知送达和点击深链验收 |
| TestFlight 实际安装态 | 阻断 | TestFlight 显示 `1.2 (2026071701)`、剩余 90 天，但按钮仍为“安装”；覆盖开发签名包时系统提示“所请求的 App 不可用或者不存在”。当前手机实际运行的是开发签名包，不是 TestFlight 包 |
| StoreKit 商品加载 | 阻断 | 开发签名包的购买页持续显示“正在加载产品信息”；真实 Sandbox 交易必须在 TestFlight 包安装成功后执行，不能用本地 StoreKit 配置替代最终验收 |
| 通知系统权限 | 通过 | iOS 设置中“礼小记”已开启允许通知，锁屏、通知中心、横幅、声音和标记均开启 |
| 通知送达取证 | 未通过验收 | 创建真实事件后发现首次手工用例误触为 7 月 29 日，不能作为送达失败；随后 DEBUG 时间压缩触发未在观察窗口捕获到横幅或通知中心记录，调度是否进入系统仍需继续定位 |
| 通知点击路由代码 | 已修复、待真机复验 | 新增 `UNUserNotificationCenterDelegate`、前台横幅、点击事件广播、冷启动待处理 `eventID` 和事件详情 Sheet；模拟器构建与全量单元测试通过，真机点击闭环尚未取得通过证据 |
| OCR 网络图片引擎 | 通过（引擎层） | 从 QuickChart 下载公开 PNG，内容为“张三 1000、李四 2000、王五 888、赵六 666”；Apple Vision 实际识别出标题和 4 条记录，OCR 解析单元测试通过。相册权限、图片选择和保存仍待高级版权益解锁后真机完成 |
| 全量单元回归 | 通过 | `/tmp/lsj-unit-after-notification-r1.xcresult`，`LiShangJiTests` 全部通过 |

本轮补充的测试工程调整：iCloud UI 测试点击整行开关的右侧坐标，并在确认层缺失时保存完整 AX 树。CoreDevice 服务随后恢复，`xcrun devicectl` 已能识别 iPhone 14、构建、覆盖安装和启动开发包；TestFlight 商店签名包仍无法安装。

补充结果：Xcode 图形界面和命令行先后完成四次真机单项测试启动，但 XCTest 的 AX 树在初始化阶段始终没有出现 `首页` 或任一 Tab。iCloud 证据为 `/tmp/lsj-latest-icloud-result`，通知重跑证据为 `/tmp/lsj-device-notification-delivery-r1.xcresult`、`r2` 和 `r3`。同一安装包通过 iPhone 镜像和 `devicectl` 手工启动可正常显示首页。因此这些失败应归类为 XCTest 真机自动化/AX 会话不同步，不能作为 App 功能失败，也不能作为通知通过证据。

### 5.5 发布阻断项（续测后）

1. **CloudKit 数据边界未确认**：开启 iCloud 后出现 `192/33/7 -> 786/84/17` 的云端合并，必须在 Production 容器中核对数据来源、去重策略和首次开启提示。
2. **通知送达和点击路由未验收**：代码已补齐前台展示、点击与冷启动事件路由，但真机时间压缩触发未取得横幅/通知中心送达证据；后台、锁屏和点击详情仍不能标记通过。
3. **真实 Sandbox 购买未完成**：TestFlight 显示 `1.2 (2026071701)` 但安装时报“所请求的 App 不可用或者不存在”，当前开发签名包商品持续加载。需在备份后卸载开发包、安装 TestFlight 包，再验证购买、恢复、冷启动、重装恢复、撤销/过期。
4. **双设备 iCloud 同步未完成**：本轮只完成 iPhone 14 的开启、重启和云端合并观察，尚未用第二台真机验证新旧版本双向增删改同步及冲突策略。

## 2. 测试环境

| 项目 | 值 |
|---|---|
| macOS / 构建环境 | xcresult 记录：`Built with macOS 26.5.1` |
| Xcode | `Xcode 26.6 (17F113)` |
| iPhone 模拟器 | `iPhone 17 Pro`，iOS `26.5`，UDID `0F05696C-2CD1-439C-88E4-7753F3BD6834` |
| iPad 模拟器 | `iPad Pro 13-inch (M5)`，iOS `26.5`，UDID `358AFCBE-9C01-4461-9475-0135545F879C` |
| 升级中量数据模拟器 | `Jizhang Upgrade Medium`，iOS `26.5` |
| 必测真机 | `iPhone 14` / iOS `26.5`；`iPad (6th generation)` / iPadOS `17.7.11`；当前均为 `available (paired)` |

## 3. 全量 CI 与发布构建

执行命令：

```bash
DESTINATION="platform=iOS Simulator,id=0F05696C-2CD1-439C-88E4-7753F3BD6834" scripts/ci.sh
```

结果：

- 测试通过：`289/289`
- 失败：`0`
- 跳过：`0`
- 设备：`iPhone 17 Pro`，iOS `26.5`
- Archive：成功，日志包含 `** ARCHIVE SUCCEEDED **`

证据：

- CI 日志：`/tmp/lsj-upgrade-test/logs/v2-ci-after-real-device-fixes.log`
- 全量测试结果：`/Users/long/Library/Developer/Xcode/DerivedData/LiShangJi-epyeocievwdoykdmlmrylyhmykzg/Logs/Test/Test-LiShangJi-2026.07.12_12-18-50-+0800.xcresult`
- Archive 产物：`build/LiShangJi.xcarchive`

说明：xcresult 的设备维度 `passedTests=292`，顶层 `totalTestCount=289` / `passedTests=289`。差异来自动态参数测试统计方式，最终判定以顶层 `result=Passed` 和 `failedTests=0` 为准。

## 4. 旧版本数据升级验证

### 4.1 Debug 中量数据升级链路

验证目标：先用旧版 App 生成生产基线数据，再升级到当前版本，确认数据不丢失、迁移字段完整、UI 能在升级数据上正常运行。

旧版数据规模：

| 数据类型 | 数量 |
|---|---:|
| 礼金记录 | 187 |
| 联系人 | 30 |
| 账本 | 6 |
| 事件 | 13 |
| 分类 | 13 |

升级后验证：

| 验证点 | 结果 |
|---|---|
| 升级前后记录数 | 一致 |
| 升级前后联系人、账本、事件、分类数 | 一致 |
| 新表 `ZCONTACTALIAS` | 存在 |
| `ZGIFTRECORD.ZAMOUNTMINOR` | `187/187` 已回填 |
| `ZCONTACT.ZCACHEDRECORDCOUNT` | `30/30` 已回填 |
| 礼金记录联系人外键 | `187/187` 有有效联系人 FK |
| 升级后 UI 回归 | 通过，`21/21` |

证据：

- 升级后 UI xcresult：`/tmp/lsj-upgrade-test/dd-v2-ui-upgraded/Logs/Test/Test-LiShangJi-2026.07.12_10-16-14-+0800.xcresult`
- 测试摘要：`Passed`，总数 `21`，通过 `21`，失败 `0`，跳过 `0`

### 4.2 Release 真实 UI 小数据升级链路

验证目标：用旧版 Release App 通过真实 UI 创建数据，再升级到当前 Release 构建，验证线上用户最接近的升级路径。

旧版 Release 数据：

| 数据类型 | 数量 |
|---|---:|
| 礼金记录 | 2 |
| 联系人 | 2 |
| 账本 | 1 |
| 事件 | 13 |
| 分类 | 13 |

样例记录：

| 联系人 | 金额 | 方向 | 账本 |
|---|---:|---|---|
| Release张三 | 888.00 | 送出 | Release升级账本 |
| Release李四 | 600.00 | 收到 | Release升级账本 |

升级后验证：

| 验证点 | 结果 |
|---|---|
| 核心数据计数 | 升级前后一致 |
| 新表 `ZCONTACTALIAS` | 存在 |
| `ZAMOUNTMINOR` | `2/2` 已回填 |
| `ZCACHEDRECORDCOUNT` | `2/2` 已回填 |
| 联系人名称快照 | 已回填 |
| 金额 minor 单位 | `88800` / `60000` |

容器快照：

- 升级前：`/tmp/lsj-upgrade-test/containers/v1-release-before-upgrade/data`
- 升级后：`/tmp/lsj-upgrade-test/containers/v2-release-after-upgrade/data`

### 4.3 iPhone 14 真机历史数据升级链路

验证目标：在原本未安装礼小记的真实设备上，先安装 `main` 线上基线 `1.0`，生成旧结构数据，再直接覆盖安装当前 `1.2 Release`，验证真实 App 容器、签名安装和 SwiftData 迁移行为。

旧版真机数据：

| 数据类型 | 数量 |
|---|---:|
| 礼金记录 | 185 |
| 联系人 | 30 |
| 账本 | 6 |
| 事件 | 13 |
| 分类 | 13 |

升级后验证：

| 验证点 | 结果 |
|---|---|
| App 版本 | `1.0` 覆盖升级为 `1.2 Release` |
| 核心数据计数 | 全部与升级前一致 |
| `ZCONTACTALIAS` | 已创建 |
| `ZAMOUNTMINOR` | `185/185` 已回填 |
| `ZCONTACTNAME` | `185/185` 已回填 |
| `ZCONTACTNAMESNAPSHOT` | `185/185` 已回填 |
| 联系人外键 | `185/185` 有效，失效外键 `0` |
| 联系人缓存 / 标准化名称 | `30/30` 已回填 |
| 升级前恢复快照 | 已创建，快照内仍有 `185` 条原始记录 |
| 升级数据 UI 冒烟 | 启动、往来页、数据安全、产品主流程均通过 |

容器证据：

- 升级前：`/tmp/lsj-upgrade-test/containers/v1-real-iphone-before-fixed-upgrade`
- 升级后：`/tmp/lsj-upgrade-test/containers/v2-real-iphone-after-fixed-upgrade`
- 真机最终代码测试：`/tmp/lsj-upgrade-test/v2-real-iphone-unit-after-fixes.xcresult`
- 升级数据横屏 UI：`/tmp/lsj-upgrade-test/v2-real-iphone-upgraded-data-ui-final.xcresult`

真机验证发现并修复了两个跨环境问题：

1. 金额格式原先跟随设备地区的小数规则，`88.5` 在真机显示为 `¥88`。现已固定为 `zh_CN/CNY`，整数不补零，小数金额显示两位，并避免共享格式器并发修改。
2. 部分 v1 记录只有联系人关系、`contactName` 为空，原回填无法生成姓名快照。现已从关联联系人补齐旧姓名与快照，并在关系丢失时使用快照展示。

## 5. UI / 产品体验验证

### 5.1 iPhone 全量 UI 与功能覆盖

iPhone 回归已包含在全量 CI 中，覆盖核心路径：

- App 启动
- 首页展示
- Tab / 主要导航
- 账本入口和空状态
- 联系人入口
- 往来/互动入口
- 设置页信息、版本、关于、联系人管理、事件节日、导出数据
- 浮动新增入口
- 记账录入页取消、金额展示、方向选择
- 首页视觉快照
- 启动性能测试
- 会员付费门槛入口
- 数据安全页入口
- 产品展示/截图路径

### 5.2 iPad 最终 UI 回归

最终 iPad 回归结果：

- 结果：`Passed`
- 顶层总数：`24`
- 通过：`24`
- 失败：`0`
- 跳过：`0`
- 设备：`iPad Pro 13-inch (M5)`，iOS `26.5`

证据：

- `/tmp/lsj-upgrade-test/dd-v2-ui-ipad-final/Logs/Test/Test-LiShangJi-2026.07.12_11-29-28-+0800.xcresult`

说明：iPad 测试适配了两种导航形态：

- iPhone 底部 `TabView`
- iPad `NavigationSplitView` 侧边栏按钮

本轮 iPad 测试过程中曾出现一次 Simulator clone runner 启动失败：

- `FBSOpenApplicationServiceErrorDomain Code=1`
- `RequestDenied`
- 失败目标为 `com.xxl.LiShangJiUITests.xctrunner`

随后 Xcode 继续执行并最终 `** TEST SUCCEEDED **`。该现象属于 Xcode/Simulator runner 启动不稳定，不是 App 断言失败；最终 xcresult 中 `failedTests=0`。

### 5.3 iPhone 14 真机回归

最终真机结果：

- 最终候选 `2026071205` 全量测试：`300/300`，失败 `0`，跳过 `0`
- 代码 / 数据 / 迁移测试：`265/265`，失败 `0`
- 全量 UI / 产品测试：`24/24`，失败 `0`
- 冷启动性能：平均约 `0.195s`
- 升级数据专项 UI：启动、往来页、数据安全、产品主流程通过

证据：

- 最终候选全量测试：`/tmp/lsj-upgrade-test/candidate-1205-iphone14-final-r2.xcresult`
- 横屏关键设置专项：`/tmp/lsj-upgrade-test/candidate-1205-landscape-helper-final.xcresult`
- 代码测试：`/tmp/lsj-upgrade-test/v2-real-iphone-unit-after-fixes.xcresult`
- 全量 UI：`/tmp/lsj-upgrade-test/v2-real-iphone-ui-final.xcresult`
- 升级数据 UI：`/tmp/lsj-upgrade-test/v2-real-iphone-upgraded-data-ui-final.xcresult`

真机 UI Runner 首次出现两次 `Timed out while enabling automation mode`，清理残留 `xctrunner` 后最小用例和完整套件均通过。横屏时设置列表目标位于懒加载区域，测试已改为滚动定位并复测通过。

### 5.4 产品关键路径冒烟

新增并验证的产品测试：

| 用例 | 目标 |
|---|---|
| `testPremiumGateOpensPurchaseSheet` | 免费态下 OCR/高级能力入口能打开购买页 |
| `testDataSafetyEntryShowsBackupRestoreAndCSV` | 设置中的数据安全入口能展示备份、恢复、CSV 能力 |
| `testProductSurfaceSnapshotFlow` | 主要产品表面与截图路径可稳定打开 |

单项运行日志：

- 产品冒烟：`/tmp/lsj-upgrade-test/logs/v2-ui-product-smoke.log`，包含 `** TEST SUCCEEDED **`
- 深色模式 + 超大字号：`/tmp/lsj-upgrade-test/logs/v2-ui-dark-large.log`，包含 `** TEST SUCCEEDED **`

说明：这两个单项 run 的 xcresult test-results 摘要返回 `unknown/0`，因此不作为主统计来源；上述 3 个产品用例已经包含在全量 CI 和最终 iPad UI run 中，主证据使用全量 xcresult。

### 5.5 深色模式与动态字体

覆盖项：

- 深色模式
- `extra-extra-extra-large` 动态字体
- 产品截图路径

结果：通过，日志包含 `** TEST SUCCEEDED **`。

## 6. 历史版本兼容性结论

本轮重点围绕“当前 `main` 是线上版本”进行升级验证。已覆盖：

- 从线上基线数据升级到当前分支
- Debug 中量数据升级
- Release 真实 UI 小数据升级
- SwiftData schema 新增实体 / 新增字段后兼容打开
- 金额 minor 单位回填
- 联系人记录数缓存回填
- 联系人快照字段回填
- 联系人外键有效性
- 升级后 UI 自动化回归
- 真机 App 容器原地覆盖升级
- 升级前自动恢复快照
- 仅保存关系、姓名字段为空的 v1 数据形态

结论：在模拟器、iPhone 14 和 iPad 真机的当前测试数据规模下，没有发现数据丢失、迁移失败或升级后无法打开的问题。

## 7. 尚需发布前人工确认的项目

这些项目不是当前自动化失败，而是受环境或真实账号限制。对包含订阅和 iCloud 同步能力的正式线上版本，发布前仍须完成：

1. iCloud 双设备同步验证
   - 必须使用测试 Apple ID。
   - 验证新增、编辑、删除、离线恢复、冲突、关闭再开启同步。
   - 验证开启同步前备份是否可恢复。

2. StoreKit 沙盒交易验证
   - 本机 StoreKit CLI 不可用，本轮只验证购买页和付费门槛 UI。
   - 发布前需要在具备 StoreKit 工具或沙盒账号的环境中验证购买、恢复购买、失败重试、取消支付。

3. TestFlight 构建状态确认
   - 确认 `1.2 (2026071205)` 已结束 Processing，可在 TestFlight 安装。
   - 后续真实 Sandbox 与 Production CloudKit 验收只使用该最终候选，不使用 `2026071201` 至 `2026071204`。

4. App Store 审核素材核对
   - 确认截图、隐私说明、订阅/买断文案与 App 内实际功能一致。
   - 确认免费版限制提前说明，避免用户录入后才感知限制。

## 8. 已知非 App 缺陷日志

| 日志 | 判断 |
|---|---|
| `IDELaunchParametersSnapshot: no debugger version` | Xcode 调试器版本元数据警告，测试最终通过 |
| Simulator clone runner `RequestDenied` | 模拟器 runner 启动不稳定，最终重试后通过 |
| 真机 `Timed out while enabling automation mode` | 清理残留 UI Runner 后完整 `24/24` 通过 |
| 真机自动锁屏等待解锁 | 设备测试前置条件，不属于 App 失败 |
| 单项冒烟 xcresult `unknown/0` | 单项 run 摘要未展开，主统计以全量 CI / iPad xcresult 为准 |

## 9. 当前发布判断

从本地自动化、真机回归和真机升级链路看，当前版本已经具备进入 TestFlight / 内部验收的条件。

发布到线上前，仍需补齐以下外部能力验收：

1. 确认 TestFlight `1.2 (2026071205)` 已结束 Processing 并可安装。
2. StoreKit 沙盒购买 / 恢复购买闭环，确认真实交易状态能正确解锁会员，并覆盖冷启动、重装恢复及可执行的取消/待处理/撤销场景。
3. 完成测试 Apple ID 下的 Production CloudKit 双设备同步、1.0/1.2 混合版本同步、冲突、离线、删除传播和关闭再开启同步验收。

压力测试和 iPhone 15 最终 UI 测试已按产品负责人决定从本次发布门槛移除，不再要求执行。在上述三项外部能力完成前，不应给出无条件上线批准，也不应对外声称真实交易闭环或双设备实时同步已验收。
