有，但**还没有一个像 Spec Kit 那样公认统一、且专门为 OpenCode 一次性任务设计的“标准框架”**。现在更接近的是几类方法，而不是一个统治性的单品。Spec Kit 本身明确强调的是**多阶段 refinement**，不是 one-shot；GitHub 也把它描述成 `/specify -> /plan -> /tasks` 的分阶段流程。([The GitHub Blog][1])

## 现在最接近你的几种东西

### 1）Task Master / task-pack 流

这是目前最接近“给 coding agent 一次性下发规范，再按任务跑”的做法。
Task Master 的核心不是交互 spec，而是先把 PRD 解析成 `tasks.json`，再给每个任务补上：

* `description`
* `dependencies`
* `details`
* `testStrategy`
* `subtasks`

然后 agent 按 task 执行、验证、改状态。这个模式本质上就是把“大 prompt”变成**可执行任务包**。([GitHub][2])

**适合你这个诉求的原因：**

* 不要求持续交互式 spec refinement
* 可以先离线把任务包写好
* 最终给 OpenCode 的其实是“下一任务 + 规则 + 验收”
  比纯 prompt 稳很多。([GitHub][2])

### 2）AGENTS.md / repo rules + 单任务 brief

这类不是“任务分解框架”，而是**稳定上下文框架**。
GitHub 2025 年后明显在推动 `agents.md`：给 agent 定义 persona、技术栈、目录结构、可执行命令、边界、示例输出。GitHub 对 2500+ 仓库的总结也指出，效果好的 `agents.md` 都有几个共同点：**明确职责、明确命令、明确边界、明确示例**。([The GitHub Blog][3])

这个模式通常搭配一个很短的单次任务 brief：

```md
Goal
Scope
Out of scope
Files likely touched
Acceptance criteria
Validation commands
```

它不是完整 spec 流，但对 OpenCode 这类 agent 很实用，因为 OpenCode 本身支持专门 agent，也建议用 plan agent 做只分析不改代码的工作流。([OpenCode][4])

### 3）Conductor / Context-Driven Development

这是最近和 OpenCode 生态最接近的“类 spec”方案。
Google 的 Conductor 提的是 **Context-Driven Development**：把 spec、plan、约束、上下文放进仓库里的 Markdown，而不是只放在聊天里；它的主张是 `Context -> Spec & Plan -> Implement`。Google 官方博客就是这么定义的。([Google Developers Blog][5])

更关键的是，**已经有人在做 OpenCode bridge / plugin**，把这套方法映射到 OpenCode 上；OpenCode 社区里也出现了专门的 conductor plugin 讨论。([GitHub][6])

但注意：
这套东西本质上还是**先成文上下文，再执行**，比 Spec Kit 更偏“持久上下文”，不完全是“纯一次性 prompt”。

### 4）Codex 式 execution pack

OpenAI 最近公开的 Codex 长任务实践，其实已经给出一个很像“非交互 spec”的包结构：

* `spec file`
* `plans.md`
* `implement.md`
* `documentation.md`
* 再配 tests / lint / typecheck / build 持续验证

OpenAI 直接把有效做法总结成：**clear target + constraints、milestones + acceptance criteria、runbook、continuous verification、audit log**。([OpenAI Developers][7])

这其实非常适合 OpenCode/Claude Code/Cursor 这种 coding agent。虽然它不是一个正式框架名，但已经很像一种**行业收敛出的任务包模式**。([OpenAI Developers][7])

---

## 结论

如果你问的是：

> “有没有一个像 Spec Kit 一样成体系，但更适合 OpenCode 这种一次性 coding task 的东西？”

答案是：

**有方向，没有统一标准。现在最像的是三条线：**

1. **Task Master 型**：把需求转成带依赖和验收的任务树
2. **AGENTS.md + task brief 型**：固定上下文 + 单次任务卡
3. **Conductor / Codex pack 型**：把 spec、plan、runbook、验证都落成文件，再一次性交给 agent 执行。([GitHub][2])

其中如果你是 **OpenCode + 一次性任务 + 想少交互**，我建议优先级是：

## 最实用的落地法

### A. 小中型任务：`AGENTS.md + Task Brief`

适合：

* 改一个模块
* 修一个 bug
* 加一个 endpoint
* 做一次重构

结构：

```md
# task.md

## Goal
## Scope
## Out of scope
## Constraints
## Files to inspect first
## Acceptance criteria
## Validation commands
## Output format
```

再配一个 repo 根目录的 `AGENTS.md`：

```md
- tech stack
- architecture
- code style
- forbidden actions
- commands to run
- test rules
- migration rules
```

这是成本最低、成功率最高的。

### B. 中大型任务：`Execution Pack`

适合：

* 一个完整 feature
* 跨多个目录
* 有状态迁移 / schema 改动
* 想让 agent 少来回问

建议 4 个文件：

```text
/specs/feature.md
/plans/feature-plan.md
/runbooks/implement-feature.md
/reports/feature-status.md
```

其中最关键的是：

* `feature.md` 只写 what/why/constraints
* `feature-plan.md` 写改哪些文件、怎么分步、风险点
* `implement-feature.md` 写 agent 的执行纪律
* `feature-status.md` 让 agent 记录已做/未做/失败原因

这其实就是把 Codex 的做法“产品化”到你的仓库里。([OpenAI Developers][7])

### C. 很大任务：`Task Master + Execution Pack`

这时不要 one-shot 直接做整个 feature。
先把 feature 拆成 task tree，再对“当前 task”生成 execution pack。这样比让 agent 吞一个大 spec 稳得多。Task Master 的依赖、details、testStrategy 正好就是这个入口。([GitHub][2])

---

## 你真正该避免的东西

### 1）只有 PRD，没有验收

没有 acceptance criteria，agent 会默认“写出来差不多就算完成”。
现在官方实践都在往**可验证结果**收敛：测试、lint、typecheck、build、rubric/evals。([OpenAI Developers][7])

### 2）只有大 prompt，没有 repo 级常驻规则

一次性 prompt 解决不了：

* 代码风格
* 边界约束
* 禁止修改区域
* build/test 命令
* monorepo 路由

这类内容应该常驻在 `AGENTS.md` 或仓库规则里。([The GitHub Blog][3])

### 3）把 spec 写得像人类文档，不写“执行字段”

给 agent 的规范，最好带这些字段：

* scope
* non-goals
* touched files
* invariants
* acceptance criteria
* verification commands
* rollback notes

否则它读得懂，但执行不稳。

---

## 最后一句

**业界现在没有一个“OpenCode one-shot spec framework”的唯一答案。**
但已经明显收敛到一句话：

> **轻量 spec + 强上下文 + 显式验收 + 可执行验证**

也就是：

* **Spec Kit 的意图定义**
* **AGENTS.md 的常驻规则**
* **Task Master 的任务分解**
* **Codex/Conductor 的执行包**

把这四个拼起来，基本就是当前最像“给 OpenCode 一次性任务规范”的成熟方法。([The GitHub Blog][1])

你要的话，我可以直接给你写一个 **OpenCode 专用的一次性任务规范模板**，做成：
**`AGENTS.md` + `task.md` + `plan.md` + `implement.md` 四件套**。

[1]: https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/ "Spec-driven development with AI: Get started with a new open source toolkit - The GitHub Blog"
[2]: https://github.com/eyaltoledano/claude-task-master/blob/main/README-task-master.md "claude-task-master/README-task-master.md at main · eyaltoledano/claude-task-master · GitHub"
[3]: https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/ "How to write a great agents.md: Lessons from over 2,500 repositories - The GitHub Blog"
[4]: https://opencode.ai/docs/agents/?utm_source=chatgpt.com "Agents"
[5]: https://developers.googleblog.com/conductor-introducing-context-driven-development-for-gemini-cli/?utm_source=chatgpt.com "Conductor: Introducing context-driven development ..."
[6]: https://github.com/anomalyco/opencode/pull/7105?utm_source=chatgpt.com "Add opencode-conductor-plugin to ecosystem page#7105"
[7]: https://developers.openai.com/blog/run-long-horizon-tasks-with-codex/ "Run long horizon tasks with Codex"
