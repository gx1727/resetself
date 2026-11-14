/// 晨间「心理挖掘」的 14 个问题，来自原文第一部分。
///
/// 这些问题用于引导用户逐步产生答案，而不是直接询问结论，
/// 因此回答属于「探索原稿」。它们保存在 `restructure_morning_answer` 表中，
/// 与晚间综合后的结论（`restructure_draft` / `restructure_record`）分开存储，
/// 避免用一句话表单冒充完整心理挖掘。
class MorningQuestion {
  const MorningQuestion({
    required this.key,
    required this.order,
    required this.question,
    required this.hint,
  });

  /// 稳定标识，用于持久化回答。
  final String key;

  /// 展示顺序，从 1 起。
  final int order;

  /// 问题正文。
  final String question;

  /// 输入提示，帮助用户想起可以写什么。
  final String hint;

  static const all = <MorningQuestion>[
    MorningQuestion(
      key: 'tolerated_dissatisfaction',
      order: 1,
      question: '你已经学会与之共处的、迟钝而持续的不满是什么？',
      hint: '不是深刻的痛苦，而是你已经学会忍受的东西。',
    ),
    MorningQuestion(
      key: 'repeated_complaints',
      order: 2,
      question: '你反复抱怨却从未真正改变的是什么？',
      hint: '写下过去一年里你最常说出的三个抱怨。',
    ),
    MorningQuestion(
      key: 'behavior_reveals',
      order: 3,
      question: '如果有人观察你的行为（而不是你的语言），他会得出你真正想要什么？',
      hint: '针对上面每个抱怨，分别写一句。',
    ),
    MorningQuestion(
      key: 'unbearable_truth',
      order: 4,
      question: '关于你当前生活的什么真相，如果要承认给你深深尊敬的人听，会让你难以忍受？',
      hint: '越难说出口，往往越接近核心。',
    ),
    MorningQuestion(
      key: 'five_year_tuesday',
      order: 5,
      question: '如果未来五年绝对没有任何改变，描述一个普通的星期二。',
      hint: '在哪里醒来？身体感觉如何？第一个念头是什么？谁在身边？9 点到 18 点做什么？22 点感觉如何？',
    ),
    MorningQuestion(
      key: 'ten_year_cost',
      order: 6,
      question: '把时间拉到十年，你错过了什么？',
      hint: '哪些机会关闭了？谁放弃了你？当你不在场时，人们会怎么谈论你？',
    ),
    MorningQuestion(
      key: 'end_of_life',
      order: 7,
      question: '你走到了生命尽头，过的是安全版本的人生，从未打破模式。代价是什么？',
      hint: '你从未允许自己感受、尝试或成为什么？',
    ),
    MorningQuestion(
      key: 'living_future',
      order: 8,
      question: '你生活中谁已经在过你刚刚描述的未来？',
      hint: '有谁在同一轨道上领先你五年、十年、二十年？想到自己会成为他们，你有什么感觉？',
    ),
    MorningQuestion(
      key: 'identity_to_give_up',
      order: 9,
      question: '为了真正改变，你必须放弃什么身份？',
      hint: '「我是那种会……的人。」不再成为那种人，会让你在社交上付出什么代价？',
    ),
    MorningQuestion(
      key: 'embarrassing_reason',
      order: 10,
      question: '你还没有改变的最尴尬理由是什么？',
      hint: '那个会让你听起来软弱、害怕或懒惰，而不是合理的理由。',
    ),
    MorningQuestion(
      key: 'self_protection',
      order: 11,
      question: '如果当前的行为是一种自我保护，你到底在保护什么？',
      hint: '这种保护正在让你付出什么代价？',
    ),
    MorningQuestion(
      key: 'three_year_tuesday',
      order: 12,
      question: '先忘掉现实可行性：如果三年后你真正想要的生活降临，一个普通星期二是什么样？',
      hint: '用和第 5 题同样的细节程度描述。',
    ),
    MorningQuestion(
      key: 'new_identity_statement',
      order: 13,
      question: '为了让那种生活自然而不是强迫，你必须相信关于自己的什么？',
      hint: '写下身份陈述：「我是那种会……的人。」',
    ),
    MorningQuestion(
      key: 'this_week_action',
      order: 14,
      question: '如果你已经是那个人，这周你会做的一件事是什么？',
      hint: '一件具体、本周内就能开始的事。',
    ),
  ];
}
