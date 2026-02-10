# 礼尚记 (LiShangJi)

> 懂礼数，更懂你

礼尚记是一款面向中国用户的 iOS 人情往来记账 App，帮助用户记录和管理婚丧嫁娶、节日庆典等场合的礼金往来，解决"人情遗忘"和"回礼对账"问题。

## 功能特性

- **多账本管理** — 创建独立账本（如"我的婚礼"、"2026春节"），分类管理不同场合
- **极速录入** — 手动录入 / OCR 拍照识别 / 语音记账，多种方式快速记录
- **双向关系追踪** — 收到与送出双向记录，实时计算人情差额
- **统计分析** — 收支趋势图、关系分布、联系人排行等多维度统计
- **iCloud 同步** — 基于 CloudKit 的数据同步，多设备无缝切换
- **农历支持** — 内置农历算法，支持农历日期显示与转换
- **隐私保护** — FaceID/TouchID 应用锁 + 后台自动模糊
- **数据导出** — CSV 格式导出记录、联系人、统计数据

## 技术栈

| 技术 | 说明 |
|------|------|
| Swift / SwiftUI | 原生 iOS 开发 |
| SwiftData | 数据持久化 |
| CloudKit | iCloud 云同步 |
| Vision Framework | OCR 文字识别 |
| Speech Framework | 语音识别 |
| Swift Charts | 数据可视化 |
| StoreKit 2 | 应用内购买 |
| LocalAuthentication | 生物识别认证 |

## 项目结构

```
LiShangJi/
├── LiShangJi/                    # 主 App 源码
│   ├── App/                      # App 常量与配置
│   ├── Models/                   # 数据模型 (SwiftData)
│   │   └── Enums/                # 枚举类型
│   ├── Features/                 # 功能模块
│   │   ├── Home/                 # 首页仪表盘
│   │   ├── GiftBook/             # 账本管理
│   │   ├── Record/               # 记录录入
│   │   ├── Events/               # 事件与提醒
│   │   ├── Contacts/             # 联系人管理
│   │   ├── Statistics/           # 统计分析
│   │   ├── Settings/             # 设置
│   │   └── Premium/              # 高级版购买
│   ├── Services/                 # 业务服务层
│   ├── Repositories/             # 数据访问层
│   │   └── Protocols/            # 仓库协议
│   ├── Navigation/               # 导航与路由
│   └── Shared/                   # 共享组件
│       ├── Components/           # UI 组件库 (LSJCard, LSJButton, ...)
│       ├── Extensions/           # Swift 扩展
│       └── Utilities/            # 工具类
├── LiShangJiTests/               # 单元测试
└── LiShangJiUITests/             # UI 测试
```

## 构建要求

- Xcode 16+
- iOS 17.0+
- Swift 5.10+

## 构建方式

1. 克隆项目
2. 用 Xcode 打开 `LiShangJi/LiShangJi.xcodeproj`
3. 选择目标设备，点击运行

> 注：iCloud 同步功能需要配置有效的 Apple Developer 账户和 CloudKit 容器。

## 文档索引

| 文档 | 说明 |
|------|------|
| [需求文档](docs/礼尚记需求文档.md) | 市场调研、用户画像、产品需求说明 |
| [技术设计文档](docs/礼尚记技术设计文档.md) | 架构设计、数据模型、技术方案 |
| [UI/UX 设计文档](docs/礼尚记UI_UX设计文档.md) | 设计语言、页面规范、组件库 |

## 许可证

Private - All Rights Reserved
