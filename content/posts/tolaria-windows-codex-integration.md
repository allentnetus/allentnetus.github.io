---
title: "Tolaria 安装使用全攻略：Windows 环境与 Codex 集成"
date: 2026-08-06
description: "从安装、Vault、Git 与 AI 配置，到 Codex 本地代理和 MCP 集成的 Windows 实用指南。"
tags:
  - Tolaria
  - Codex
  - Windows
  - MCP
  - 知识管理
draft: false
---

> 适用对象：在 Windows 上将 Tolaria 用作本地 Markdown 知识库，并可选地接入 Codex 的用户。  
> 本文基于 Tolaria 官方文档与四次实施会话整理；为便于复用，**文中所有磁盘路径统一以 `D:\` 为示例**。版本和发布包会持续变化，安装时以官方 Stable 下载页为准。

## 目录

1. [产品与数据边界](#1-产品与数据边界)
2. [安装前准备](#2-安装前准备)
3. [安装 Tolaria Stable 到 D 盘](#3-安装-tolaria-stable-到-d-盘)
4. [首次启动与建立 Vault](#4-首次启动与建立-vault)
5. [日常使用：笔记、结构、检索与视图](#5-日常使用笔记结构检索与视图)
6. [Git 备份与多设备同步](#6-git-备份与多设备同步)
7. [AI 功能配置与安全使用](#7-ai-功能配置与安全使用)
8. [以 Codex 为例配置本地代理](#8-以-codex-为例配置本地代理)
9. [可选：让 Codex 通过 MCP 使用 Tolaria](#9-可选让-codex-通过-mcp-使用-tolaria)
10. [验证与故障排查](#10-验证与故障排查)
11. [推荐的起步结构](#11-推荐的起步结构)

---

## 1. 产品与数据边界

Tolaria 是本地优先的桌面知识库：笔记是磁盘上的 Markdown 文件，YAML Frontmatter 保存结构，附件、类型定义与保存的视图也都保存在 Vault 文件夹中；Tolaria 的缓存与窗口偏好则是本机应用状态。换言之，Vault 目录才是你的知识资产和备份对象，而不是应用本身。[官方概览](https://tolaria.md/) / [Vault 说明](https://tolaria.md/concepts/vaults)

它可以打开普通 Markdown 文件夹、Obsidian Vault 或 Git 知识库，不要求迁移或导入数据库。[打开 Vault](https://tolaria.md/start/open-or-create-vault)

### 本文使用的关键路径

| 项目 | 本机路径 / 值 | 作用 |
|---|---|---|
| Tolaria 程序目录 | `D:\Tolaria` | Stable 程序目录示例 |
| Tolaria MCP 入口 | `D:\Tolaria\mcp-server\index.js` | Codex 调用 Tolaria 的本地 stdio 服务 |
| Node.js | `D:\Program Files\nodejs\node.exe` | 运行 MCP 服务；已验证为可用 |
| MCP UI 端口 | `9711` | Tolaria UI 与 MCP 服务的本地 WebSocket 桥接端口 |
| Codex 主配置 | `D:\CodexHome\config.toml` | 示例中的用户级 Codex 配置；需将 `CODEX_HOME` 设置为 `D:\CodexHome` |
| Tolaria 个人插件 | `D:\CodexPlugins\tolaria` | 示例插件目录 |
| 插件 MCP 配置 | `D:\CodexPlugins\tolaria\.mcp.json` | Tolaria 插件的 stdio 配置 |

> 不要把 Vault 建在桌面、下载目录或“文档”根目录等混杂文件夹。即使 Tolaria 可以打开它们，Git 初始化、备份和权限控制都会变得难以管理。

---

## 2. 安装前准备

### 2.1 选择发布渠道

日常使用选择 **Stable**。Stable 是手动晋级的版本；Alpha 随 `main` 分支更新，适合测试而非主知识库。切换渠道或更新前，应先提交或推送重要 Vault 改动。[发行渠道说明](https://tolaria.md/reference/release-channels)

官方入口：

- [Stable 下载页](https://tolaria.md/download/)
- [官方安装文档](https://tolaria.md/start/install)
- [GitHub 最新 Stable Release](https://github.com/refactoringhq/tolaria/releases/latest)

### 2.2 准备目录

建议把程序与数据分开：

```text
D:\Tolaria\                        # 程序安装目录
D:\Knowledge\MyVault\              # 个人 Vault 示例
D:\Knowledge\WorkVault\            # 工作 Vault 示例（可选）
```

可用 PowerShell 创建专用 Vault 文件夹：

```powershell
New-Item -ItemType Directory -Force -Path 'D:\Knowledge\MyVault'
```

### 2.3 Windows 安全提示

只从 Tolaria 官方下载页或官方 GitHub Release 取得安装包。Windows 目前属于“已支持、仍较早期”的平台；若公司设备受 SmartScreen、Defender 或 WDAC 策略拦截，应走公司正常的软件审批流程，**不要关闭安全防护**。[官方 Windows 平台说明](https://tolaria.md/start/install)

---

## 3. 安装 Tolaria Stable 到 D 盘

### 3.1 下载与安装

1. 打开 [Tolaria Stable 下载页](https://tolaria.md/download/)；不要从 Alpha 页面或不明第三方下载。
2. 选择 **Windows** 安装包（x64）。下载页会重定向到官方 GitHub Release。
3. 运行安装程序。
4. 当安装向导出现安装路径时，改为：

   ```text
   D:\Tolaria
   ```

5. 完成安装并启动 Tolaria。

历史实施已验证 NSIS 安装包支持自定义程序目录。本文统一使用 `D:\Tolaria`；如果你当前下载的安装器没有目录选择页，不要自行移动运行中的程序文件；先按向导的实际限制完成，记录其目录，再重新检查是否存在官方便携或数据目录选项。

### 3.2 验证安装

至少完成以下三项：

```powershell
Test-Path 'D:\Tolaria\mcp-server\index.js'
Get-ChildItem 'D:\Tolaria' -Force | Select-Object Name, Length, LastWriteTime
```

- Tolaria 窗口可以正常打开。
- `D:\Tolaria` 是实际安装目录，而非仅下载目录。
- 在应用的 About/版本信息处核对版本，并与下载的 Stable Release 相符。

> 早期会话曾记录了一个已安装版本号；它不是固定版本要求。请以当前官方 Stable Release 与应用内版本为准。

---

## 4. 首次启动与建立 Vault

首次启动有三条路径：克隆 **Getting Started Vault**、打开已有本地 Vault、创建新的空 Vault。示例 Vault 克隆到本地后会断开远程，因而可以随意练习而不会把教程改动推送回上游。[首次启动流程](https://tolaria.md/start/first-launch)

### 4.1 推荐路线：先使用示例 Vault

1. 打开 Tolaria。
2. 首次引导中选择 **Getting Started Vault**。
3. 用它熟悉类型、关系、视图、Git 面板和 AI 面板。
4. 练习结束后，打开自己的专用目录：`D:\Knowledge\MyVault`。

### 4.2 创建新的空 Vault

1. 在首次引导选择 **Create a new empty vault**；或按 `Ctrl+K`，搜索并执行相应的创建/打开 Vault 命令。
2. 在系统文件选择器中定位到 `D:\Knowledge\MyVault`。
3. 确认后，Tolaria 将该文件夹注册为 Vault；新笔记默认直接建在 Vault 根目录。
4. 创建第一条笔记（`Ctrl+N`），标题写成明确的 H1，例如“2026 年知识库使用约定”。

### 4.3 打开现有 Obsidian 或 Markdown 库

1. 先关闭外部工具可能正在批量改写的任务（同步、格式化、Git rebase 等）。
2. 在 Tolaria 中选 **Open existing local vault**。
3. 选择现有 Vault 的根目录，而不是某个子文件夹或 `.obsidian` 配置目录。
4. 等待扫描完成。Tolaria 会递归扫描 `.md`，并读取已有 Frontmatter；原文件不会被导入到私有数据库。[打开已有 Vault](https://tolaria.md/start/open-or-create-vault)
5. 外部编辑后按 `Ctrl+K` → `Reload Vault` 重新扫描。

### 4.4 Vault 文件布局与多库

Tolaria 不强制文件夹分类，笔记可平铺；类型和关系才是它的主要组织方式。建议只约定两类特殊目录：`attachments/` 放附件、`views/` 放保存的自定义视图。[官方文件布局](https://tolaria.md/reference/file-layout)

```text
D:\Knowledge\MyVault\
├─ attachments\
│  ├─ architecture.png
│  └─ source.pdf
├─ views\
│  └─ active-projects.yml
├─ 个人系统说明.md
├─ 项目-示例.md
└─ 人物-示例.md
```

如有个人库和工作库，不要合并目录。在 Tolaria 中分别注册，然后进入 `Settings` → `Vaults` → 打开 **Use multiple vaults at the same time**；底部左侧 Vault 菜单决定哪些库参与统一图谱、搜索和 Wikilink。Git 提交、同步、视图与修复仍以当前 Vault 为作用域。[多 Vault 官方说明](https://tolaria.md/concepts/vaults)

---

## 5. 日常使用：笔记、结构、检索与视图

### 5.1 最小日常工作流

1. **捕捉**：按 `Ctrl+N`，先写清晰的 H1 与原始内容；不确定归属时先不强行分类。
2. **链接**：输入 `[[` 搜索并选择已有笔记，形成 Wikilink。
3. **整理**：在属性面板或 Markdown Frontmatter 补充 `type`、`status`、关系字段。
4. **回顾**：从 Inbox 或保存视图处理未归类项目。
5. **保存历史**：审查差异后提交 Git。

在 Windows 中，`Ctrl+K` 打开命令面板，常用命令包括 `New Note`、`Search`、`Open Settings`、`Reload Vault`、`Add Remote`、`Toggle Raw Mode`、`Toggle AI Panel`。[命令面板参考](https://tolaria.md/guides/use-command-palette)

### 5.2 笔记与 Frontmatter 示例

下面是一条项目笔记，普通编辑器和 Git 都能读取：

```markdown
---
type: Project
status: Active
owner: "[[张三]]"
related_to:
  - "[[企业知识库]]"
review_date: 2026-08-13
---

# Tolaria 试用与迁移评估

## 目标

- 用一周验证日常捕捉、Git 历史和 Codex 协同。

## 下一步

- [ ] 建立 Project 类型与活动项目视图
```

YAML Frontmatter 负责结构，Markdown 正文仍是正文。附件是 Vault 内普通文件，白板和电子表格也以可持久化的 Markdown 文件保存。[Vault 核心规则](https://tolaria.md/concepts/vaults) / [文件布局](https://tolaria.md/reference/file-layout)

### 5.3 Types：给重复类别建立模板

当某一类笔记反复出现时才创建 Type，例如 `Project`、`Person`、`Meeting`。执行 `Ctrl+K` → `New Type`，或点击侧边栏 Types 标题旁的 `+`。

一个类型本身也是 Markdown：

```markdown
---
type: Type
_icon: briefcase
_color: blue
_sidebar_label: Projects
_order: 10
---

# Project

## Goal

## Next actions

- [ ]
```

类型可配置图标、颜色、侧边栏顺序、固定属性、默认值和新笔记模板；不要把一次性的标签做成 Type，应改用属性或保存视图。[创建 Type](https://tolaria.md/guides/create-types)

### 5.4 Properties、Relationships 与 Custom Views

- **Properties**：如 `status: Active`、`review_date: 2026-08-13`，用于筛选、排序和展示。
- **Relationships**：用字段里的 `[[笔记名]]` 表达关系，例如 `owner: "[[张三]]"`。
- **Custom Views**：为重复问题建立保存的筛选视图，例如“活动项目”“本周修改过的笔记”“需跟进的人”。视图保存为 Vault 中的结构化文件，可使用 `all` / `any` 组合条件，日期条件支持 `today`、`one week ago` 等动态值。[自定义视图](https://tolaria.md/guides/build-custom-views)

先写清视图要回答的问题，再建筛选条件。例如：

```text
问题：我这周需要推进哪些项目？
条件：type = Project AND status = Active
列：标题、owner、review_date、下一步
排序：review_date 升序
```

### 5.5 编辑器与文件

Tolaria 提供块编辑、斜杠命令、Wikilink、Raw Markdown、白板、媒体预览等能力；需要精确查看源文本时，从 `Ctrl+K` 使用 `Toggle Raw Mode`。PDF、图片等附件仍是原文件，建议放在 `attachments/` 并以相对路径链接。外部程序改动文件后使用 `Reload Vault`。

---

## 6. Git 备份与多设备同步

Git 不是开启 Vault 的前提，但强烈建议用于历史、回滚、备份和设备同步。普通 Markdown 文件夹可直接使用；Git 初始化必须在独立 Vault 根目录中显式执行。[官方 Git 说明](https://tolaria.md/concepts/vaults)

### 6.1 初始化本地 Git 仓库

方法一：在 Tolaria 中按提示初始化 Git（不要对大而杂的 Documents/Desktop 根目录执行）。

方法二：在 Vault 根目录执行：

```powershell
Set-Location 'D:\Knowledge\MyVault'
git init
git add .
git commit -m 'Initialize Tolaria vault'
```

然后回到 Tolaria 重新加载 Vault。

### 6.2 添加远程仓库

前提：远程仓库已经创建，且系统 Git 在 Windows 上已能完成认证。Tolaria 调用系统 Git，不保存 GitHub/GitLab 等平台专用凭据。

在 Tolaria 的底部状态栏点击 remote 标识，或 `Ctrl+K` → `Add Remote`：

1. 粘贴远程 URL，例如 `git@github.com:your-account/my-vault.git`。
2. 确认远程名（通常为 `origin`）。
3. 按提示 Fetch 或 Push。

推荐 SSH 密钥、GitHub CLI 登录或已有 Git credential helper。先在终端验证后再回到 Tolaria：

```powershell
Set-Location 'D:\Knowledge\MyVault'
git remote -v
git ls-remote origin
```

详见 [连接 Git 远程仓库](https://tolaria.md/guides/connect-a-git-remote)。

### 6.3 提交、推送与冲突

手动操作：打开 Git/Changes 面板 → 检查文件差异 → 写简短提交信息 → Commit → 已配 remote 时 Push。远程先有更新时先 Pull，处理冲突后再 Push。

可选开启 `Settings` 中 Git-enabled Vault 的 **AutoGit**，它会在空闲或应用失活后做保守的自动提交/推送。即使启用 AutoGit，也应在大规模 AI 改动前后查看 diff；小提交更容易审查和回滚。[Git 管理与 AutoGit](https://tolaria.md/guides/commit-and-push)

---

## 7. AI 功能配置与安全使用

### 7.1 三类 AI Target

在 `Settings` 中选择默认 AI target：

| 类型 | 用途 | 是否能通过工具编辑 Vault |
|---|---|---|
| Coding agent | Codex、Claude Code、GitHub Copilot、OpenCode 等 | 可以，受权限模式约束 |
| Local model | Ollama、LM Studio | 不可以，仅基于笔记上下文聊天 |
| API model | OpenAI、Anthropic、Gemini、OpenRouter 或兼容端点 | 不可以，仅基于笔记上下文聊天 |

官方路径：`Settings` → 选择默认 AI target；AI 面板用于连续对话，编辑器内可使用 `Ctrl+K` 后按空格输入内联提示词。[使用 AI](https://tolaria.md/guides/use-ai-panel)

### 7.2 权限与密钥

- **Vault Safe**：Coding agent 仅限文件、搜索与编辑工具；日常推荐。
- **Power User**：可允许支持的 agent 运行 Shell；只在理解其作用范围时使用。
- Direct model（本地/API）只能聊天，不能经工具写 Vault。
- API key 不存入 Vault：在 `Settings` 中选择仅本机保存、环境变量读取，或本地模型无 key。添加后使用测试操作确认端点与模型都能响应。[配置模型](https://tolaria.md/guides/configure-ai-models)

每次 AI 编辑后，都按以下顺序操作：**看 diff → 检查链接/Frontmatter → Git commit**。敏感工作库建议先用 Vault Safe，并避免把密钥、客户隐私信息或未脱敏资料交给外部 API 模型。

---

## 8. 以 Codex 为例配置本地代理

本节的“本地代理”是指：在 **Tolaria 的 AI 面板中选择 Coding agent → Codex**，由 Tolaria 拉起本机可用的 Codex 命令来完成 Vault 内的搜索、读取与编辑。它不同于下一节的 MCP：MCP 是在独立 Codex 任务中调用 Tolaria 的工具。

### 8.1 先理解两个集成方式

| 方式 | 从哪里发起 | 谁执行编辑 | 适合什么场景 | 关键前提 |
|---|---|---|---|---|
| Tolaria 本地 Coding agent | Tolaria 的 AI 面板或编辑器内提示 | 本机 Codex agent | 正在阅读/写作时，让 AI 直接基于当前 Vault 协作 | Tolaria 能在其启动环境的 `PATH` 中发现 `codex` |
| Tolaria MCP | Codex 桌面应用、CLI 或 IDE 的任务 | 外部 Codex 任务通过 MCP 工具 | 从 Codex 侧检索、创建、打开或刷新 Tolaria 笔记 | Tolaria 已打开 Vault，MCP 服务已配置 |

**不要让两个方式同时编辑同一篇笔记。**一个任务完成、保存并刷新 Vault 后，再开始另一个；Git diff 是最终的变更审查依据。

### 8.2 前提：确认本机 Codex 命令可发现

在 PowerShell 执行：

```powershell
Get-Command codex -ErrorAction SilentlyContinue
where.exe codex
codex --version
```

合格标准：

- 前两条能返回实际命令路径；
- `codex --version` 能输出版本而非“不是内部或外部命令”；
- 首次运行若要求登录，先按 Codex 的登录流程完成，再继续配置。

Tolaria 只能启动已安装且可发现的本地 CLI agent。桌面应用继承的 `PATH` 可能与已打开的交互终端不同，因此“PowerShell 能运行、Tolaria 看不到”通常是环境变量尚未被 Tolaria 进程继承，而不是 Vault 配置问题。[Tolaria：AI Agent Not Found](https://tolaria.md/troubleshooting/ai-agent-not-found)

若 `codex` 不可发现：

1. 先按 OpenAI 官方方式安装或修复 Codex CLI；不要在 Tolaria 中填写一个猜测的可执行文件路径。
2. 重新打开 PowerShell，重复上面三条命令。
3. 确认当前用户的 `PATH` 包含 `where.exe codex` 返回路径所在的目录。检查命令：

   ```powershell
   $env:Path -split ';'
   ```

4. **完全退出并重启 Tolaria**，因为已经运行的桌面应用不会自动继承新 PATH。

> 本机 `D:\Program Files\nodejs\node.exe` 是 Tolaria MCP 所需的 Node 运行时；它不等同于 Codex 本地代理命令。不要为了让 Tolaria 发现 Codex 而把 Node 路径填入 AI target。

### 8.3 在 Tolaria 中选择 Codex

1. 启动 Tolaria，并先打开目标 Vault，例如 `D:\Knowledge\MyVault`。
2. 打开 `Settings`。
3. 在 AI 设置中将默认 AI target 选为 **Coding agent**。
4. 在 agent 列表中选择 **Codex**。
5. 模型选项优先选择 **Agent default**，让已安装的 Codex 负责模型选择；只有你已确认某个模型可用时才在 Tolaria 的 agent model picker 中显式选择。
6. 权限模式先选 **Vault Safe**；只在确有必要运行 Git、脚本或其他 Shell 命令时，临时改为 **Power User**。
7. 打开 AI 面板，提出一次只读请求验证，例如：`列出这个 Vault 中与“Tolaria”相关的笔记，只总结，不修改文件。`

Tolaria 官方将 Codex 列为可用于 tool-backed Vault 编辑的 Coding agent；它也区分可编辑 Vault 的 Coding agent 和只聊天的本地/API 模型。Coding agent 的 Vault Safe 只限文件、搜索、编辑工具，而 Power User 可允许支持的 Shell 命令。[Tolaria AI 配置说明](https://tolaria.md/guides/use-ai-panel)

### 8.4 给 Codex 的 Vault 级操作边界

在 Vault 根目录创建 `AGENTS.md`，让 Codex 无论从 Tolaria 或其他 Codex 工作面进入该目录时，都读到同一套可审查的约束。示例文件路径：

```text
D:\Knowledge\MyVault\AGENTS.md
```

建议从以下最小内容开始，再按你的资料敏感性增补：

```markdown
# MyVault 操作约定

- 笔记均为 UTF-8 Markdown；Frontmatter 使用 YAML。
- 新附件放入 `attachments/`，新保存视图放入 `views/`。
- 未经明确要求，不移动、删除或批量改写既有笔记。
- 新建笔记必须包含 H1；有明确类别时填写 `type`。
- 编辑前先说明拟修改的文件；编辑后总结变更。
- 完成一组相关修改后，先提供 diff 摘要，等待人工审查再提交 Git。
- 不读取或输出 Vault 外的私人文件；不将 Vault 内容发送到未经批准的外部服务。
```

`AGENTS.md` 适合放随 Vault 持久化的工作规则；本示例将 Codex 的用户级设置与 MCP 配置放在 `D:\CodexHome\config.toml`。为使该路径生效，应将用户环境变量 `CODEX_HOME` 设为 `D:\CodexHome`；受信任项目也可以有 `.codex\config.toml` 覆盖层。项目级配置不能取代用户级认证与 provider 设置。[Codex 配置参考](https://developers.openai.com/codex/config-advanced)

在全新 D 盘布局中，可先执行以下命令，然后**完全重启 Codex**：

```powershell
New-Item -ItemType Directory -Force -Path 'D:\CodexHome', 'D:\CodexPlugins\tolaria'
[Environment]::SetEnvironmentVariable('CODEX_HOME', 'D:\CodexHome', 'User')
```

若已有 Codex 配置，先备份原配置，再将需要保留的配置内容合并到 `D:\CodexHome\config.toml`；不要仅改环境变量就假定旧配置会自动迁移。

### 8.5 在 Tolaria 内实际使用 Codex

#### 方式 A：AI 面板（建议用于多步工作）

适用于梳理、研究、迁移、批量但受控的结构化编辑：

1. 打开 Tolaria 的 AI 面板（也可 `Ctrl+K` → `Toggle AI Panel`）。
2. 检查 target 显示为 Codex，并确认是 Vault Safe。
3. 先给范围、再给任务、最后给验收标准。
4. 让 Codex 先报告拟变更，再执行有写入的步骤。
5. 回到 Git/Changes 面板审查 diff；必要时撤销或修正，然后才 Commit。

推荐提示词模板：

```text
范围：仅处理当前 Vault 中 `项目-*.md` 文件，不读取 Vault 外文件。
任务：找出 status 为 Active 且 review_date 早于今天的项目。
输出：先列出候选文件、判断依据和建议动作；不要修改文件。
```

```text
范围：仅编辑 `项目-Tolaria 试用.md`。
任务：根据该笔记已有“下一步”内容，将 review_date 更新为下周三，补一条可执行待办。
验收：保留现有 Frontmatter 字段、不要改标题、完成后说明精确改动。
```

#### 方式 B：编辑器内联提示（建议用于当前段落）

在当前笔记中按 `Ctrl+K`，再按空格输入请求。适合改写、补全、摘要和提取行动项；请求必须说明“仅修改当前选中段落”或“只给建议不写入”，避免扩大改动范围。Tolaria 将 AI 面板定位为连续对话与 agent 工作，内联提示则更适合正在写作时的即时处理。[Tolaria 使用 AI](https://tolaria.md/guides/use-ai-panel)

### 8.6 Codex 任务与 Vault 生命周期

每次建议遵循这个闭环：

```text
打开并选定 Vault
  → Codex 只读盘点
  → 人工确认范围
  → Codex 小批量编辑
  → Tolaria Git/Changes 审查
  → Commit（必要时 Push）
```

- 给每条请求一个明确范围，优先指定相对路径或文件模式。
- 对批量操作，先要求“只列清单、不写入”，确认后再编辑。
- Codex 编辑后若笔记列表未更新，执行 `Ctrl+K` → `Reload Vault`。
- 当前 Vault 不在 Git 中也能使用 Codex，但没有可审查的历史与回滚，故不建议对重要资料这样操作。
- 执行长任务时，随时使用 Tolaria 的停止控件；停止当前流不会改变下次默认 target。

### 8.7 本地代理常见问题

| 现象 | 最可能原因 | 最小处理 |
|---|---|---|
| Tolaria 不显示 Codex | `codex` 不在 Tolaria 继承的 PATH 中 | 用 `where.exe codex` 验证，修复 PATH 后完整重启 Tolaria |
| 终端能运行 Codex，Tolaria 不能 | Tolaria 在 PATH 改动前启动 | 退出 Tolaria，重新从开始菜单启动 |
| Codex 被发现但请求失败 | 登录、模型可用性或权限模式问题 | 先在终端运行 `codex --version` 和一次简单任务，回到 Tolaria 选 Agent default、Vault Safe |
| AI 改动超出预期 | 提示词范围过宽或启用了 Power User | 停止任务，查看 diff，回滚不需要的改动；下次先做只读盘点 |
| 文件已改但 Tolaria 未显示 | 文件系统扫描尚未刷新 | `Ctrl+K` → `Reload Vault` |
| Codex 与 MCP 两边都在改笔记 | 并发写入造成覆盖或难以审查 | 停止一侧，刷新 Vault，审查 Git diff 后再继续 |

---

## 9. 可选：让 Codex 通过 MCP 使用 Tolaria

### 8.1 作用与前提

Tolaria 的 MCP 服务是本地 **stdio** 服务，运行后会连接到 `ws://localhost:9711` 的 Tolaria UI bridge。它可提供笔记搜索、Vault 上下文、读取、创建（不覆盖已有文件）、打开笔记与刷新 Vault 等工具；实际工具集合会随 Tolaria 版本变化，不能把数量当作兼容性承诺。[官方 MCP 入口源码](https://github.com/refactoringhq/tolaria/blob/main/mcp-server/index.js)

前提：

1. Tolaria 已安装在 `D:\Tolaria` 并能够启动。
2. Tolaria 处于运行状态，且已打开至少一个 Vault。
3. Node.js 可执行文件存在：`D:\Program Files\nodejs\node.exe`。
4. `D:\Tolaria\mcp-server\index.js` 存在。

验证命令：

```powershell
Test-Path 'D:\Program Files\nodejs\node.exe'
& 'D:\Program Files\nodejs\node.exe' --version
Test-Path 'D:\Tolaria\mcp-server\index.js'
```

本机实施时 Node 为 `v24.15.0`，入口存在，且以 `WS_UI_PORT=9711` 启动后输出正常的 `Tolaria MCP server running`。

### 8.2 推荐：个人 Codex 插件配置

已部署的插件目录：

```text
D:\CodexPlugins\tolaria\
├─ .codex-plugin\plugin.json
└─ .mcp.json
```

核心 MCP 配置文件 `D:\CodexPlugins\tolaria\.mcp.json` 应为：

```json
{
  "mcpServers": {
    "tolaria": {
      "type": "stdio",
      "command": "D:\\Program Files\\nodejs\\node.exe",
      "args": [
        "D:\\Tolaria\\mcp-server\\index.js"
      ],
      "env": {
        "WS_UI_PORT": "9711"
      }
    }
  }
}
```

`plugin.json` 用于描述插件；`.mcp.json` 才是启动本地服务所需的关键配置。配置变更后，**新开一个 Codex 任务**，使其重新初始化 MCP 服务；旧任务不保证重新读取新插件。

### 8.3 不使用插件时的等价配置

若你使用的是 Codex 的主配置，而非个人插件，编辑：

```text
D:\CodexHome\config.toml
```

其等价 TOML 结构应类似：

```toml
[mcp_servers.tolaria]
command = 'D:\Program Files\nodejs\node.exe'
args = ['D:\Tolaria\mcp-server\index.js']

[mcp_servers.tolaria.env]
WS_UI_PORT = '9711'
```

> 两种方式选一种作为配置事实来源，避免同名 `tolaria` 服务由两处重复启动。本文本机已采用个人插件路径。

### 8.4 验证 MCP 已加载

1. 先启动 Tolaria 并打开 Vault。
2. 新建 Codex 任务。
3. 在任务中检查是否出现 Tolaria MCP 工具（通常包括 `search_notes`、`get_vault_context`、`list_vaults`、`get_note`、`create_note`、`open_note`、`refresh_vault` 等；具体以当前 `tools/list` 为准）。
4. 先做只读验证，例如请求列出 Vault 或搜索一个已知笔记。
5. 最后再测试创建一条临时笔记，确认它出现在已打开的 Vault 中；随后用 Git diff 审查。

首次实施已完成 MCP stdio 初始化和工具枚举验证；若当前会话没有显示新工具，优先新建任务，再按下一章排查。

---

## 10. 验证与故障排查

### 10.1 运行检查表

| 检查项 | 期望结果 | 处理方式 |
|---|---|---|
| Stable 安装 | 应用能打开，版本与 Release 相符 | 从官方 Stable 下载页重新核对 |
| 安装路径 | 程序在 `D:\Tolaria` | 检查安装向导记录与目录内容 |
| Vault 加载 | `.md` 笔记出现在列表 | 确认选的是 Vault 根目录，执行 `Reload Vault` |
| 外部文件改动 | 新/改笔记被识别 | `Ctrl+K` → `Reload Vault` |
| Git 远程 | `git ls-remote origin` 成功 | 修复系统 Git 的 SSH/凭据，再在 Tolaria 中操作 |
| AI 模型 | Settings 测试连接成功 | 检查 endpoint、model ID、key 的本机/环境变量路径 |
| MCP | 新 Codex 任务可见 Tolaria 工具 | 检查 Node、入口、`WS_UI_PORT` 和 Tolaria 是否已打开 |

### 10.2 MCP 无法加载或没有工具

按顺序只读检查：

```powershell
Test-Path 'D:\CodexPlugins\tolaria\.mcp.json'
Test-Path 'D:\Program Files\nodejs\node.exe'
Test-Path 'D:\Tolaria\mcp-server\index.js'
& 'D:\Program Files\nodejs\node.exe' --version

$env:WS_UI_PORT = '9711'
& 'D:\Program Files\nodejs\node.exe' 'D:\Tolaria\mcp-server\index.js'
```

最后一条会以前台方式运行服务，看到 `Tolaria MCP server running` 即证明入口能驻留；用 `Ctrl+C` 停止测试进程。若只看到服务启动却无法操作当前 Vault，确认 Tolaria 已启动、已打开 Vault，且 `9711` 与配置一致。

常见原因：

- 修改了 `.mcp.json` 但继续使用旧 Codex 任务：新开任务。
- `command` 只写了 `node`，但 Codex 的 PATH 与交互终端不同：使用本文的绝对路径。
- `args` 指向不存在的入口：重新确认 `D:\Tolaria\mcp-server\index.js`。
- 端口不一致：`WS_UI_PORT` 必须与 Tolaria UI bridge 使用的端口一致，本机为 `9711`。
- MCP 工具存在但访问不到笔记：先在 Tolaria 打开 Vault，再调用 `list_vaults` 或 `get_vault_context`。

### 10.3 不相关的 PaddleOCR 故障不要误判为 Tolaria

此前的 MCP 诊断曾发现 `paddleocr` 因 `paddleocr_mcp` 命令和 Python 包缺失而未加载；这是另一个 MCP 服务的独立依赖问题，和 Tolaria 的 Node/stdio 配置无关。排查 Tolaria 时不要因此改动 `D:\Tolaria` 或其插件配置。

---

## 11. 推荐的起步结构

为降低迁移成本，先用一个小 Vault 完整跑通“捕捉—结构化—Git—AI 审查”闭环，再考虑打开既有 Obsidian 主库。

```text
D:\Knowledge\MyVault\
├─ attachments\
├─ views\
├─ 个人系统说明.md                 # 约定、字段字典、链接规则
├─ Project.md                      # Type 定义
├─ Person.md                       # Type 定义
├─ Meeting.md                      # Type 定义
├─ 项目-Tolaria 试用.md
└─ 会议-2026-08-06.md
```

建议顺序：

1. 用一周只做 `Ctrl+N` 捕捉和 Wikilink。
2. 为真正重复的笔记建立 `Project`、`Person`、`Meeting` 三个 Type。
3. 建“活动项目”和“待回顾会议”两个 Custom View。
4. 初始化 Git，形成小而可读的提交。
5. 需要 AI 协作时，先选 Vault Safe；验证后再决定是否接入 Codex MCP。

## 官方参考

- [Tolaria 文档首页](https://tolaria.md/)
- [安装 Tolaria](https://tolaria.md/start/install)
- [首次启动](https://tolaria.md/start/first-launch)
- [打开或创建 Vault](https://tolaria.md/start/open-or-create-vault)
- [Vault 与多 Vault](https://tolaria.md/concepts/vaults)
- [Git 远程与提交](https://tolaria.md/guides/connect-a-git-remote) / [AutoGit](https://tolaria.md/guides/commit-and-push)
- [AI 使用](https://tolaria.md/guides/use-ai-panel) / [模型配置](https://tolaria.md/guides/configure-ai-models)
- [Tolaria 官方仓库](https://github.com/refactoringhq/tolaria)
- [OpenAI Codex 配置与 MCP 参考](https://developers.openai.com/codex/config-advanced)
- [OpenAI Codex 自定义与 AGENTS.md 参考](https://developers.openai.com/codex/guides/agents-md)
