# PetManager 下一轮提示词：无电脑、玩耍优先动作重制

```text
目标：
基于已完成的 Classic S4 与多多 S5 工程合同，执行一轮“无电脑、玩耍优先”的视觉方向重制。现有带电脑候选保留为历史证据，不得直接发布，也不得覆盖。

项目路径：
<PetManager 项目路径>

上游产品合同：
<LetsMakeMoney 项目路径>/doc/releases/v0.9/pet-animation-play-first-revision.md

开始前读取：
- docs/hatch-pet-pro-custom-actions-design.md
- skills/hatch-pet-pro/SKILL.md
- skills/hatch-pet-pro/references/custom-action-contract.md
- Classic S4.3 最终审查与证据
- 多多 S5/S5.2 最终审查与证据
- 两套 action-profile.json、compiled-profile.json、motion manifest、QA evidence 与 motion review

本轮不是重做状态机，也不是增加动作数量。保留以下运行时 ID、动作类型、帧数、逐帧时长结构、锚点、脚底线、回退和图集合同：
- working_loop
- working_ack
- rest_ack
- sleep_ack
- run_prepare
- run_stop
- lunch_relief
- lunch_return

产品方向：
1. 所有新候选必须彻底移除电脑、笔记本、显示器、键盘、鼠标、办公桌、办公椅和屏幕界面。
2. 动画主体必须是小猫自身，优先表现玩耍、扑抓、观察、伸展、理毛、摆尾、翻滚和睡眠微动作。
3. 工作状态通过更积极、更有节奏的玩耍表达，不再用“猫在办公”解释。
4. 午休开始与结束通过能量和姿态转换表达，不使用道具进出。
5. 首轮默认完全无道具。若无道具无法清楚表达，先提出单一轻量玩具方案并等待项目所有者批准，不得自行生成。

本轮重制范围：
- working_loop：主动玩耍的无缝循环，观察目标 -> 扑抓/拍打 -> 收势 -> 再次准备。
- working_ack：停下玩耍、看向用户、轻拍或歪头回应，再回到 active pose。
- lunch_relief：停止高能玩耍，大幅伸展或翻滚，结束在 awake_rest 可衔接姿势。
- lunch_return：从松弛姿势起身、伸展、进入玩耍准备姿势，结束帧自然衔接 working_loop。

锁定复用范围：
- rest_ack
- sleep_ack
- run_prepare
- run_stop

除非自动 QA 或人工审查证明锁定动作不符合新方向，否则这四项的 incoming、normalized 和 atlas 输入哈希必须保持不变。

实施要求：
1. 新建独立工作区和版本号，不覆盖 S4/S5 历史候选。
2. 先更新 Profile 的 purpose、motionRequirements、allowedProps 和 forbiddenElements；四个重制动作 allowedProps 必须为空。
3. 将电脑及全部办公道具加入 Profile 级和动作级 forbiddenElements。
4. 编译 Profile 后先停在人工 Profile 审批门禁，不得直接调用 imagegen。
5. Profile 获批后，Classic 先行完成生成、标准化、图集、真实时长 GIF、Contact Sheet、边界衔接、循环连续性和 motion review。
6. Classic 人工视觉通过后，才用相同语义合同为多多生成对应四项；不得加入 pet_id 特判。
7. 旧候选标记为 superseded_visual_direction，但不得删除、改哈希或伪装成失败工程产物。

自动门禁至少覆盖：
- 生成帧和图集不得引用或包含办公道具层；
- working_loop 首尾连续；
- lunch_relief 末帧衔接 awake_rest；
- lunch_return 末帧衔接 working_loop；
- 相邻尺度、中心、脚底线、耳朵、尾巴和四肢稳定；
- 透明缺口、色键残留、相邻槽污染为 0；
- 锁定四动作哈希不变；
- fixed-pro 基线哈希不变；
- 缺少人工 review 时验证器返回非零；
- ready:false / published:false，直到项目所有者批准。

人工审查必须回答：
- 第一眼看到的是猫在玩，而不是道具在移动吗？
- working、awake_rest、sleeping 是否无需文字即可辨认？
- working_loop 连播 10 次是否自然、轻快且不机械？
- 午休开始/结束是否只靠动作能量与姿态就能理解？
- Classic 和多多是否保持各自身份且服从同一合同？

文档要求：
- 将本轮产品方向、失败尝试、生成提示策略和最终审查结论写入 PetManager 的开发/QA 文档。
- 将“电脑道具让桌宠变成状态插画”的教训加入 hatch-pet-pro 后续整体优化方向，但不要因此扩大本轮实现范围。

停止点：
先完成 Profile 修订、编译、自动合同检查和人工审批材料，然后停下。未收到项目所有者“批准玩耍优先 Profile”前，不调用 imagegen、不生成正式素材、不提交、不推送、不发布、不修改 LetsMakeMoney。

最终输出：
## 当前基线
## Profile 修改
## 禁用元素
## 四个重制动作分镜
## 锁定动作与哈希
## 自动门禁
## 人工审批入口
## 下一阶段停止点
```
