---
title: "Palantir AIP 架构详解"
date: 2026-09-23
slug: "aip"
aliases:
  - "/posts/palantir-aip-architecture/"
  - "/posts/palantir-aip/"
description: "Palantir AIP、Foundry、Apollo 与 Ontology 的架构关系，涵盖安全治理、互操作性、智能体与模型生态。"
tags:
  - Palantir
  - AIP
  - Ontology
  - 企业 AI
draft: false
category: "知识领域"
toc: true
---

> 基于官方架构文档整理，重点呈现决策中心化设计与 Ontology 核心地位。

> 核对日期：2026-09-23。文中的产品状态与模型清单是官方公开文档及公告的时间点记录，具体可用性仍取决于 enrollment、区域与配置；“定位解读”“设计动机解读”属于作者分析。

[下载 PDF 版](/files/palantir-aip-architecture.pdf)

---

## 1. 整体平台架构

Palantir 标准架构由三大平台构成，共同形成企业操作系统。

```text
┌─────────────────────────────────────────────────────────────────┐
│                            Apollo                               │
│          持续交付 · 零信任基础设施 · Rubix 计算网格               │
└───────────────────────────────┬─────────────────────────────────┘
                                │
               ┌────────────────┴────────────────┐
               │                                 │
┌──────────────▼──────────────┐     ┌────────────▼─────────────┐
│          Foundry            │     │           AIP            │
│                             │     │                          │
│  · 数据连接与转换           │     │  · Secure LLM 接入       │
│  · 逻辑编写与模型           │     │  · 智能体生命周期        │
│  · 工作流与分析             │     │  · 人机协同应用          │
│                             │     │  · AIP Evals 评估        │
└──────────────┬──────────────┘     └────────────┬─────────────┘
               │                                 │
               └────────────────┬────────────────┘
                                │
                     ┌──────────▼──────────┐
                     │      Ontology       │
                     │    （决策中心核心）   │
                     └──────────┬──────────┘
                                │
                     ┌──────────▼──────────┐
                     │   人类 + AI 协同     │
                     │   运营决策与执行     │
                     └─────────────────────┘
```

**平台职责说明**

| 平台     | 核心职责                                                                 |
|----------|--------------------------------------------------------------------------|
| Apollo   | 持续交付、零信任基础设施、Rubix 计算网格管理                             |
| Foundry  | 数据连接与转换、逻辑编写、工作流与分析                                   |
| AIP      | Secure LLM 接入、智能体生命周期、人机协同应用、评估框架                  |
| Ontology | 决策中心，统一整合数据、逻辑、行动与安全                                 |

**官方能力分层**

官方将 AIP + Foundry 的能力进一步归纳为 **九大能力集**，由六个网格级组件横向支撑：

- **Ontology 系统**：Ontology Language + Ontology Engine + Ontology Toolchain
- **服务层**：Data Services（数据服务）+ Logic Services（逻辑服务）+ Workflow Services（工作流服务）
- **用户层**：Analytics & Applications（分析与应用）+ Automations（自动化）+ Product Delivery（产品交付工具链）
- **六网格组件**：Storage（存储）、Compute（计算）、Networking（网络）、Security（安全）、Governance（治理）、Workspace（工作空间）——全部由 Apollo 驱动

这是 **AIP + Foundry 整体架构**的九类能力视角；[AIP 架构专页](https://www.palantir.com/docs/foundry/architecture-center/aip-architecture)另以 12 类能力概括 AIP 的端到端架构，包括安全模型接入、上下文工程、可观测性、智能体生命周期和产品交付等。

官方对三平台关系的定位是 **"Enterprise Operating System"（企业操作系统）**：

- AIP + Foundry 运行在同一服务网格（service mesh）中；
- Apollo 负责编排数千次零停机升级。

---

## 2. Ontology 系统三层结构

Ontology 是整个架构的决策中心，并非简单语义层，而是完整的多模态系统。

官方原文直接印证了这一论断：

- 决策中心：*"The Ontology is the system at the heart of Palantir's architecture... models the complex, interconnected **decisions** of an enterprise, not simply the data"*。
- 非语义层：*"The Ontology is **not a 'semantic layer'**"*。
- 名词与动词：数据对象是"名词"（nouns），必须有"行动"（verbs）与之配对——语义必须与动力学（kinetics）结合，*"semantics must be paired with kinetics"*。

```text
┌─────────────────────────────────────────────────────────────────┐
│                     Ontology Language                           │
│                     （建模语言层）                               │
│  对象 Object Types · 链接 Link Types · 属性 Properties          │
│  行动 Action Types · 逻辑 Functions / 规则 / 模型               │
└───────────────────────────────┬─────────────────────────────────┘
                                │
┌───────────────────────────────▼─────────────────────────────────┐
│                      Ontology Engine                            │
│                      （执行引擎层）                               │
│  高规模读取（SQL / 实时订阅 / 物化）                             │
│  高规模写入（事务 / 批量 / 流式 / CDC）                          │
│  支持数十亿对象查询 · 数万级行动编排                             │
└───────────────────────────────┬─────────────────────────────────┘
                                │
┌───────────────────────────────▼─────────────────────────────────┐
│                    Ontology Toolchain                           │
│                    （工具链层）                                  │
│  Ontology SDK · Palantir MCP · 变更管理 · 开发接口              │
└─────────────────────────────────────────────────────────────────┘
```

**四要素横向支撑**

```text
Data（数据）  +  Logic（逻辑）  +  Action（行动）  +  Security（安全）
```

- **Data**：将异构数据源统一映射为业务对象、属性与链接。
- **Logic**：业务规则、机器学习模型、优化器及 LLM 驱动函数。
- **Action**：从简单事务到多步骤工作流，可写回运营与边缘系统。
- **Security**：角色、标记与用途的细粒度动态访问控制，对人类与智能体统一生效。

**决策图与学习回路**

- **decision graph（决策图）**：每条逻辑（简单规则或复杂编排）可连接到每个行动，把传统上碎片化的流程串成一张图。
- **continuous learning loops（持续学习回路）**：工作流中的每一条反馈都被安全地纳入学习回路，支撑从"增强"到"自动化"的演进。
- **cybernetic enterprise（控制论企业）**：官方原文对 Ontology 作为动态、复利式数字核心的定位。

---

## 3. 端到端决策闭环（受控人审场景示意）

```text
异构数据源
ERP / MES / CRM / 传感器 / 文档 / API
         │
         ▼
数据集成（批处理 · 流式 · CDC）
         │
         ▼
┌─────────────────────┐
│      Ontology       │
│ 对象 · 属性 · 链接  │
│ 规则 · 行动         │
└──────────┬──────────┘
           │
           ▼
上下文注入（结构化 + 非结构化 + 向量）
           │
           ▼
大语言模型（Secure LLM）
           │
           ▼
┌─────────────────────┐
│     AI 智能体        │
│ AIP Logic / Agent   │
└──────────┬──────────┘
           │
           ▼
提案 / 建议行动
           │
           ▼
人类审核 或 策略检查
           │
     ┌─────┴─────┐
     │           │
  通过         拒绝/修改
     │           │
     ▼           ▼
执行 Action    反馈回路
写回业务系统      │
     │           │
     └─────┬─────┘
           │
           ▼
可观测性与审计 → 按工作流设计记录反馈或回写 Ontology
```

**图示适用范围与设计原则**

- 这是需要人审的工作流示例：智能体可先生成建议，再按配置经授权审批或策略检查后执行；不能据此推断所有 AIP 智能体都默认走提案模式。
- 执行结果与反馈可按应用设计记录或回写 Ontology，用于评估和改进；回写与持续优化不是无需配置的自动保证。
- 平台提供执行追踪、可观测性与审计能力，具体覆盖范围取决于采用的组件及工作流配置。

**官方表述与产品化落地**

- **演进路径**：官方将这一演进概括为 *"journey from augmentation to automation"*（从增强到自动化的旅程）——渐进自动化是官方设计语言，而非事后解释。
- **AI FDE 的默认分支流程**：AI FDE 默认使用分支，在 Global Branch proposal（全局分支提案）或 Code Repository PR 中提交相应变更供审查；变更操作还受用户批准、权限与平台审计约束。这是 AI FDE 的产品行为，不应推广成所有 AIP 智能体的统一默认流程。
- **可观测性**：官方对应能力为 AIP observability，基于 Workflow Lineage 提供指标、执行历史、**分布式追踪（distributed tracing）**、日志与日志检索，覆盖智能体链式执行的全链路。

---

## 4. 安全与治理三层结构

```text
┌─────────────────────────────────────────────────────────────────┐
│                        企业层                                    │
│  企业身份提供商集成 · SIEM 对接 · 企业安全策略                   │
└───────────────────────────────┬─────────────────────────────────┘
                                │
┌───────────────────────────────▼─────────────────────────────────┐
│                        平台层                                    │
│  角色 / 标记 / 用途访问控制 · 完整血缘与审计日志                 │
│  人类与智能体统一权限范围                                        │
└───────────────────────────────┬─────────────────────────────────┘
                                │
┌───────────────────────────────▼─────────────────────────────────┐
│                      基础设施层                                  │
│  零信任（身份 / 设备验证） · 全链路加密 · 节点强制轮换           │
│  Rubix 网格隔离                                                  │
└─────────────────────────────────────────────────────────────────┘
```

平台级访问控制同时适用于人类用户与 AI 智能体；智能体实际权限由调用用户或项目的权限配置等条件决定。

**官方安全承诺与认证细节**

- **基础设施层**：Rubix 为加固版 Kubernetes。
  - **节点与容器轮换**：[Rubix 文档](https://www.palantir.com/docs/foundry/architecture-center/rubix)写明节点最长运行 48 小时；[MMDP 文档](https://www.palantir.com/docs/foundry/architecture-center/multimodal-data-plane)写明容器在 72 小时内销毁并轮换。两处约束的对象不同。
  - **认证相关能力**：Rubix 文档描述其特性可满足包括 **FedRAMP High、DoD DISA IL-5/IL-6、CMMC** 在内的严苛认证标准；特定部署的认证状态仍须按授权范围核实。
  - **部署范围**：跨 AWS / Azure / GCP / Oracle Cloud / 本地环境，行为一致。

- **AIP 接入的第三方托管模型服务的数据承诺**：官方对这一接入路径说明——
  - 提示词与输出**不被第三方留存、不用于再训练、供应商人员无法访问**（Palantir 与模型提供商签有合同与技术双重保证）；
  - 模型请求在可用且可行时路由到区域端点（US / UK / EU 等）；这一说明不自动覆盖所有客户自接入模型的处理方式。

- **服务商认证**：官方称，除非 AIP 合同另有明确约定，已接入的第三方托管模型服务商获得 ISO 27017、SOC 1/2/3、CSA STAR **和／或其他认证**；不应理解为每家服务商同时持有全部认证。

- **模型治理状态机**：模型系列在 Control Panel 中可处于 enabled / disabled / **disallowed** 状态。具体可用性取决于模型是否已集成、法律条款确认、AIP 功能启用、地理限制、必要的工程审查、面向具体 AIP 产品的接入进度，以及实验性模型的风险确认等条件。

- **地理分区示例**：模型可用性按 US / EU / UK / CA / AU / JP / KSA / **IL2 / IL4 / IL5（国防隔离区）** 分级。
  - 这是模型在不同 enrollment 中的可用性与治理约束，不能直接等同于 Ontology 的动态访问控制。

---

## 5. 简化总结视图

```text
┌─────────────────────────────────────────────────────────────────┐
│                         Apollo（底座）                           │
│               Rubix 网格 + 持续交付 + 零信任基础设施             │
└───────────────────────────────┬─────────────────────────────────┘
                                │
        ┌───────────────────────┴───────────────────────┐
        │                                               │
┌───────▼──────────────┐                   ┌────────────▼─────────────┐
│      Foundry         │                   │          AIP             │
│  数据 + 逻辑 + 工作流 │◄──── Ontology ────►│  LLM + 智能体 + 应用     │
└──────────────────────┘                   └──────────────────────────┘
                                │
                     ┌──────────▼──────────┐
                     │   人类 + AI 协同     │
                     │   运营决策与执行     │
                     └─────────────────────┘
```

当前官方架构中心对 MMDP 的概括：

> **"Any data, any compute, any model, anywhere"（任意数据、任意计算、任意模型、任意地点）**

该数据面理念由 **MMDP 多模态数据面**承载——详见下文第 7 节。

---

## 6. 核心设计要点总结

1. **决策中心化**：Ontology 是架构核心，编码企业知识、规则与允许的行动。
2. **LLM 角色定位**：大语言模型作为可替换的推理组件，在 Ontology 约束下运行。
3. **提案与反馈闭环**：在需要人审的路径中，智能体可生成提案，经授权审核后执行；反馈可按工作流设计记录或用于优化。
4. **统一安全治理**：人类与智能体遵循平台统一的权限控制与审计机制，实际授权范围依用户或项目配置而定。
5. **渐进自动化**：支持从人机协同增强，到受控自主执行的平滑过渡。

6. **开放数据面（MMDP）**：以 Apache Iceberg 开放格式、虚拟表与计算下推支持互操作；虚拟目录和虚拟表可使特定外部数据接入 Ontology 时免于重复复制。
7. **战略解读（作者判断）**：Palantir 强调数据、计算、模型及 Ontology 接口的互操作，同时仍将 Ontology 置于架构核心。商业护城河的判断需与官方技术事实区分。
8. **模型无关的工程保障**："LLM 可替换"不是口号，由 AIP Evals 评估框架（测试用例 + 评估函数 + 跨模型对比 + 方差分析）提供工程支撑。

---

## 7. MMDP 多模态数据面

MMDP（Multimodal Data Plane）是 Palantir 的开放数据与计算架构，哲学口号：

> **"Any data, any compute, any model, anywhere."**

### 开放数据架构

- 以 **Apache Iceberg** 为 Foundry / AIP 主表格式（AWS、GCP、Azure、Databricks、Snowflake 同为生态伙伴）。[2026-09-15 公告](https://www.palantir.com/docs/foundry/announcements/2026-09)宣布托管 Iceberg 表及 Palantir Iceberg REST catalog 在 AWS / Azure / GCP 托管的标准 Foundry 企业环境中 GA；这不等于所有部署环境均已启用。
- **Virtual Tables（虚拟表）**：Iceberg 目录可托管在 Palantir 内，也可注册 Databricks / Snowflake / BigQuery 等外部虚拟目录——Ontology 使用外部数据**无需复制**。
- 非表格数据（媒体、文档、流式、地理空间）同样开放：REST API + Python / TypeScript SDK 访问；导出任务与 Ontology webhook 同步到外部系统。

### 开放计算架构

- 内置运行时：Spark（批）、Flink（流）、DataFusion / Polars / DuckDB（单节点），全部跑在 Rubix 加固 Kubernetes 网格上。
- **Compute Modules（计算模块）**：BYO Compute——任何容器化资源（遗留可执行程序、专用模型、自定义引擎）可导入并在批/流/交互式函数中安全使用。
- **计算下推（pushdown compute）**：Pipeline Builder、Code Workspaces 可直接使用客户现有的 Databricks / Snowflake 计算资源。

### 开放模型架构

- **Model Catalog**：OpenAI、Anthropic、Google（Gemini）、Meta（Llama）、xAI（Grok）等最新模型，与客户自注册模型（微调、自有、遗留）同场竞技。
- 有趣细节：嵌入模型目录包含 **Snowflake Arctic Embed**——Palantir 与"竞争对手"的模型同目录提供。
- 模型访问可按用途精确治理（token 限额等）。

### 定位解读（作者判断）

从公开架构资料可以作如下解读：

- Palantir 强调数据、计算、模型的开放标准与互操作能力，但各功能仍有接入和部署条件；
- **Ontology** 仍是架构核心，同时其元素可通过 REST API、JSON 配置、OSDK 与 MCP 等接口连接外部系统；
- “护城河在决策中枢”属于商业分析，不是官方文档给出的技术边界。

---

## 8. 互操作性六大类

官方架构中心专设 Interoperability 章节，Palantir 与既有企业软件栈的互操作分为六类；Palantir MCP 被列在语义互操作之下：

| 互操作类型 | 关键机制 |
|---|---|
| **数据** | 原始格式存储（CSV / Iceberg / Parquet）；REST / JDBC / S3 接口；Virtual Tables 免复制接入 Databricks / Snowflake / BigQuery；HyperAuto 自动生成数据管道 |
| **元数据** | 血缘、标签、安全标记等全量元数据经 Platform SDK / REST 暴露，可对接外部数据目录与元数据管理工具 |
| **语义** | Ontology 元素（对象/链接/行动/函数）可经 REST API 访问并通过 JSON 驱动的方式配置，支持与外部语义建模工具双向同步；Palantir MCP 支持智能体驱动的语义互操作 |
| **代码与逻辑** | Python / Java / SparkSQL 等开放语言；Spark / Flink / DataFusion / Polars 开放运行时；ONNX 模型格式；Code Repositories 基于高可用 Git 服务 |
| **分析** | Power BI、Tableau、Jupyter、RStudio 官方连接器；Code Workspaces 原生嵌入 Jupyter / RStudio |
| **安全** | SAML 认证、Active Directory 授权；权限经 Ontology SDK 扩展至第三方应用 |

> 解读：Palantir 为互操作提供了具体机制；其对“封闭黑盒”印象的影响属于作者判断。

---

## 9. 智能体产品矩阵

截至 2026-09-23 的智能体与 AI 应用相关产品节选。表中状态来自官方文档或带日期的公告，不代表每个 enrollment 均已启用：

| 产品 | 定位 | 状态 |
|---|---|---|
| **AIP Chatbot Studio**（原 AIP Agent Studio） | 构建交互式助手（AIP Chatbots），可部署于平台内或经 OSDK / API 外部部署；内置企业数据与工具 | 原产品 2025-05 起 GA；2026-04 更名 |
| **AIP Logic** | 无代码 LLM 函数开发环境：块（Blocks）链式组合，可读写 Ontology；发布后经 Action 调用 | 稳定 |
| **AIP Evals** | 评估框架五件套：Evaluation suite / target function / evaluation function / test cases / metrics；支持跨模型对比与方差分析；已集成进 AI FDE | 稳定 |
| **AI FDE**（AI 驻场工程师） | 对话式操作 Foundry：建管道、改 Ontology、写函数、配置 Automate、建 OSDK 应用、审计权限 | **2026-03 宣布 GA**；Automate 工具于 2026-08 公告 |
| **AIP Evolve** | 协调多个 AI FDE 智能体，在指定目标、验证策略与变更约束下改进 AI 系统，提交结果和证据供审查 | **2026-09-08 宣布 GA** |
| **AIP Analyst** | 自然语言对 Ontology 做即席分析：搜索 → 对象集 → 聚合 → 可视化；可嵌入 Workshop / iframe | **2026-04 起 GA** |
| **AIP Assist** | 平台内 LLM 帮助助手；默认不读取用户正在处理的数据，可按管理员配置使用自定义内容源或 AIP Chatbots 模式 | 稳定 |
| **AIP Threads** | 拖拽文档即用的轻量 LLM 交互（无需技术配置） | 2024-10 宣布 beta；当前是否 GA 未核实 |
| **AIP Document Intelligence** | 比较文档提取策略的质量、速度和成本，并将策略部署到 Python transforms 或 functions | 应用 2026-02 宣布 GA；functions 部署 2026-07 宣布 GA |
| **Autopilot** | 通过看板、依赖图、自动化事件与对象追踪管理 Ontology 自动化工作流 | 2026-03 公告为 beta；现已有[官方文档](https://www.palantir.com/docs/foundry/autopilot/overview)，当前是否 GA 未见明确公告 |

### AI FDE 的四个设计要点（官方文档）

1. **"Context pollution" 治理**：初始状态仅加载最小上下文（不含用户数据），由用户拖拽扩权——最小权限原则在 LLM 时代的工程化。
2. **Closed-loop 操作模型**：执行 → 观察结果 → 反馈决定下一步；自带验证（transform preview、function preview、CI 检查）。
3. **默认分支提案**：AI FDE 默认使用分支，把相应改动提交为 Global Branch proposal 或 Code Repository PR 供审查；写入操作仍须符合权限与用户批准规则。
4. **模型支持**：Anthropic / OpenAI / Google / xAI，原生工具调用（native tool calling）。

### MCP 双轨制（重要）

| | **Palantir MCP**（构建者） | **Ontology MCP / OMCP**（消费者） |
|---|---|---|
| 使用者 | AI IDE / 智能体（Claude Code、VS Code Continue 等） | 外部 AI 客户端（Copilot Studio、Gemini Enterprise 等）；可用于 Teams 等工作环境中的智能体场景 |
| 能力 | 导航 Foundry 架构、搜 Ontology、**修改 ontology 类型**、预览/修复 transforms | 将 object types / action types / query functions 暴露为 MCP 工具，**读写 Ontology 数据** |
| 边界 | 可改类型，**不能写数据** | 经 application restrictions 限制智能体可触发的行动 |
| 生态 | — | **MCP Hub** 可发现/管理 OMCP 服务；官方文档以 Copilot Studio 智能体在 Microsoft Teams 中使用 Ontology 为示例，不等同于承诺所有 Teams 环境均有原生集成 |

> 作者解读：Ontology MCP 使外部 AI 平台能在配置的权限和 application restrictions 内读取 Ontology 数据、查询并执行预定义行动，“决策中心”由此可参与跨平台工作流。

---

## 10. 模型生态与治理

### 官方公开模型清单节选（核对日期：2026-09-23）

型号与可用区域变化很快；以下是 Palantir [Supported LLMs](https://www.palantir.com/docs/foundry/aip/supported-llms) 页面和近期公告中的节选，不表示每种型号在所有 enrollment、区域或 AIP 产品入口均可使用。

- **xAI**：Grok-3 / Grok-4 / Grok-4-Fast / Grok-Code-Fast-1；地理可用性表还列出 Grok 4.3 / 4.5 等型号。
- **OpenAI**：GPT-4o / GPT-4.1 / GPT-5 至 GPT-5.5 的若干具体型号，以及 GPT-5.6 Luna / Sol / Terra；**GPT-5.3 Codex** 应按全名记录，不能简写为“GPT-5.3 全系”。
- **Anthropic**：Claude 3.5 / 3.7 / 4 的若干具体型号、Claude Opus 4.8、Claude Sonnet 5、Claude Opus 5；不同模型与提供商通道的地理可用性不同。
- **Google**：Gemini 2.0 / 2.5、Gemini 3 Flash、Gemini 3.1 Pro、Gemini 3.5 Flash / Flash-Lite、Gemini 3.6 / 3.7 Flash。当前支持清单未列“Gemini 3.5 Pro”。
- **开源及开放权重**：Llama 3 / 3.1 / 3.3 / 4、Mistral / Mixtral、Gemma 4 的部分型号。
- **嵌入**：`ada` embedding、text-embedding-3 系、Snowflake Arctic Embed。
- **音频**：GPT Realtime 1.5 / 2.0（流式语音对话）、Whisper、GPT-4o Transcribe（含说话人分离 diarization）

**官方来源差异**：[2026-09-10 公告](https://www.palantir.com/docs/foundry/announcements/2026-09)宣布 Gemini 3.8 Flash 已在指定环境提供，但核对当日的 Supported LLMs 页面尚未列出 3.8。引用该型号时应注明公告日期、适用环境和清单尚未同步，不能默默合并为“全区域已支持”。

### 模型接入路径

除 Palantir 托管接入外，还有三条路径：

- **BYO Model（bring-your-own-model）**：接入企业自有模型（订阅、微调、领域模型）。
- **自托管模型（self-host）**：私有部署。
- **模型供应商兼容 API**。

另有 LLM 容量管理与速率限制治理。

### 术语考证

- **k-LLM**：官方平台概述页提及这一表述，[AIP Logic 文档](https://www.palantir.com/docs/foundry/logic/blocks)将其与在平台中使用可用的不同 LLM 联系起来。公开材料未给出可据此推断与 k-匿名有关的定义，因此不作词源或隐私机制推测。

- **轮换对象**：Rubix 页的 48 小时指节点，MMDP 页的 72 小时指容器；参见第 4 节。

---

## 11. 设计动机解读

以下是基于官方材料提出的作者分析，用于解释可能的设计动机；除特别指出的产品行为外，不应将动机判断视为 Palantir 官方结论：

1. **为什么决策必须中心化？**
   - 客户（国防、医疗、能源）需要的是可审计的 AI；
   - Ontology 把每个决策的数据、逻辑、行动、权限绑成可回溯整体，审计日志才能回答"这个订单为什么被拒"。

2. **为什么 LLM 必须可替换？**
   - **合规**：AIP 接入的第三方托管模型服务有不留存数据、不用于再训练的公开承诺，其他接入路径须分别核对；
   - **模型演进**：型号和可用性持续变化，见第 10 节的时间点记录；
   - **议价权**：多模型选择可能增强采购弹性，这是作者的商业推断；
   - **工程前提**：可用 AIP Evals 对候选模型运行测试用例、比较结果与方差，验证更换模型的实际影响。

3. **为什么在部分流程中使用提案模式？**
   - 官方原话 *"journey from augmentation to automation"*；
   - 渐进自动化可让审核、权限和验证随工作流风险调整；
   - AI FDE 的默认分支提案是一个产品化示例，但其他 AIP 工作流也可采用不同程度的自主执行。

4. **为什么强调互操作？**
   - 官方 MMDP 资料明确支持与现有数据湖、计算环境、模型和治理工具共存的混合架构；
   - Ontology 是架构核心，但其元素也可通过 REST API、JSON 配置、OSDK 与 MCP 等接口与外部系统连接；
   - 对“供应商锁定”或商业护城河的判断是作者解读，不能仅凭接口清单推出确定结论或“2026 年突然开放”的时间线。

---

## 12. 参考来源

**架构中心**

- 总览：https://palantir.com/docs/foundry/architecture-center/overview/
- Ontology 系统：https://palantir.com/docs/foundry/architecture-center/ontology-system/
- MMDP：https://palantir.com/docs/foundry/architecture-center/multimodal-data-plane/
- 互操作性：https://palantir.com/docs/foundry/architecture-center/interoperability/
- Rubix：https://palantir.com/docs/foundry/architecture-center/rubix/
- 三平台：https://palantir.com/docs/foundry/architecture-center/platforms/
- AIP 架构：https://palantir.com/docs/foundry/architecture-center/aip-architecture/

**AIP 文档**

- AIP 概览：https://palantir.com/docs/foundry/aip/overview/
- AIP 功能清单：https://palantir.com/docs/foundry/aip/aip-features/
- AIP 安全与隐私：https://palantir.com/docs/foundry/aip/aip-security/
- 支持模型清单：https://palantir.com/docs/foundry/aip/supported-llms/
- AIP Logic 核心概念：https://palantir.com/docs/foundry/logic/core-concepts/
- AIP Logic Blocks 与 k-LLM 表述：https://palantir.com/docs/foundry/logic/blocks/

**智能体与应用**

- AI FDE：https://palantir.com/docs/foundry/ai-fde/overview/
- AI FDE 安全与治理：https://palantir.com/docs/foundry/ai-fde/security-and-governance/
- AIP Evolve：https://palantir.com/docs/foundry/aip-evolve/overview/
- AIP Analyst：https://palantir.com/docs/foundry/aip-analyst/overview/
- AIP Chatbot Studio：https://palantir.com/docs/foundry/chatbot-studio/overview/
- AIP Document Intelligence：https://palantir.com/docs/foundry/document-intelligence/overview/
- AIP Evals：https://palantir.com/docs/foundry/aip-evals/overview/
- AIP Assist：https://palantir.com/docs/foundry/assist/overview/
- AIP Threads：https://palantir.com/docs/foundry/threads/overview/
- Autopilot：https://palantir.com/docs/foundry/autopilot/overview/
- Palantir MCP：https://palantir.com/docs/foundry/palantir-mcp/overview/
- Ontology MCP：https://palantir.com/docs/foundry/ontology-mcp/overview/
- Ontology MCP 使用示例：https://palantir.com/docs/foundry/ontology-mcp/example-mcp-workflows/

**动态**

- 2026 Release Notes：https://palantir.com/docs/foundry/announcements/release-notes/
- 2024-10 公告（AIP Threads beta）：https://palantir.com/docs/foundry/announcements/2024-10/
- 2025-04 公告（AIP Agent Studio GA 计划）：https://palantir.com/docs/foundry/announcements/2025-04/
- 2026-02 公告（AIP Document Intelligence GA）：https://palantir.com/docs/foundry/announcements/2026-02/
- 2026-03 公告（AI FDE、AIP Analyst、Autopilot）：https://palantir.com/docs/foundry/announcements/2026-03/
- 2026-07 公告（AIP Document Intelligence functions 部署）：https://palantir.com/docs/foundry/announcements/2026-07/
- 2026-08 公告（AI FDE Automate 工具）：https://palantir.com/docs/foundry/announcements/2026-08/
- 2026-09 公告（AIP Evolve、Iceberg、模型）：https://palantir.com/docs/foundry/announcements/2026-09/

---

*文档整理完成。内容基于 Palantir 官方架构说明重新组织，确保层级清晰、文字互不覆盖。*
