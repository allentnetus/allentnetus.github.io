---
type: 知识领域
Status: Active
URL: "https://github.com/earendil-works/pi/"
date: 2026-08-19
---

## 1. 定位

Pi可以简单理解为：**一个比 Claude Code、Codex CLI 更"底层、更可改造"的编码智能体框架**。**一个极简、模型无关、可编程的 Agent Harness，同时附带一个成熟的 Terminal Coding Agent。**

核心结构大致分三层：pi-ai 负责统一接入 OpenAI、Anthropic、Google 等模型；pi-agent-core 负责 Agent Loop、工具调用和状态管理；pi-coding-agent 则提供终端里的交互式 Coding Agent。[GitHub](https://github.com/earendil-works/pi?utm_source=chatgpt.com)

它比较有特点的地方是：

- **极简 Agent Loop**：核心主要围绕读取、写入、编辑文件和执行 Shell，而不是内置大量复杂编排。
- **模型自由度很高**：除了 OpenAI、Anthropic、Google，也可以通过 models.json 接 Ollama、LM Studio、vLLM、OpenAI-compatible API 等。[GitHub](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/models.md?utm_source=chatgpt.com)
- **支持 AGENTS.md / CLAUDE.md**：可以像 Codex CLI、Claude Code 一样给项目配置长期指令。[Pi开发](https://pi.dev/?utm_source=chatgpt.com)
- **扩展能力强**：支持 Extensions、Skills、自定义工具、Prompt、SDK，甚至可以让一个 Pi Agent 调用另一个 Agent。[GitHub](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/sdk.md?utm_source=chatgpt.com)
- **可以作为 Agent Harness 使用**：也就是说你不一定把 Pi 当成最终产品，而是把它当作自己的 Coding Agent、企业 Agent 或多 Agent 系统的运行底座。
- 目前已经形成了扩展生态，例如 Web 搜索、URL 抓取、GitHub、PDF、YouTube 等能力都可以通过 package/extension 增加。[Pi开发](https://pi.dev/packages?utm_source=chatgpt.com)

和你之前用过的几个工具放在一起理解，会比较直观：

| 工具 | 定位 | 可定制性 | 开箱即用 |
| --- | --- | --- | --- |
| **Claude Code** | 完整 Coding Agent | 中高 | 很高 |
| **Codex CLI** | OpenAI Coding Agent | 高 | 很高 |
| **DeepSeek Harness** | Agent Harness / Coding Agent | 高 | 中高 |
| **Pi Agent** | 极简 Agent Harness + Coding Agent | **很高** | 中 |
| **OpenClaw** | 长时间运行的个人/通用 Agent | 高 | 中 |

**Pi Agent 更适合"自己搭 Agent"而不是单纯"找 AI 帮我写代码"。** 如果只是写代码，Claude Code/Codex CLI 更省事；如果你想研究 Agent Harness、Skill、Memory、Tool Calling、多模型切换、子 Agent，以及打造自己的 Coding Agent，Pi 很值得研究。

另外，它和 OpenClaw 之间也有比较强的关系：Pi 的极简 Agent 架构可以作为这类长期运行 Agent 系统的底层执行 Agent，有开发者专门讨论过 Pi 在 OpenClaw 体系中的使用方式。[Armin Ronacher's Thoughts and Writings](https://lucumr.pocoo.org/2026/1/31/pi/?utm_source=chatgpt.com)

如果你目前是在研究 **DeepSeek Harness、Hermes、Codex CLI、Tolaria** 这一类工具，那么我建议下一步直接做一份：

**Pi Agent vs DeepSeek Harness vs Hermes Agent vs Codex CLI vs Claude Code 的架构、功能、扩展机制、Skills、MCP、Memory、模型支持和本地部署对比。**

这样最容易判断 Pi Agent 值不值得装。

它最大的价值不是"内置功能最多"，而是：

**你可以把 Pi 改造成自己的 Codex / Claude Code / DeepSeek Harness / 企业 Agent Runtime。**

## 2. Pi 的整体架构

官方 monorepo 实际上分成几层：[GitHub](https://github.com/earendil-works/pi)

```text
┌─────────────────────────────────────┐
│            你的应用 / IDE           │
│        CLI / Web / Desktop / CI     │
└──────────────────┬──────────────────┘
                   │
          SDK / RPC / JSON Stream
                   │
┌──────────────────▼──────────────────┐
│     @earendil-works/pi-coding-agent │
│                                     │
│ TUI / Session / Context / Skills    │
│ Extensions / Tools / Packages       │
└──────────────────┬──────────────────┘
                   │
┌──────────────────▼──────────────────┐
│      @earendil-works/pi-agent-core  │
│                                     │
│ Agent Loop                          │
│ Tool Calling                        │
│ State                               │
│ Events                              │
│ Steering / Follow-up                │
└──────────────────┬──────────────────┘
                   │
┌──────────────────▼──────────────────┐
│          @earendil-works/pi-ai      │
│                                     │
│ OpenAI / Claude / Gemini / DeepSeek │
│ OpenRouter / Kimi / Local Model...  │
└─────────────────────────────────────┘
```

此外还有：

```text
pi-tui
   ↓
Terminal UI
pi-telemetry
   ↓
Tracing / Telemetry
Extensions
Skills
Prompt Templates
Themes
Pi Packages
   ↓
扩展整个 Harness
```

这其实是 Pi 和很多 Coding Agent 最大的差异。

**Codex CLI / Claude Code 首先是"产品"；Pi 首先是"Agent Runtime + Harness"。**

## 3. Agent Loop 是怎么工作的

Pi 的核心非常简单。

官方 pi-agent-core 明确暴露了底层：

agentLoop()

agentLoopContinue()

Agent

AgentTool

AgentContext

典型过程：

```text
User
 │
 ▼
Prompt
 │
 ▼
LLM
 │
 ├── 普通文本 ─────────→ 返回用户
 │
 └── Tool Call
        │
        ▼
   Tool Execution
        │
        ▼
   Tool Result
        │
        ▼
       LLM
        │
       ...
```

实际上对应的内部事件大概是：

```text
agent\_start
    ↓
turn\_start
    ↓
message\_start
    ↓
LLM streaming
    ↓
message\_end
    ↓
tool\_execution\_start
    ↓
tool\_execution\_update
    ↓
tool\_execution\_end
    ↓
toolResult
    ↓
turn\_end
    ↓
下一轮 LLM
    ↓
agent\_end
```

这套 Event 模型非常重要，因为 Extension 可以插入：

```text
LLM 调用前
LLM 调用后
Tool 调用前
Tool 调用后
Session 切换
Compaction
用户输入
模型切换
```

所以实际上可以实现：

```text
权限系统
审计
Sandbox
Hook
Memory
Todo
Plan Mode
Sub Agent
MCP
Browser
Git checkpoint
CI Agent
```

而不需要改 Pi Core。

## 4. 默认工具极其克制

Pi 默认真正交给模型的核心工具只有：

```text
read
write
edit
bash
```

官方 Quickstart 就明确这么设计。[GitHub](https://github.com/badlogic/pi-mono/tree/main/packages/coding-agent)

另外存在一些可选只读工具能力，比如：

```text
grep
find
ls
```

最新 v0.84.2 还增加了：

```text
defaultTools
```

因此现在可以针对不同项目配置默认启用哪些工具。[GitHub](https://github.com/earendil-works/pi/releases?utm_source=chatgpt.com)

这也是 Pi 哲学的核心：

不把几十个 Tool 全部塞进 Agent Context。

这对减少 Tool Schema 占用、降低模型选择错误和 Context Pollution 很有价值。

## 5. Extensions 是 Pi 最强的部分

如果只研究一个 Pi 特性，我认为应该重点研究 **Extension System**。

Extension 本质上是：

**TypeScript 模块 + Agent 生命周期事件 + Tool 注册 + UI API。**

它能够：[Pi开发](https://pi.dev/docs/latest/extensions?utm_source=chatgpt.com)

| 能力 | Extension 可以做什么 |
| --- | --- |
| Tool | 注册新的 LLM Tool |
| Hook | 拦截 Tool 调用 |
| Event | 监听 Agent 生命周期 |
| Context | 动态注入上下文 |
| Permission | 阻止危险命令 |
| UI | 创建 Terminal UI |
| Command | 添加 /xxx |
| Session | 写入持久状态 |
| Provider | 添加新模型 Provider |
| Compaction | 自定义上下文压缩 |
| Tool Set | 动态开关 Tool |

例如：

pi.registerTool(...)

可以直接增加：

```text
browser
database
jira
notion
ssh
docker
knowledge\_base
```

而：

pi.on("tool\_call", ...)

则可以实现：

```text
rm -rf → 拦截
sudo → 请求确认
.env → 禁止修改
生产数据库 → 禁止访问
```

这已经接近一个 **Agent Middleware / Agent OS Hook System**。

## 6. Skills

Pi Skills 和 Claude Code / Codex Skills 思路高度接近。

目录：

```text
my-skill/
├── SKILL.md
├── scripts/
├── references/
└── assets/
```

Pi 启动时只加载：

```text
name
description
```

真正需要 Skill 时，再读取完整 SKILL.md。

也就是典型：

Progressive Disclosure

避免几百个 Skill 全部进入 Context。[Pi开发](https://pi.dev/docs/latest/skills?utm_source=chatgpt.com)

更重要的是：

**Pi 可以直接复用 Claude Code 和 Codex Skills。**

例如：

```text
{
  "skills": [
    "~/.claude/skills",
    "~/.codex/skills"
  ]
}
```

这一点非常适合搭建统一 Agent Skill Library。

---

## 7. Context / AGENTS.md

Pi 支持：

```text
~/.pi/agent/AGENTS.md
项目/
   AGENTS.md
项目/
   CLAUDE.md
AGENTS.override.md
```

加载逻辑会从当前目录向父目录查找。[Pi开发](https://pi.dev/docs/latest/usage?utm_source=chatgpt.com)

因此可以形成：

```text
全局规则
   ↓
公司规则
   ↓
项目规则
   ↓
目录规则
```

这和现在 Codex 的：

AGENTS.md

AGENTS.override.md

设计已经非常接近。Codex 当前同样支持层级式 AGENTS.md。[OpenAI Developers](https://developers.openai.com/codex/agent-configuration/agents-md?utm_source=chatgpt.com)

## 8. Session 设计其实很漂亮

Pi Session 不是简单 Chat History。

它采用：

JSONL

+

Tree

每条记录具有：

id

parentId

因此一场对话实际上可以变成：

```text
            Prompt A
               │
          Response A
               │
          ┌────┴────┐
          │         │
       Branch B   Branch C
          │         │
       Result B   Result C
```

对应命令：

```text
/tree
/fork
/clone
/resume
/session
```

所以 Pi 天生支持：

**同一个 Agent Session 内尝试多个方案，而不用丢掉之前的推理路径。**

这个设计比单纯的线性 Chat History 更适合 Coding Agent。

## 9. Context Compaction

Pi 在上下文接近模型限制时，会自动压缩历史。

默认逻辑是：

```text
contextTokens
>
contextWindow - reserveTokens
默认：
reserveTokens = 16384
keepRecentTokens ≈ 20000
```

摘要结构也不是简单一句话，而是类似：

```text
Goal
Constraints & Preferences
Progress
  Done
  In Progress
  Blocked
Key Decisions
Next Steps
```

并且继续追踪：

读过哪些文件

修改过哪些文件

所以更接近：

**Agent State Compression**

而不是普通聊天摘要。

## 10. Memory 要特别区分

Pi **原生有 Session Memory，但没有 Claude Code 那种完整 Auto Memory。**

原生提供：

```text
AGENTS.md
Session JSONL
Branch
Compaction
Custom Session State
```

但没有内建：

```text
Semantic Long-term Memory
Vector Memory
Automatic User Preference Memory
Knowledge Graph Memory
```

生态里已经出现不少扩展，例如：

```text
pi-memory
pi-hermes-memory
Remnic
red-skills-memory
```

其中 pi-hermes-memory 甚至直接移植了 Hermes Agent 的一套 Persistent Memory 思路。[Pi开发](https://pi.dev/packages)

所以 Pi 的逻辑仍然是：

```text
Memory ≠ Core
Memory = Extension
```

## 11. 模型支持是 Pi 的巨大优势

这一点明显强于绑定单一模型厂商的 Coding Agent。

目前官方支持订阅登录：

| 登录方式 | 支持 |
| --- | --- |
| ChatGPT Plus / Pro | ✅ Codex |
| Claude Pro / Max | ✅ |
| GitHub Copilot | ✅ |
| xAI | ✅ |
| OpenRouter | ✅ |
| Radius | ✅ |

API Provider 更广，包括：

```text
OpenAI
Anthropic
DeepSeek
Gemini
Vertex AI
Azure OpenAI
Amazon Bedrock
Mistral
Groq
Cerebras
NVIDIA NIM
OpenRouter
Together AI
Fireworks
Kimi
MiniMax
Qwen
Xiaomi MiMo
Cloudflare
...
```

本地模型还支持：

```text
llama.cpp
Ollama
LM Studio
vLLM
OpenAI-compatible API
```

所以你完全可以建立：

Pi

 │

 ├─ GPT

 ├─ Claude

 ├─ Gemini

 ├─ DeepSeek

 ├─ Kimi

 ├─ Qwen

 └─ Local LLM

然后同一套：

Skills

Tools

Memory

Agent Workflow

不用跟模型厂商绑定。

## 12. MCP：一个非常容易误解的地方

**Pi Core 故意没有内建 MCP。**

官方甚至直接写：

No MCP.

理由不是 Pi 不能用 MCP，而是官方更倾向：

```text
CLI + README + Skill
或者：
Extension → MCP
```

因此结构是：

Pi

 │

 └─ Extension

       │

       └─ MCP Client

              │

              ├─ GitHub MCP

              ├─ Notion MCP

              └─ Database MCP

而 Claude Code 则把 MCP 当一等能力直接内置。[Claude Platform Docs](https://docs.anthropic.com/en/docs/claude-code/mcp?utm_source=chatgpt.com)

这是两种明显不同的产品哲学。

## 13. Sub-Agent 也是一样

Pi 官方：

No built-in sub-agents

但生态已经有：

@tintinweb/pi-subagents

以及：

pi-dynamic-workflows

pi-background-tasks

piolium

所以可以形成：

```text
Main Pi
   │
   ├─ Research Agent
   ├─ Coding Agent
   ├─ Review Agent
   ├─ Test Agent
   └─ Security Agent
```

只是 orchestration 不由官方替你决定。

## 14. SDK / RPC 非常重要

Pi 不只是 CLI。

官方直接提供：

```text
SDK
RPC
JSON Event Stream
```

SDK 可以：

createAgentSession()

然后把 Pi 嵌进：

```text
Web App
Desktop
IDE
CI/CD
企业系统
自动化 Workflow
Multi-Agent
```

所以从产品架构来看：

```text
Pi CLI
只是 Pi Runtime 的一个客户端。
```

这也是为什么我更愿意称它：

**Agent Harness SDK**

而不是单纯 Coding CLI。

## 15. Pi 最大的问题：安全边界

这是研究 Pi 时必须重点关注的地方。

官方明确说明：

**Pi 默认没有内置 Sandbox，也没有完整的 Permission System。**

Pi 进程有什么权限：

Agent 就有什么权限

也就是说默认：

```text
Filesystem
Shell
Network
Credentials
Environment
```

都继承当前用户权限。[GitHub](https://github.com/earendil-works/pi)

而所谓：

```text
Project Trust
主要防止未经允许加载：
.pi/settings.json
Extensions
Skills
Project packages
```

**它不是 Sandbox。**

官方也明确指出，Project Trust 无法消除：

```text
Prompt Injection
恶意 README
恶意代码注释
恶意 Build Output
```

因此生产环境使用 Pi，比较合理的架构应该是：

```text
             Pi
              │
       Permission Extension
              │
          Sandbox
       ┌──────┼──────┐
       │      │      │
     Docker  VM   OpenShell
```

官方目前推荐 Gondolin、Docker 或 OpenShell 等隔离方案。[GitHub](https://github.com/earendil-works/pi)

## 16. 和 Codex CLI、Claude Code 的本质区别

| 维度 | Pi | Codex CLI | Claude Code |
| --- | --- | --- | --- |
| 核心定位 | **Agent Harness** | Coding Agent | Coding Agent |
| 模型 | **多模型** | OpenAI | Claude |
| Agent Loop | **公开可编程** | 产品内部 | 产品内部 |
| Extensions | **极强** | 强 | 强 |
| Skills | ✅ | ✅ | ✅ |
| MCP | Extension | ✅ | ✅ |
| Sub-agent | Extension | ✅ | ✅ |
| Plan Mode | Extension | 有相关能力 | ✅ |
| Auto Memory | Extension | 相对有限 | **✅** |
| AGENTS/规则 | ✅ | ✅ | CLAUDE.md |
| Sandbox | 外部 | **内置** | 权限系统 |
| SDK Embedding | **强** | 有 SDK/Server 能力 | SDK/CLI |
| Provider 自由度 | **极高** | 低 | 低 |
| 自己造 Agent | **非常适合** | 中 | 中 |
| 开箱即用 | 中 | **高** | **高** |

Codex 当前已经拥有操作系统级 Sandbox/Approval，以及 Subagent 等原生能力；Claude Code 则已经把 MCP、Subagent、Hooks、Skills 和 Auto Memory 做成完整产品能力。[OpenAI Developers](https://developers.openai.com/codex/agent-approvals-security?utm_source=chatgpt.com)

所以：

```text
Claude Code
    ↓
最好用的完整产品之一
```

```text
Codex CLI
    ↓
OpenAI 体系的完整 Coding Agent
```

```text
Pi
    ↓
最好改造的 Agent Harness 之一
```

## 17. 为什么 Pi 最近值得重点关注

从近期迭代速度也能看出来，Pi 已经明显从"小众 CLI"向 **通用 Agent Runtime** 发展。

例如最近几个版本先后增加：

```text
llama.cpp 本地模型管理
Provider Extension
Constrained Tool Sampling
OpenRouter Login
Kimi
Qwen
Fullscreen TUI
AGENTS.override.md
动态 Tool Loading
defaultTools
RPC / SDK 能力增强
```

最新 v0.84.2 还继续加强 Tool Schema、TUI、Provider 和 Extension 能力。[GitHub](https://github.com/earendil-works/pi/releases?utm_source=chatgpt.com)

说明它现在竞争的已经不只是：

```text
Claude Code
Codex
```

更是在往：

```text
Agent Runtime
Agent SDK
Agent Harness
Agent Platform Foundation
发展。
```

## 18. 从你的使用场景看，Pi 最值得研究什么

如果目标只是：

让 AI 帮我改代码

优先：

**Codex CLI / Claude Code。**

但如果目标是研究和搭建：

```text
自己的 Agent Harness
多模型 Agent
统一 Skills
Memory
Tool Calling
Browser Agent
Sub-Agent
MCP
长期运行 Agent
企业 Agent
DeepSeek / Qwen / Kimi Agent
```

那么：

**Pi 的研究价值非常高。**

尤其是这条技术路线：

```text
                    Pi
                     │
             ┌───────┴───────┐
             │               │
           Skills        Extensions
             │               │
        ┌────┴────┐     ┌────┴────┐
      Coding   Research Browser   MCP
                     │
                  Memory
                     │
              pi-hermes-memory
                     │
                 Subagents
                     │
               Multi-Agent
                     │
                 Sandbox
```

这实际上已经可以构成一个完整的 **个人 Agent / 企业 Agent Harness**。

结合你最近在看的 **DeepSeek Harness、Hermes、Codex CLI、Tolaria**，我的判断是：**Pi 非常值得实际安装测试，而且不应只把它当 Coding Agent 测，而应该把它作为"可自定义 Harness 底座"来测。** [Pi开发](https://pi.dev/docs/latest/extensions?utm_source=chatgpt.com)

下一步最有价值的是直接做一轮实测：**在 Windows 上安装 Pi → 接 ChatGPT/Codex → 接 DeepSeek → 配 AGENTS.md → 复用 Codex Skills → 加 Memory → 加 Sub-agent → 测 MCP → 与你现在的 Hermes / DeepSeek Harness 做同任务对比。**这样才能真正判断它能不能替代你现在在用的 Harness。
