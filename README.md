# PackageViewer

一个简洁优雅的 macOS 应用，用于查看和管理本地安装的软件包。支持 npm、Homebrew 和 pip 三大主流包管理器。

## 功能特性

- **多包管理器支持**：统一管理 npm、Homebrew、pip 的本地包
- **实时搜索**：快速筛选和查找已安装的包，支持防抖优化
- **版本检查**：一键查询最新可用版本，按钮直接显示版本号
- **一键更新**：直接在应用内更新包到最新版本
- **刷新功能**：快速重置列表并重新加载所有包信息
- **包数量统计**：动态显示当前筛选结果的数量
- **版本信息**：清晰展示每个包的当前版本
- **路径信息**：显示包的安装路径
- **优雅的界面**：原生 macOS 设计风格，紧凑列表布局
- **Tooltip 提示**：鼠标悬停查看完整包名
- **加载状态**：操作时显示加载动画，状态实时反馈

## 系统要求

- macOS 13.0 或更高版本
- npm / Homebrew / pip（根据需要管理的包）

## 安装

### 下载预编译版本

1. 从 [Releases](https://github.com/fengxiaodong28/PackageViewer/releases) 下载最新的 `PackageViewer.app`
2. 将应用拖到 `/Applications` 文件夹
3. 首次运行时，可能需要在"系统设置"中允许运行

### 从源码构建

```bash
# 克隆仓库
git clone https://github.com/fengxiaodong28/PackageViewer.git
cd PackageViewer

# 构建应用
./build-app.sh

# 应用将生成到桌面
# 将 PackageViewer.app 拖到 /Applications 文件夹即可安装
```

### 使用 Swift Package Manager

```bash
# Debug 构建
swift build

# Release 构建
swift build -c release

# 直接运行
swift run

# 清理构建产物
swift package clean
```

## 使用方法

### 基本操作

1. **切换包管理器**：点击顶部的标签页切换不同的包管理器（npm、Homebrew、pip）
2. **搜索包**：在搜索框中输入关键词，实时筛选已安装的包（支持 300ms 防抖）
3. **查看包名**：列表显示包名、版本和操作按钮；鼠标悬停可查看完整包名

### 版本管理

4. **检查更新**：
   - 点击 **Check** 按钮查询最新版本
   - 查询完成后按钮显示最新版本号
   - 若有新版本可用，**Update** 按钮将启用（蓝色高亮）

5. **更新包**：
   - 点击 **Update** 按钮直接更新到最新版本
   - 更新完成后弹窗显示成功或失败信息

6. **刷新列表**：
   - 点击搜索栏右侧的 **🔄** 刷新按钮
   - 重置所有包的版本检查状态
   - 重新加载包列表

### 键盘快捷键

- **Cmd + F**：聚焦搜索框
- **Esc**：清空搜索

## 技术栈

- **语言**：Swift 5.9+
- **框架**：SwiftUI
- **架构**：MVVM + Service Layer
- **并发**：async/await
- **依赖管理**：Swift Package Manager（零外部依赖）

## 项目结构

```
PackageViewer/
├── Package.swift                    # Swift 包配置
├── build-app.sh                     # 应用构建脚本
├── CLAUDE.md                        # Claude Code 项目指南
├── README.md                        # 项目说明文档
└── Sources/PackageViewer/
    ├── PackageViewer.swift          # @main App 入口
    ├── Models/                      # 数据模型
    │   ├── Package.swift            # ObservableObject 类（支持响应式更新）
    │   ├── PackageManager.swift     # 包管理器枚举
    │   └── PackageRepository.swift  # 仓储协议 + 错误类型
    ├── Services/                    # 服务层（各包管理器独立实现）
    │   ├── ShellCommandService.swift   # Shell 命令执行服务
    │   ├── NpmPackageService.swift     # npm 包服务
    │   ├── HomebrewPackageService.swift  # Homebrew 包服务
    │   └── PipPackageService.swift       # pip 包服务
    ├── ViewModels/                  # 视图模型
    │   └── PackageListViewModel.swift  # @MainActor，状态管理
    └── Views/                       # 视图
        ├── ContentView.swift        # 标签页容器
        ├── PackageListView.swift    # 包列表视图（含操作列）
        ├── SearchBar.swift          # 搜索栏（含刷新按钮）
        └── EmptyStateView.swift    # 空状态视图
```

## 架构设计

### MVVM + Service Layer

- **Models**：`Package` 作为 `ObservableObject`，支持 `@Published` 属性实现响应式更新
- **Repository Protocol**：定义统一接口 `fetchPackages()`, `queryLatestVersion()`, `updatePackage()`
- **Services**：每个包管理器独立实现，使用各自特定的命令
- **ViewModels**：`@MainActor` 确保线程安全，`@Published` 属性驱动 UI 更新
- **Views**：无状态 SwiftUI 视图，使用 `@ObservedObject` 观察 ViewModel

### 包管理器命令

| 管理器 | 列表命令 | 检查版本 | 更新命令 |
|--------|----------|----------|----------|
| npm | `npm list -g --depth=0` | `npm view <pkg> version` | `npm install -g <pkg>@latest` |
| Homebrew | `brew list --formula` | `brew info --json=v2 <pkg>` | `brew upgrade <pkg>` |
| pip | `pip3 list --format=json` | `pip3 index versions <pkg>` | `pip3 install --upgrade <pkg>` |

## 开发指南

### 添加新的包管理器

1. 创建 `[Name]PackageService.swift` 在 `Services/` 目录
2. 实现 `PackageRepository` 协议
3. 在 `PackageManager.swift` 中添加新的 case
4. 在 `PackageListViewModel.swift` 的 `init` 中添加对应的 service
5. 在 `ContentView.swift` 中添加新的标签页

### 代码规范

- 4 空格缩进
- PascalCase 命名类型，camelCase 命名属性
- 单个类型每个文件（文件名 = 类型名）
- 使用 async/await 处理异步操作
- ViewModels 使用 `@MainActor` 确保 UI 线程安全
- 完善的错误处理，使用特定的错误类型

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！

### 贡献指南

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'feat: Add AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 作者

[https://github.com/fengxiaodong28](https://github.com/fengxiaodong28)

## 致谢

- 感谢 SwiftUI 社区的优秀示例
- 感谢所有贡献者
