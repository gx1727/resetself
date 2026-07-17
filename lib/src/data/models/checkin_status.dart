enum CheckinStatus {
  match(
    value: 'match',
    optionLabel: '完全匹配，状态很好',
    sampleStatusTag: '完全匹配',
    systemComment: '今天的行为与新身份一致，这是一条稳定的新证据。',
    completionTitle: '已完成今日校验',
    completionBody: '你今天和新的自己站在同一边。\n这份稳定，会慢慢长成新的惯性。',
    shouldCreateSample: false,
  ),
  partial(
    value: 'partial',
    optionLabel: '部分偏离，被旧习惯拉扯',
    sampleStatusTag: '部分偏离',
    systemComment: '今天出现了轻微拉扯，系统已记录为旧惯性样本。',
    completionTitle: '已收录至惯性样本库',
    completionBody: '这不是失败，只是一条珍贵的数据。\n看见它，就是在松动旧惯性。',
    shouldCreateSample: true,
  ),
  fullDeviation(
    value: 'full_deviation',
    optionLabel: '完全偏离，只记作偏差数据',
    sampleStatusTag: '完全偏离',
    systemComment: '今天明显偏离了目标，但系统只将其视作一次旧惯性回弹。',
    completionTitle: '已收录至惯性样本库',
    completionBody: '这不是你的错，是旧惯性在自我防御。\n先被接住，再继续向前。',
    shouldCreateSample: true,
  );

  const CheckinStatus({
    required this.value,
    required this.optionLabel,
    required this.sampleStatusTag,
    required this.systemComment,
    required this.completionTitle,
    required this.completionBody,
    required this.shouldCreateSample,
  });

  final String value;
  final String optionLabel;
  final String sampleStatusTag;
  final String systemComment;
  final String completionTitle;
  final String completionBody;
  final bool shouldCreateSample;
}
