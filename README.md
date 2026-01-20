# PackageViewer

一个简洁优雅的 macOS 应用，用于查看和管理本地安装的软件包。支持 npm、Homebrew 和 pip 三大主流包管理器。

## 功能特性

- **多包管理器支持**：统一管理 npm、Homebrew、pip 的本地包
- **实时搜索**：快速筛选和查找已安装的包
- **包数量统计**：动态显示当前筛选结果的数量
- **版本信息**：清晰展示每个包的版本号
- **路径信息**：显示包的安装路径
- **优雅的界面**：原生 macOS 设计风格

## 系统要求

- macOS 14.0 或更高版本

## 安装

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
```

## 使用方法

1. **切换包管理器**：点击顶部的标签页切换不同的包管理器
2. **搜索包**：在搜索框中输入关键词，实时筛选已安装的包
3. **查看详情**：列表中显示包名、版本和安装数量
4. **清空搜索**：点击搜索框右侧的 ✕ 按钮清空搜索

## 技术栈

- **语言**：Swift 5.9+
- **框架**：SwiftUI
- **架构**：MVVM + Service Layer
- **依赖管理**：Swift Package Manager

## 项目结构

```
PackageViewer/
├── Package.swift                    # Swift 包配置
├── build-app.sh                     # 应用构建脚本
└── Sources/PackageViewer/
    ├── Models/                      # 数据模型
    │   ├── Package.swift
    │   ├── PackageManager.swift
    │   └── PackageRepository.swift
    ├── Services/                    # 服务层
    │   ├── ShellCommandService.swift
    │   ├── NpmPackageService.swift
    │   ├── HomebrewPackageService.swift
    │   └── PipPackageService.swift
    ├── ViewModels/                  # 视图模型
    │   └── PackageListViewModel.swift
    └── Views/                       # 视图
        ├── ContentView.swift
        ├── PackageListView.swift
        ├── SearchBar.swift
        └── EmptyStateView.swift
```

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！

## 作者

[https://github.com/fengxiaodong28](https://github.com/fengxiaodong28)
