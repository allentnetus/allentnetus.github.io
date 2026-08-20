---
title: "Codex 接入 DeepSeek Harness 的两种路径及原理"
date: 2026-08-20
description: "介绍 Codex 接入 DeepSeek Harness 的 LLM Provider 与 Codex CLI Subagent 两条路径、配置方法、调用链和常见问题。"
tags:
  - Codex
  - DeepSeek Harness
  - AI Agent
  - Subagent
draft: false
---

## 1. 概述

Codex 可以接入 DeepSeek Harness（以下简称 DSH），但需要先区分两种完全不同的接入方式：

1. **路径一：把 OpenAI Codex 当作 LLM 提供商**
   - Codex 作为主 Agent 的模型路由。
   - 可以出现在 DSH 右下角的模型选择器中。
   - 通过 `llm-pi-ai` 和 pi-ai 的 `openai-codex` provider 工作。

2. **路径二：把 Codex CLI 当作 Subagent 工具**
   - Codex CLI 作为主 Agent 可以调用的子代理。
   - 主 Agent 可以把某个任务委派给本机 Codex CLI。
   - 不会作为主模型出现在右下角模型列表中。

两条路径可以同时启用，因为它们使用的是 DSH 中不同的注册表和调用链。

---

## 2. 两条路径的整体架构

```text
                         DeepSeek Harness
                                │
             ┌──────────────────┴──────────────────┐
             │                                     │
   路径一：LLM Provider                  路径二：Subagent Provider
             │                                     │
     ctx.llm / llm-pi-ai                    ctx.subagents
             │                                     │
     openai-codex 路由                       codex provider
             │                                     │
   右下角模型选择器                     codex app-server --stdio
             │                                     │
   主 Agent 直接使用 Codex               Codex CLI 独立子进程
```

两条路径的关键差异：

| 对比项 | 路径一：LLM Provider | 路径二：Codex CLI Subagent |
|---|---|---|
| DSH 内部位置 | `ctx.llm` | `ctx.subagents` |
| Provider 名称 | `openai-codex` | `codex` |
| 是否出现在模型下拉框 | 是 | 否 |
| 是否作为主 Agent 模型 | 是 | 否 |
| 是否启动 Codex CLI | 否，直接走 pi-ai provider | 是，启动 `codex app-server --stdio` |
| 模型由谁决定 | DSH 模型选择器 | Codex CLI 自己的配置 |
| 上下文 | 主 Agent 当前上下文 | 独立、一次性的 Codex 上下文 |
| 认证来源 | DSH credentials / 环境变量 | Codex CLI 自己的登录状态 |

---

## 3. 路径一：把 OpenAI Codex 当作 LLM 提供商

### 3.1 原理

DSH 使用 `@deepseek-ai/dsh-llm-pi-ai` 适配器接入 pi-ai。pi-ai 内置了 `openai-codex` provider，它使用 Codex Responses 协议访问 OpenAI/ChatGPT Codex 后端。

该路由的核心信息包括：

```text
Provider: openai-codex
协议: openai-codex-responses
后端: https://chatgpt.com/backend-api
```

当路径一启用后，DSH 会把该 provider 的模型加入 LLM 模型目录，因此可以在右下角模型选择器中选用。

### 3.2 配置方式

在 `$DSH_HOME/settings.yaml` 中添加：

```yaml
llm-pi-ai:
  providers:
    openai-codex:
      apiKeyEnv: CODEX_OAUTH_TOKEN
```

本机 DSH 的实际配置文件是：

```text
<DSH_HOME>/settings.yaml
```

`apiKeyEnv` 的值只是凭据引用名，不应把真实 token 直接写进 YAML：

```yaml
apiKeyEnv: CODEX_OAUTH_TOKEN
```

### 3.3 Token 来源

Codex CLI 登录后，通常会把凭据保存到：

```text
<USER_HOME>/.codex/auth.json
```

常见字段包括：

```text
auth_mode
tokens.access_token
tokens.refresh_token
tokens.account_id
```

其中：

- `tokens.access_token`：当前访问 token。
- `tokens.refresh_token`：刷新 token。
- `tokens.account_id`：ChatGPT/Codex 账号信息。

**不要把 access token 或 refresh token 写进本文档、提交到 Git、发送到聊天记录或打印到终端日志。**

### 3.4 推荐的凭据保存方式

推荐使用 DSH 的 credentials 服务，或者使用 Web 界面的 Models/模型设置页面保存凭据。

逻辑上等价于：

```text
credential reference: CODEX_OAUTH_TOKEN
credential value:     <你的 access_token>
```

DSH 运行时根据：

```yaml
apiKeyEnv: CODEX_OAUTH_TOKEN
```

去 credentials 服务中查找对应值。

也可以使用环境变量，但要注意：

- 已经运行的 DSH 进程不会自动获得后来新增的环境变量。
- 设置环境变量后必须重启 DSH。
- Windows 子进程通常继承父进程创建时的环境快照。
- 长期运行的 Harness、Node 或 PowerShell 进程可能仍然看不到新变量。

因此，DSH Web 场景下优先使用 credentials 服务更可靠。

### 3.5 路径一的限制

路径一并不等同于“DSH 自动执行 `codex login`”。DSH 的 pi-ai 适配器不会替你完成完整的 OAuth 登录交互。

实际使用时要注意：

1. 需要先有有效的 ChatGPT/Codex OAuth 凭据。
2. access token 会过期。
3. 不应假设 DSH 的 `apiKeyEnv` 路由会自动完成 Codex CLI 那套刷新流程。
4. token 失效后，需要重新执行 `codex login` 或重新把新 token 存入 credentials 服务。
5. 模型是否可用还取决于 ChatGPT 账号类型、权限、地区和当前服务端目录。

### 3.6 当前环境中的验证方式

DSH Web API 使用 RPC 风格接口。查询 provider：

```powershell
$body = @{
  type = "client-request"
  rpcId = "check-provider"
  method = "llm.providers"
  payload = @{}
} | ConvertTo-Json -Depth 4

Invoke-RestMethod `
  -Uri "http://127.0.0.1:3080/api/llm.providers" `
  -Method Post `
  -Body $body `
  -ContentType "application/json"
```

查询模型目录：

```powershell
$body = @{
  type = "client-request"
  rpcId = "check-models"
  method = "llm.models"
  payload = @{}
} | ConvertTo-Json -Depth 4

Invoke-RestMethod `
  -Uri "http://127.0.0.1:3080/api/llm.models" `
  -Method Post `
  -Body $body `
  -ContentType "application/json"
```

成功时，`llm.providers` 中会出现类似：

```text
provider: openai-codex
active: true
settingsNs: llm-pi-ai
settingsPath: [providers, openai-codex]
```

`llm.models` 中会出现一个 `openai-codex` 分组。模型名称以当前安装版本的 catalog 为准，不要把文档中的模型列表视为永久固定列表。

---

## 4. 路径二：把 Codex CLI 当作 Subagent 工具

### 4.1 原理

路径二不是把 Codex 当作 DSH 主模型，而是把本机 Codex CLI 包装成 DSH 的一个子代理 provider。

`@deepseek-ai/dsh-subagent-codex` 的核心流程是：

```text
主 Agent
   │
   │ 调用 subagent_codex
   ▼
DSH subagent provider: codex
   │
   │ 启动
   ▼
codex app-server --stdio
   │
   ├─ initialize
   ├─ thread/start，创建临时线程
   ├─ turn/start，提交一次独立任务
   └─ 返回最终答案
```

该 provider 的特点：

- 每次调用启动一个新的 Codex CLI app-server 进程。
- 使用父 Session 的工作目录。
- 创建临时 Codex thread。
- 只把独立文本任务传给 Codex。
- 只把最终答案返回给主 Agent。
- 不继承主 Agent 的完整对话、人格、模型上下文或工具目录。
- 子代理结束后，Codex 的中间过程不会完整复制到主 Session。

### 4.2 安装 Codex CLI

先确认本机已经安装 Codex CLI：

```powershell
codex --version
```

本次环境中验证到的版本是：

```text
codex-cli 0.147.0
```

Codex CLI 本身需要单独登录：

```powershell
codex login
```

Bundle 不负责安装 Codex CLI，也不负责登录或创建 Codex 账号。

### 4.3 安装 DSH Bundle

当前 DSH Web profile 是 `web`，目录为：

```text
<DSH_HOME>/profiles/web
```

安装命令：

```powershell
dsh plugin --profile web add @deepseek-ai/dsh-subagent-codex
```

也可以在 profile 目录直接执行：

```powershell
cd "<DSH_HOME>/profiles/web"
pnpm add @deepseek-ai/dsh-subagent-codex
```

安装后，包会出现在 profile 的依赖中，例如：

```json
{
  "dependencies": {
    "@deepseek-ai/dsh-subagent-codex": "0.0.1-rc.1"
  }
}
```

### 4.4 重要：安装依赖不等于加载 Provider

DSH Profile 的 `dsh.profile.bundles` 只接受声明了 `dsh.bundle` patch 的 Bundle。`@deepseek-ai/dsh-subagent-codex` 是一个 Cordis provider 插件，不应简单地加入 `dsh.profile.bundles`，否则可能出现：

```text
dsh: profile bundle ... declares no dsh.bundle in its package.json
```

正确做法是：

1. 将包安装到 profile 依赖。
2. 在 profile 的 `cordis.patch.yml` 中显式插入 provider 行。
3. 在 Agent preset 中启用对应工具行。

Provider 行示例：

```yaml
- insert:
    - id: subagent-codex
      name: '@deepseek-ai/dsh-subagent-codex'
      config:
        env: {}
```

当前 profile patch 文件：

```text
<DSH_HOME>/profiles/web\cordis.patch.yml
```

### 4.5 启用 Agent 工具

工具行的核心配置如下：

```yaml
- id: tool-subagent-codex
  name: '@deepseek-ai/dsh-tool-subagent'
  config:
    provider: codex
    toolName: subagent_codex
    backgroundMode: one-shot
    maxDepth: provider-managed
```

有些版本的插件 README 使用下面的字段表达同一类语义：

```yaml
- id: tool-subagent-codex
  name: '@deepseek-ai/dsh-tool-subagent'
  config:
    provider: codex
    toolName: subagent_codex
    enableRunInBackground: false
    maxDepth: provider-managed
```

应以当前安装版本随附的 Agent preset 模板为准，不要混用不同版本的配置字段。

### 4.6 为什么要创建自定义 preset

DSH 自带的 `standard`、`code`、`cordis` preset 通常都带有 Codex 工具模板，但默认是：

```yaml
disabled: true
```

这意味着：

- Provider 即使安装并注册了，也不会自动给 Agent 暴露工具。
- Host availability alone grants no tool。
- 需要复制一个 preset，并移除 Codex 工具行上的 `disabled: true`。

本次使用的自定义 preset：

```text
<DSH_HOME>/.agent-presets/code-codex
```

它基于内置 `code` preset，并把下面这行删掉：

```yaml
disabled: true
```

自定义 preset 的元数据示例：

```yaml
name: Code + Codex
description: Code Mode preset with OpenAI Codex CLI enabled as a subagent tool.
order: 3
```

然后把默认 preset 设置为：

```yaml
agent-presets:
  default: code-codex
```

该设置位于：

```text
<DSH_HOME>/settings.yaml
```

也可以在 profile patch 中覆盖：

```yaml
- id: agent-presets
  config:
    default: code-codex
```

### 4.7 路径二中模型由谁决定

路径二的 Codex 模型不是由 DSH 右下角模型选择器决定的。

调用关系是：

```text
DSH 主 Agent 模型
   │
   │ 决定是否调用 subagent_codex
   ▼
Codex CLI 子进程
   │
   │ 使用 Codex 自己的配置和登录状态
   ▼
Codex CLI 当前可用模型
```

因此：

- 右下角模型选择器仍然选择 DSH 主 Agent 的模型。
- Codex CLI 子代理使用自己的默认模型或 Codex CLI 配置中的模型。
- 两个模型上下文独立。
- 两边的 token 消耗、限额和账号状态也可能独立计算。

---

## 5. 两条路径能否同时使用

可以同时使用，而且互不冲突。

例如：

```text
右下角选择：openai-codex / 某个 Codex 模型
Agent preset：code-codex

主 Agent 直接使用路径一的 openai-codex
主 Agent 需要时再调用路径二的 subagent_codex
```

这时可能出现两层 Codex：

1. **路径一**：主 Agent 本身就是 `openai-codex` 路由。
2. **路径二**：主 Agent 再启动一个独立的 Codex CLI 子进程。

也可以反过来：

```text
右下角选择：DeepSeek、Sensenova 或其他普通模型
Agent preset：code-codex
```

此时主 Agent 使用普通模型，但仍然可以把代码任务委派给 Codex CLI。

常见使用方式如下：

| 目标 | 推荐配置 |
|---|---|
| 让整个主 Agent 使用 Codex | 路径一，右下角选择 `openai-codex` 模型 |
| 让主 Agent 偶尔调用 Codex 做独立任务 | 路径二，启用 `code-codex` preset |
| 两者都保留 | 路径一 + 路径二同时配置 |
| 主要使用 DeepSeek，遇到复杂代码再委派 Codex | 普通主模型 + 路径二 |

---

## 6. UI 中应该在哪里看到

### 6.1 路径一

刷新 Web 页面后，在右下角的模型选择器中应该看到：

```text
openai-codex
```

展开后能看到该运行时 catalog 提供的 Codex 模型。

如果看不到：

1. 确认 `settings.yaml` 已保存。
2. 确认 DSH 已重启，或等待 settings 动态生效。
3. 强制刷新浏览器：`Ctrl + F5`。
4. 通过 `POST /api/llm.providers` 查看 `openai-codex` 是否 `active: true`。
5. 通过 `POST /api/llm.models` 查看模型目录。

### 6.2 路径二

路径二不会出现在右下角模型下拉框中。

应该从以下位置验证：

1. **Settings → Agent Preset**：确认当前是 `code-codex`。
2. 新建 Session：Agent preset 通常对新 Session 最可靠。
3. 让 Agent 明确调用 Codex，例如：

   ```text
   请使用 Codex CLI 子代理检查当前项目结构，并返回检查结果。
   ```

4. 当子代理真正运行时，在 DSH 的 Subagent/子代理活动区域或会话事件中看到子代理活动。

---

## 7. 常见错误与原因

### 7.1 `no credential for provider route "openai-codex"`

典型错误：

```text
llm-pi-ai: no credential for provider route "openai-codex";
its profile resolves CODEX_OAUTH_TOKEN, which is not set
```

原因：

- `settings.yaml` 声明了 `apiKeyEnv: CODEX_OAUTH_TOKEN`。
- 但 DSH 进程和 credentials 服务都找不到这个引用对应的值。

处理：

1. 打开 DSH Web 的 Models/模型设置页面保存 `CODEX_OAUTH_TOKEN`。
2. 或通过 DSH credentials 服务写入该引用。
3. 不要把 token 直接写进 `settings.yaml`。
4. 如果只使用环境变量，设置后重启 DSH。

### 7.2 `patch: entry "tool-subagent-codex" not found`

原因：

- `tool-subagent-codex` 是 Agent preset 内部的工具行。
- 它不一定存在于 Web Host 的顶层 composition 中。
- 直接在 profile patch 里用同名 id 修改，可能找不到目标。

处理：

- 创建自定义 Agent preset，复制内置 preset 并移除 `disabled: true`。
- 或使用正确的 `insert` 语法插入顶层 host provider。
- 不要把 Host 层和 Agent 层混为一谈。

### 7.3 `profile bundle ... declares no dsh.bundle`

原因：

把 `@deepseek-ai/dsh-subagent-codex` 错误加入了：

```json
{
  "dsh": {
    "profile": {
      "bundles": [
        "@deepseek-ai/dsh-subagent-codex"
      ]
    }
  }
}
```

处理：

- 保留它在 `dependencies` 中。
- 不要把它作为没有 `dsh.bundle` 声明的 profile bundle。
- 在 `cordis.patch.yml` 中显式插入：

```yaml
- insert:
    - id: subagent-codex
      name: '@deepseek-ai/dsh-subagent-codex'
      config:
        env: {}
```

### 7.4 设置了环境变量但 DSH 仍然说未设置

Windows 进程的环境变量在创建时就会固化。常见情况是：

```text
注册表中的用户环境变量已经更新
但已经运行的 Harness/Node/PowerShell 进程仍然没有该变量
```

解决办法：

- 使用 credentials 服务，不依赖进程环境继承。
- 或完全停止并重新启动 DSH 以及启动它的父进程。
- 确认不要只在一个已经运行的旧 PowerShell 窗口里设置变量。

---

## 8. 安全注意事项

Codex OAuth token 等同于账号凭据，应按密码处理：

- 不要写入 Git 仓库。
- 不要写进 Markdown、日志或截图。
- 不要把完整 `auth.json` 发给别人。
- 不要在终端直接输出完整 token。
- 优先使用 DSH credentials 服务。
- token 失效后重新执行 `codex login`，再更新 DSH credentials。
- 如果怀疑泄露，应立即撤销/重新登录相关账号。

本文档只记录配置引用名 `CODEX_OAUTH_TOKEN`，不记录真实 token。

---

## 9. 当前环境的关键文件

```text
DSH Home:
<DSH_HOME>

Web Profile:
<DSH_HOME>/profiles/web

Profile manifest:
<DSH_HOME>/profiles/web\package.json

Profile patch:
<DSH_HOME>/profiles/web\cordis.patch.yml

DSH settings:
<DSH_HOME>/settings.yaml

Custom Agent preset:
<DSH_HOME>/.agent-presets/code-codex

Codex CLI credentials:
<USER_HOME>/.codex/auth.json

DSH credentials store:
<DSH_HOME>\.credentials.yaml
```

启动和重启：

```powershell
cd "<DSH_ROOT>"
.\stop-deepseek-harness.ps1
.\run-dsh.ps1 -Port 3080
```

访问地址：

```text
http://127.0.0.1:3080
```

---

## 10. 结论

- **路径一**把 Codex 当成 DSH 的主模型路由，能出现在右下角模型选择器中。
- **路径二**把 Codex CLI 当成 DSH 的子代理工具，不出现在模型选择器中，而由 Agent preset 暴露给主 Agent。
- 两者可以同时配置、同时使用。
- 路径一的关键是 `openai-codex` + `CODEX_OAUTH_TOKEN` + credentials 服务。
- 路径二的关键是安装 CLI、安装 DSH provider 包、显式挂载 `subagent-codex` provider，并在自定义 preset 中启用 `tool-subagent-codex`。
- 右下角模型决定主 Agent；Codex CLI 子代理的模型由 Codex CLI 自己决定。
