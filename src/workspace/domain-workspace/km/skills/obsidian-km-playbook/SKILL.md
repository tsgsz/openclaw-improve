---
name: obsidian-km-playbook
description: 执行型技能（Runner）：obsidian-km-playbook
---

> 运行说明：本技能为执行型技能，按当前 Runner 架构使用。

# Obsidian 知识管理手册（obsidian-km-playbook）

## 目标与适用场景

将 Obsidian 知识库从“随手记”升级为“可持续演进的知识系统”，适用于：
- 个人知识管理（学习、写作、项目跟进）
- 团队轻协作（Markdown + Git）
- 需要兼顾桌面/移动端、同步与备份的场景

核心原则：
1. **文件优先**：笔记是本地 Markdown 文件，不绑死工具。
2. **链接优先**：优先双链与 MOC，目录只是最小骨架。
3. **增量治理**：先可用，再精细；每周小步维护。

---

## 一键执行步骤（应用到 `~/workspace/KnowledgeBase`）

```bash
bash ~/.openclaw/workspace/skill-catalog/project/obsidian-km-playbook/scripts/apply.sh ~/workspace/KnowledgeBase
```

执行后将：
- 创建基础目录结构（仅增量，不覆盖已有内容）
- 初始化 MOC 与模板文件（仅在文件不存在时创建）

---

## 文件结构模板

建议结构（PARA + Inbox + MOC + 模板）：

```text
知识库/
  00-Inbox/          # 捕获入口（24-72小时内清理）
  01-MOC/            # 内容地图（Map of Content）
  02-Notes/          # 永久笔记/主题笔记
  03-Projects/       # 有截止时间的项目
  04-Areas/          # 持续责任域（健康/财务/家庭/职业）
  05-Resources/      # 参考资料（书/文章/方法/术语）
  06-Archives/       # 完成/冷却材料
  07-Templates/      # 模板（笔记/日报/周复盘）
  08-Attachments/    # 附件（图片/音视频/PDF）
```

---

## 命名规范与链接规范

### 1) 文件命名
- 统一：`YYYY-MM-DD-标题`（时间敏感类）或 `主题-限定词`（长期笔记）
- 避免特殊字符：`# | ^ : %` 等
- 示例：
  - `2026-02-14-阅读-Obsidian同步策略.md`
  - `MOC-知识管理.md`
  - `项目-知识库重构-v1.md`

### 2) 链接规范
- 优先使用 `[[双链]]`，保持低摩擦链接。
- 一条笔记至少 1 个上游链接 + 1 个下游链接。
- MOC 只做“导航与语义分组”，不复制正文。

### 3) 标签规范
- 标签用于“状态/流程/横切面”，不替代目录与双链。
- 推荐层级：
  - `status/inbox` `status/draft` `status/evergreen`
  - `topic/km` `topic/obsidian`
  - `review/weekly`
- 每篇笔记控制在 2-5 个标签。

---

## 模板与周期笔记

最小模板集：
- `TPL-永久笔记.md`
- `TPL-每日笔记.md`
- `TPL-每周复盘.md`

建议核心插件：
- Daily notes
- Templates
- Backlinks
- Tag pane / Tags view
- Search

社区插件最小集（可选，少而精）：
- Obsidian Git（自动提交备份）
- Dataview（仅在确有查询需求时启用）

---

## Inbox 到归档流程（可执行）

1. **捕获**：所有临时内容先进 `00-Inbox`。
2. **澄清**（每日 10 分钟）：
   - 可行动 → `03-Projects`/任务系统
   - 可沉淀 → `02-Notes` 并补链接
   - 纯资料 → `05-Resources`
   - 无价值 → 删除
3. **组织**：补充最小元数据（type/status/tags/created/updated）。
4. **连接**：至少关联 1 个 MOC 与 2 条双链。
5. **归档**：项目完成后移入 `06-Archives`，在 MOC 保留入口。

---

## 每周维护清单

- [ ] 清空 `00-Inbox`（剩余项 <= 10）
- [ ] 更新 1-3 个核心 MOC
- [ ] 修复孤儿笔记（无反链/无出链）
- [ ] 处理附件：重命名、去重、迁移到 `08-Attachments`
- [ ] 抽样检查命名与标签一致性
- [ ] 执行 Git 提交 + push（形成可回滚历史）
- [ ] 周复盘：新增知识点、下周主题、淘汰过时笔记

---

## 移动端与性能建议

- 大文件（视频/大体积素材）尽量外链或独立存储，库内保留索引笔记。
- 图片统一压缩后入库，降低同步负担。
- 插件总量从少到多，优先核心插件；定期关闭不常用插件。
- 移动端优先：快速捕获（Inbox）+ 最小编辑，深度整理放桌面端。

---

## 常见误区与修正

1. **误区：目录越细越好**  
   修正：目录保持 1-2 层，复杂关系交给双链 + MOC。

2. **误区：标签越多越专业**  
   修正：标签服务检索与状态，不做“第二套目录”。

3. **误区：同步=备份**  
   修正：同步用于多端一致；备份需独立策略（Git/快照/异地）。

4. **误区：先装一堆插件再开始写**  
   修正：先用核心插件跑通流程，再按痛点增配。

5. **误区：只收集不复盘**  
   修正：建立每周固定 Review，持续去杂质、补链接、沉淀输出。

---

## 参考来源（高质量）

1. https://help.obsidian.md/
2. https://raw.githubusercontent.com/obsidianmd/obsidian-help/master/en/Files%20and%20folders/How%20Obsidian%20stores%20data.md
3. https://raw.githubusercontent.com/obsidianmd/obsidian-help/master/en/Linking%20notes%20and%20files/Internal%20links.md
4. https://raw.githubusercontent.com/obsidianmd/obsidian-help/master/en/Editing%20and%20formatting/Tags.md
5. https://raw.githubusercontent.com/obsidianmd/obsidian-help/master/en/Plugins/Templates.md
6. https://raw.githubusercontent.com/obsidianmd/obsidian-help/master/en/Plugins/Daily%20notes.md
7. https://raw.githubusercontent.com/obsidianmd/obsidian-help/master/en/Getting%20started/Back%20up%20your%20Obsidian%20files.md
8. https://raw.githubusercontent.com/obsidianmd/obsidian-help/master/en/Obsidian%20Sync/Introduction%20to%20Obsidian%20Sync.md
9. https://stephango.com/vault
10. https://fortelabs.com/blog/para/
