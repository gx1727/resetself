# 重身ResetSelf APP ｜ 完整 UI/UX 设计与前端架构文档

基于「一日身份重构理论」及「无挫败感」理念，本设计文档严格遵循 Apple HIG、MD3 及无障碍标准，提供从产品思考到前端代码落地的全套指南。

## 1. 产品分析 (Product Analysis)

- **核心定位**：一款反直觉的“心理认知重构”应用，而非传统的“行为打卡”应用。
    
- **核心价值**：提供认知真空环境，引导用户从“底层身份”而非“表层行为”开始改变；容纳一切失败，将所有偏离视为迭代数据。
    
- **竞品差异**：无连签、无排行榜、无红点警示、无扣分机制。所有操作以“低阻力、免焦虑”为最高原则。
    

## 2. 用户画像 (User Persona)

- **核心人群**：陷入“间歇性踌躇满志，持续性混吃等死”循环的职场人/学生；深受“毒性生产力”困扰、一中断计划就陷入极度内耗的完美主义者。
    
- **痛点**：目标宏大但无法落地；过度依赖意志力导致频频崩盘；害怕面对真实的失败。
    
- **需求**：一个绝对安全、不带审判眼光的“数字树洞”和“思维手术台”。
    

## 3. 用户旅程 (User Journey)

1. **入驻 (Onboarding)**：授权极简模式 -> 一键屏蔽外界干扰（认知真空） -> 了解3句核心理念。
    
2. **破局 (24h Reset)**：
    
    - 上午 (90min)：写反愿景 -> 剥离虚假目标 -> 直面恐惧。
        
    - 日间：每小时轻量级自省（弹窗）。
        
    - 夜晚 (120min)：寻找限制信念 -> 设定新身份 -> 确立明日1个最小行动。
        
3. **日常 (Daily)**：每日1分钟自检（仅做状态选择，无惩罚）。
    
4. **急救 (SOS)**：情绪崩溃/拖延时，一键进入“内耗急救”，系统自动归因为“旧惯性”，安抚情绪。
    
5. **年度 (Yearly)**：数据对比回顾，不评价好坏，只展示变化。
    

## 4. 信息架构 (Information Architecture - IA)

采用极简扁平化层级（最多2层）：

- **首页 (Home)**
    
    - 当前身份卡片 (Identity Card)
        
    - 明日最小行动 (Minimal Action)
        
    - SOS急救按钮 (悬浮)
        
- **重装 (Reset)**
    
    - 24小时重构引导流 (24h Wizard)
        
    - 历史重构记录归档
        
- **洞察 (Insights)**
    
    - 惯性样本库 (Deviation Logs)
        
    - 每周/年度变化白皮书 (Reports)
        
- **设置 (Settings)**
    
    - 极简模式权限、作息时间设定
        

## 5. 用户流程 (User Flow) - 以每日自检为例

`收到温和推送` -> `打开APP首页` -> `点击今日自检` -> `选择状态（匹配/部分偏离/完全偏离）`

-> _若选择偏离_ -> `系统提示：已作为样本录入惯性库，辛苦了` -> `流程结束，回归首页`。

## 6. 页面列表 (Page List)

1. `Splash Screen` (启动页)
    
2. `Onboarding_Vacuum` (一键真空模式授权)
    
3. `Home_Dashboard` (主页-身份卡)
    
4. `Wizard_Morning` (上午破局：反愿景/恐惧)
    
5. `Wizard_Night` (夜晚重装：信念/新身份/最小行动)
    
6. `Daily_Check` (每日一分钟校验)
    
7. `SOS_Friction` (内耗急救站)
    
8. `Insight_Deviation_Library` (惯性样本库)
    

## 7. 每个页面详细设计 (Detail Design)

- **Home_Dashboard**：全屏大留白。正中央是用户的「身份宣言」（大字体，如：_我是一个看重长远价值的人_）。底部只有一个按钮“今日校验”。右上角为极简的周报入口。右下角悬浮一个柔和的呼吸圈（SOS急救）。
    
- **Wizard_Morning**：采用分步表单（Progressive Disclosure）。每页只有一个问题，配有温和的引导语。打字时其他UI元素淡出（Focus Mode）。
    
- **SOS_Friction**：点击后全屏变暗，文字缓慢浮现：“这不是你的错，是旧惯性的防御。发生了什么？” 提供几个快速标签供选择。
    

## 8. 每个页面 Wireframe (线框图示意)

**【首页 (Home) Wireframe】**

```
+---------------------------------------+
|  [设置]                       [周报]  |
|                                       |
|                                       |
|                                       |
|        我是一个享受专注状态的人       |
|          (I am a focused person)      |
|                                       |
|                                       |
|  +---------------------------------+  |
|  | 明日小动作：清理桌面 5 分钟     |  |
|  +---------------------------------+  |
|                                       |
|                                       |
|           [ 进行今日自检 ]            |
|                                       |
|                                 (SOS) |
+---------------------------------------+
```

**【每日自检 (Daily Check) Wireframe】**

```
+---------------------------------------+
|  [关闭]                               |
|                                       |
|       今天的行为，匹配你的身份吗？    |
|                                       |
|  [ 完全匹配，状态很好 ]               |
|                                       |
|  [ 部分偏离，被旧习惯拉扯了 ]         |
|                                       |
|  [ 完全偏离，但没关系，只是数据 ]     |
|                                       |
|                                       |
|  (注：无需自责，系统只做数据采样)     |
+---------------------------------------+
```

## 9. 页面交互 (Interactions)

- **手势**：全局支持右滑返回。卡片支持轻量下拉刷新（代表呼吸、重新校准）。
    
- **反馈**：打字时键盘音效关闭，只保留极轻微的 Haptic Engine 震动（类似心跳）。
    
- **防敷衍机制**：在重构填写反愿景时，如果输入少于10个字，按钮不会禁用（防挫败），但会延迟1.5秒出现，并配有极微弱的提示“多写一点对自己更有帮助哦”。
    

## 10. 页面状态 (States)

- **Loading**：绝对不使用焦躁的转圈 Spinner。使用全局骨架屏的“呼吸渐变”（Opacity 0.3 -> 0.7）。
    
- **Empty (空状态)**：不提示“你还没有记录，快去添加吧”。提示词改为：“这是一张白纸，等待你的新身份在此扎根。”
    
- **Error (错误/断网)**：提示“网络暂时走神了，但你的数据已在本地安全保存。”
    

## 11. 动画设计 (Animation)

- **核心基调**：Fluid, Breathing, Calm.
    
- **曲线**：使用 ease-in-out，时长偏长（例如页面切换 400ms，元素浮现 600ms）。
    
- **具体场景**：完成每日自检后，选项化作微光融入“惯性样本库”图标中，没有撒花、没有弹窗打断。
    

## Design System (设计规范)

以 **Tailwind CSS** 为基础构建。

### 12. & 13. Color Token (色彩 - 低饱和度、无红色警告)

彻底抛弃警示红和纯黑纯白。使用莫兰迪色系。

- `bg-primary`: 浅色模式 `#F7F7F5` (暖白纸) / 深色模式 `#1C1C1E` (深空)
    
- `bg-surface`: 浅色模式 `#FFFFFF` / 深色模式 `#2C2C2E`
    
- `text-primary`: `#2D2D2D` / `#E5E5EA`
    
- `text-secondary`: `#8E8E93` (用于安抚性文案)
    
- `brand-calm`: `#819B8E` (主色调：鼠尾草绿，代表生机与平静)
    
- `brand-deviation`: `#C2A878` (偏离态：柔和的沙土黄，绝不使用红色)
    
- `border-subtle`: `#E5E5EA` / `#3A3A3C`
    

### 14. Typography (排版)

- **Font Family**: `Inter`, 系统默认无衬线字体 (San Francisco / Roboto)。
    
- **Heading 1 (身份卡)**: `text-3xl font-semibold tracking-tight leading-snug`
    
- **Heading 2 (问题)**: `text-xl font-medium tracking-normal`
    
- **Body (输入框/正文)**: `text-base font-normal leading-relaxed`
    
- **Caption (安抚文案)**: `text-sm font-light text-secondary`
    

### 15. Spacing (间距 - 8pt Grid)

- 充分留白，拒绝拥挤。
    
- 页面外边距 (Margin): `m-6` (24px) 或 `m-8` (32px)。
    
- 卡片内边距 (Padding): `p-6` (24px)。
    
- 元素间距 (Gap): `gap-4` (16px), 核心分隔 `gap-8` (32px)。
    

### 16. Component Library (核心组件)

基于 **shadcn/ui** 深度定制：

- `Button`: 移除默认的强阴影和高饱和 hover。`variant="default"` 使用 `bg-brand-calm text-white rounded-2xl`。`variant="ghost"` 用于跳过或次要操作。
    
- `Card`: 极致轻量。`border border-border-subtle shadow-sm rounded-3xl bg-surface`。
    
- `Textarea`: 无边框设计，仅在底部有一条极浅的细线，focus 时变绿。自动扩容 (Auto-resize)。
    
- `Progress`: 彻底摒弃进度条，改用底部的点状指示器 (Dots Indicator)，降低进度压迫感。
    

## 架构与技术实现 (Architecture)

### 17. API 数据模型 (Data Model - TypeScript/JSON)

为了保证随时断点保存，数据模型必须轻量且扁平。

```
// 用户当前身份 (核心状态)
interface IdentityState {
  id: string;
  statement: string; // "我是一个____的人"
  annualDirection: string;
  monthlyTasks: string[];
  minimalAction: string; // 明日小动作
  lastUpdated: string; // ISO Date
}

// 每日校验记录 (作为数据样本)
interface CheckInLog {
  id: string;
  date: string;
  status: 'MATCH' | 'PARTIAL_DEVIATION' | 'FULL_DEVIATION';
  triggerFactor?: string; // 归因（如果是偏离）
  isSOS: boolean; // 是否由内耗急救触发
}
```

### 18. 前端组件拆分 (Component Tree)

```
src/
├── components/
│   ├── layout/
│   │   ├── ZenContainer.tsx      # 全局呼吸感背景布局
│   │   └── SafeAreaView.tsx      # 移动端适配适配层
│   ├── features/
│   │   ├── Identity/
│   │   │   ├── IdentityCard.tsx  # 首页身份宣言展示
│   │   │   └── ActionBadge.tsx   # 明日小动作组件
│   │   ├── Wizard/
│   │   │   ├── StepContainer.tsx # 自动保存、防跳出的向导容器
│   │   │   └── GentlePrompt.tsx  # 温和防敷衍提示文本
│   │   └── SOS/
│   │       └── FloatingBreathButton.tsx # 右下角急救按钮
│   └── ui/                       # shadcn 定制组件库 (Button, Input等)
├── stores/
│   ├── identityStore.ts          # Zustand: 存储当前身份与最小行动
│   └── draftStore.ts             # Zustand: 实时持久化重装步骤的草稿 (localStorage)
```

### 19. React + Tailwind + shadcn/ui 实现建议 (供 AI 快速生代码)

1. **状态管理**：使用 `Zustand` 结合 `persist` 中间件，实现“任何输入实时存入 LocalStorage”。完美解决“断点保存、防中断”的需求。
    
2. **动画库**：强制引入 `Framer Motion`。
    
    - 页面切换使用 `<AnimatePresence>`，配置 `{ opacity: 0, y: 10 }` 的微小位移，模拟“思绪浮现”。
        
    - SOS按钮使用 `animate={{ scale: [1, 1.05, 1] }}` 配合 `transition={{ repeat: Infinity, duration: 4 }}` 实现深呼吸效果。
        
3. **Tailwind 配置**：在 `tailwind.config.js` 中严格限制调色板，只允许使用上述的 `brand-calm`, `bg-primary` 等 Token，防止开发人员误用高饱和度色彩。
    
4. **Shadcn 改造**：修改 `components/ui/button.tsx` 等默认文件，将 `rounded-md` 改为 `rounded-2xl`，将强烈的 ring 焦点效果改为极淡的背景色变化。
    

### 20. 总结：开发团队落地军规

- **绝不能加的功能**：不准做连续打卡日历（一格格填满那种），不准做勋章系统，不准加 push 推送促活（除了设定好的自检时间）。
    
- **前端异常捕获**：在 Error Boundary 中，文案统一由“系统发生错误”改为“系统正在整理你的潜意识，请稍后再试”。永远保持从容。
    
- **无感存储**：所有的 `onChange` 事件必须挂载 `debounce` (防抖，比如500ms) 然后自动 dispatch 到缓存系统，绝对不要让用户手动点“保存”按钮。