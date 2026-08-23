---
title: "将WorkBuddy内置模型塞进DeepSeek Harness"
date: 2026-08-23
description: "通过 OpenAI 兼容桥接进程把 WorkBuddy 内置 ACP 模型接入 DeepSeek Harness：确认真实模型清单、扩展 settings.yaml 配置、重启 Bridge、双重校验与实路调用测试，并附「新建会话均为计划模式」问题的排查与修复记录。"
tags:
  - DeepSeek Harness
  - WorkBuddy
  - AI Agent
  - 模型接入
draft: false
---

## 一、原理

DeepSeek Harness（以下简称 Harness）本身是一个 LLM 调度/路由外壳，它并不直接托管模型推理，而是通过**可插拔的 Provider + Bridge** 机制对接外部模型后端。WorkBuddy 内置大模型（Hy3、GLM 系列、MiniMax、Kimi、DeepSeek 等）则运行在 WorkBuddy 的 ACP（Agent Compute Platform）之上，对外暴露一个**兼容 OpenAI API 协议的本地服务端点**。

整体调用链路如下：

```
用户/Harness UI
   │  (模型选择：WorkBuddy 内置 ACP)
   ▼
Harness 配置 (settings.yaml)
   │  llm-pi-ai.providers['workbuddy-built-in']
   │  └─ models: [{id, name, contextWindow}, ...]
   ▼
workbuddy-acp-openai-bridge.cjs   ← 本机后台进程 (Node.js)
   │  监听 http://<bridge_host>:<bridge_port>/v1
   │  把 OpenAI 格式请求 → WorkBuddy ACP 协议
   │  把 ACP 响应 → OpenAI 格式 (chat/completions, models)
   ▼
WorkBuddy ACP 内置模型后端 (云端推理)
   └─ hy3, glm-5.2, minimax-m3, ...
```

**关键点：**
1. **协议适配**：Harness 只认 OpenAI 风格的 `/v1/chat/completions` 和 `/v1/models`；Bridge 负责把这套协议翻译成 WorkBuddy ACP 的鉴权与调用格式，再翻译回来。
2. **配置驱动模型清单**：`settings.yaml` 里 `workbuddy-built-in` provider 下的 `models` 数组，决定了 Harness 模型选择器里能看到的选项——**没列进去的模型即使 ACP 支持也选不到**。
3. **本地桥接进程**：Bridge 是一个常驻后台 job，监听本地端口；Harness 通过 `http://<bridge_host>:<bridge_port>` 访问它，由它代发到 ACP。
4. **上下文窗口**：每个模型在配置中声明 `contextWindow`（示例统一用了 `1048576`，即 1M token），供 Harness 做上下文裁剪与计费估算。

---

## 二、完整实施方案

### 阶段 0：确认 ACP 当前可用模型目录
在向配置里加模型前，必须先确认 WorkBuddy ACP 实际开放了哪些内置模型 ID，避免写入不存在的 ID 导致调用失败。

- 通过 ACP 目录接口或 Bridge 的 `/v1/models` 拉取真实清单。
- 实测得到的可用 ID：
  `hy3, hy3-x, glm-5.3, glm-5.2, glm-5.1, glm-5v-turbo, minimax-m3, kimi-k3-1, kimi-k2.7, kimi-k2.6, deepseek-v4-flash, deepseek-v4-pro`
- **原则**：只把 ACP 真实存在的模型写入配置；如当前 ACP 只提供 `minimax-m3`，就不要擅自加 `minimax-m2` 等未确认版本。

### 阶段 1：扩展 Harness 模型配置
编辑 `<DSH_HOME>\.dsh-home\settings.yaml`，在 `llm-pi-ai.providers['workbuddy-built-in'].models` 中插入新条目。

示例（在 `kimi-k3-1` 之前插入）：
```yaml
      models:
        - id: hy3
          name: Hy3（WorkBuddy 内置）
          contextWindow: 1048576
        - id: hy3-x
          name: Hy3-X（WorkBuddy 内置）
          contextWindow: 1048576
        - id: glm-5.3
          name: GLM-5.3（WorkBuddy 内置）
          contextWindow: 1048576
        - id: glm-5.2
          name: GLM-5.2（WorkBuddy 内置）
          contextWindow: 1048576
        - id: glm-5.1
          name: GLM-5.1（WorkBuddy 内置）
          contextWindow: 1048576
        - id: glm-5v-turbo
          name: GLM-5v-Turbo（WorkBuddy 内置）
          contextWindow: 1048576
        - id: minimax-m3
          name: MiniMax-M3（WorkBuddy 内置）
          contextWindow: 1048576
        - id: kimi-k3-1
          name: Kimi-K3（WorkBuddy 内置）
          contextWindow: 1048576
```
> 注意：配置文件位于工作区之外，普通 workspace-write 沙箱会拒绝写入，需要以"工作区外配置更新"为由提升权限后成功。

### 阶段 2：重启 Bridge 进程
配置变更需 Bridge 重新加载才能生效。

1. 杀掉旧 Bridge job：
   `job_kill(job_id="<旧job>", reason="Reload bridge ...")`
2. 确认已停止：`job_output(job_id="<旧job>", wait=true)` 看到 `killed`。
3. 启动新 Bridge（后台常驻，`--mode` 可省略，默认 `dontAsk`）：
   ```
   node <DSH_HOME>\workspaces\default\workbuddy-acp-openai-bridge.cjs
        --port <bridge_port>
        --workspace "<DSH_HOME>\workspaces\default"
        [--mode dontAsk|plan|default|acceptEdits|auto|bypassPermissions]
   ```
4. 验证监听：job 输出出现
   `WorkBuddy ACP OpenAI bridge listening at http://<bridge_host>:<bridge_port>/v1`

### 阶段 3：双重校验
**A. 校验 YAML 配置正确解析**
```js
const fs=require('fs');
const {parse}=require('.../profiles/node_modules/yaml');
const d=parse(fs.readFileSync('.../settings.yaml','utf8'));
const p=d['llm-pi-ai'].providers['workbuddy-built-in'];
console.log(p.models.map(x=>x.id).join(','));  // 应输出含新模型的清单
console.log('YAML OK');
```
**B. 校验 Bridge 实际暴露的模型与模式**
```powershell
$h=Invoke-RestMethod -Uri 'http://<bridge_host>:<bridge_port>/health'      # status/mode/models
$m=Invoke-RestMethod -Uri 'http://<bridge_host>:<bridge_port>/v1/models'   # $m.data.id -join ','
```
两份清单应一致，且都含 `hy3, hy3-x, glm-5.3, glm-5.2, glm-5.1, glm-5v-turbo, minimax-m3`。

### 阶段 4：实路调用测试
挑选代表模型做真实 `/v1/chat/completions` 调用（非仅列清单）：
```powershell
$body=@{model='glm-5.2';messages=@(@{role='user';content='请只回复：GLM OK'});stream=$false} | ConvertTo-Json -Depth 8
$r=Invoke-RestMethod -Uri 'http://<bridge_host>:<bridge_port>/v1/chat/completions' -Method Post -Body $body -ContentType 'application/json' -TimeoutSec 180
"model=$($r.model) reply=$($r.choices[0].message.content)"
```
预期：`model=glm-5.2 reply=...`，说明端到端链路通。

> 提示：经 PowerShell 发送含中文的提示词时偶发被替换为 `?`，验证类测试建议用英文提示词，或用 `[System.Text.Encoding]::UTF8.GetBytes()` 显式以 UTF-8 字节发送。

### 阶段 5：交付与收尾
- 更新任务清单（todo），标记"确认模型 ID / 加入配置 / 重启验证"为 completed。
- 告知用户：刷新 Harness 后，在 **WorkBuddy 内置模型（ACP）** 分类下即可选择新增模型。

---

## 三、关键注意事项（踩坑点）

| 项 | 说明 |
|---|---|
| **配置位置越界** | `settings.yaml` 在工作区外，需权限升级才能写；否则报 `sandbox: file access denied`。 |
| **清单一致性** | 配置里的 `models` 与 Bridge `/v1/models` 必须对齐，否则 Harness 选择器显示但调用 404。 |
| **不要臆造模型 ID** | 只加 ACP 实测存在的 ID；未开放的版本（如 `minimax-m2`）不要写。 |
| **Bridge 必须重启** | 改 YAML 不自动热加载，必须 kill + 重新拉起 Bridge job。 |
| **后台常驻** | Bridge 用后台方式启动，端口固定（默认 `<bridge_port>` 为 `17899`），需保证不被系统回收；`run-dsh.ps1` 已加入自启动与健康检查。 |
| **contextWindow 声明** | 影响 Harness 的上下文管理，按模型真实窗口填写，示例统一 1M 仅作占位。 |
| **会话权限模式** | 无头桥接无法应答 WorkBuddy 授权弹窗，可能弹窗的模式会导致请求挂起。默认 `dontAsk`（从不弹窗、放行安全只读操作、拒绝需审批操作）；纯只读分析可改回 `plan`。三种覆盖方式：启动参数 `--mode`、环境变量 `WORKBUDDY_ACP_MODE`、单次请求体字段 `workbuddy_mode`。 |

---

## 四、附：「新建会话均为计划模式」排查记录

**现象**：通过 Harness 走 WorkBuddy 内置模型时，新对话一律处于计划模式（模型自称 plan mode、只给方案不执行）。

**排查结论**：不是 WorkBuddy 的设置问题。

1. 直连 ACP 探测 `session/new`：原生返回 `currentModeId = "default"`（Always Ask），WorkBuddy 自身默认正常。
2. 根因在桥接器：`runAcp()` 中写死了
   `session/set_config_option { configId:'mode', value:'plan' }`。
   当初这样设计是因为无头桥接没人能应答授权弹窗，`default` 模式下模型一旦尝试执行命令就会挂起直到超时；`plan` 可避免挂起，但副作用是每次回复都自称计划模式。

**修复**：将模式改为可配置，默认 `dontAsk`：

- `set_config_option(dontAsk)` 返回值确认 `currentValue: "dontAsk"` 生效；
- 行为级验证（要求模型执行 `echo wb-mode-test`）：模型明确答复 *not analyze-only plan mode*，处于受限自动模式——不再以计划模式口吻回复；
- 模型自报模式名不可靠（曾把 `dontAsk` 会话自报为 "default"），验收应以配置返回值 + 行为测试为准。

> **文档占位约定**：`<DSH_HOME>` 表示 DeepSeek Harness 根目录；`<bridge_host>` 默认值为 `127.0.0.1`；`<bridge_port>` 默认值为 `17899`。文中不记录具体机器路径。
