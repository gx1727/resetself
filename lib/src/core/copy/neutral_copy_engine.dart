/// 中性归因策略系统的入口。
///
/// 这一层会按三段组装文本：
/// 1. `CopyLexicon`：只放可复用语义原子（偏离、回流、锚点、专注、归档）
/// 2. `CopyScenarios`：按场景（onboarding / vacuum / archive / focus）拼装
/// 3. `CopyStrategy`：对外暴露组合接口，传入上下文返回最终文本
///
/// 页面层不再写完整句子，只调用 `CopyStrategy` 拿到最终文本。
class CopyStrategy {
  const CopyStrategy._();

  static OnboardingCopy onboarding() {
    return const OnboardingCopy(
      airBadgeLabel: 'AIR',
      title: 'ResetSelf',
      subtitle: '把每一次想坚持却没有坚持的瞬间，\n悄悄变成可追溯的旧惯性样本。',
      vacuumPrepCta: '先看认知真空准备区',
      restructureCta: '开启 24h 重构向导',
      reopenFocus: '打开专注进行中',
    );
  }

  static VacuumModeCopy vacuumMode() {
    return const VacuumModeCopy(
      backLabel: '返回',
      title: '认知真空',
      subtitle: '先关掉提醒、关掉打扰，\n给接下来 24 小时留一段真正安静区。',
      durationLabel: '专注时长',
      minutesUnit: '分钟',
      muteChannelsLabel: '降噪渠道',
      defaultReminder: '默认在准备区结束前 5 分钟提醒你',
      enterFocus: '先进入一段真空专注',
      readyCta: '我准备好了，进入 24h 重构',
    );
  }

  static String vacuumDurationOption(int minutes) {
    return CopyLexicon.focusDurationOption(minutes);
  }

  static HomeCopy home() {
    return const HomeCopy(
      identityBadge: '当前核心身份',
      minActionLabel: '明日极简动作',
      todayStatusCheckinMissing: '今天还没有开始校准',
      todayStatusEmptyHint: '无需自责，系统只做状态校准',
      todayStatusRecordedHint: '今天的状态已经被温柔地记下了。',
      todayStatusMatch: '今天已完成校验：完全匹配',
      todayStatusPartial: '今天已完成校验：部分偏离',
      todayStatusFullDeviation: '今天已完成校验：完全偏离',
      todayStatusGeneric: '今天已完成校验',
      checkinCtaMissing: '进行今日校验',
      checkinCtaRecorded: '重新校准今天状态',
      weeklySectionEyebrow: '本周状态',
      weeklySectionTitle: '这一周的节奏变化',
      positiveSectionEyebrow: '本周回流',
      positiveSectionTitle: '你已经留下了哪些稳定信号',
      vacuumActiveRemaining: '预计还有 {minutes} 分钟',
      vacuumActiveEnded: '这一段已到结束时间',
      vacuumActiveOngoing: '正在进行',
      vacuumReminderOn: '{time} 提醒',
      vacuumReminderOff: '不启用提醒',
      vacuumNoiseOn: '先隔离碎片输入',
      vacuumNoiseOff: '手动保持安静区',
      vacuumFinishedReturnPrompt: '上一段专注已经结束。现在只回到这一个动作：{action}',
      sampleSourceSos: 'SOS急救',
      sampleSourceDailyDeviation: '每日偏离',
      sampleSourceRestructure: '首次重构',
      sampleSourceVacuumFocus: '真空专注',
      sampleSourceGeneric: '惯性样本',
    );
  }

  static String homeVacuumReturnPrompt(String minAction) {
    return CopyLexicon.formatTemplate(
      CopyStrategy.home().vacuumFinishedReturnPrompt,
      {'action': minAction},
    );
  }

  static String homeVacuumRemaining(int minutes) {
    return CopyLexicon.formatTemplate(
      CopyStrategy.home().vacuumActiveRemaining,
      {'minutes': '$minutes'},
    );
  }

  static String homeVacuumReminder(String time) {
    return CopyLexicon.formatTemplate(
      CopyStrategy.home().vacuumReminderOn,
      {'time': time},
    );
  }

  static String insightsInsightEntryTitle(String filterLabel) {
    return CopyLexicon.formatTemplate(
      '先借 {filter} 看清这一周的节奏',
      {'filter': filterLabel},
    );
  }

  static InsightsCopy insights() {
    return const InsightsCopy(
      pageTitle: '惯性样本库',
      loadingHint: '样本库正在慢慢浮现...',
      errorHint: '样本库暂时没有展开，但你的本地数据仍是安全的。',
      defaultStatusSos: 'SOS急救',
      defaultStatusManual: '首次重构',
      defaultStatusVacuumFocus: '真空专注',
      defaultStatusGeneric: '惯性样本',
      statMatch: '匹配',
      statPartial: '部分偏离',
      statFullDeviation: '完全偏离',
      statSos: 'SOS',
      statVacuumFocus: '真空专注',
      statFullMatch: '完全匹配',
      statDailyDeviation: '每日偏离',
      statRestructure: '首次重构',
      footer: '只展示最近 7 天的样本数据',
      todayTimeTemplate: '今天 {time}',
      yesterdayTimeTemplate: '昨天 {time}',
      monthDayTimeTemplate: '{date} {time}',
    );
  }

  static String insightsTodayTime(String hourMinute) {
    return CopyLexicon.formatTemplate(
      CopyStrategy.insights().todayTimeTemplate,
      {'time': hourMinute},
    );
  }

  static String insightsYesterdayTime(String hourMinute) {
    return CopyLexicon.formatTemplate(
      CopyStrategy.insights().yesterdayTimeTemplate,
      {'time': hourMinute},
    );
  }

  static String insightsMonthDayTime(String monthDay, String hourMinute) {
    return CopyLexicon.formatTemplate(
      CopyStrategy.insights().monthDayTimeTemplate,
      {'date': monthDay, 'time': hourMinute},
    );
  }

  static String insightsHourMinute(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static SettingsCopy settings() {
    return const SettingsCopy(
      flowSectionTitle: '当前流程状态',
      vacuumSectionTitle: '当前真空模式节奏',
      focusSectionTitle: '当前真空专注状态',
      debugDbPath: '数据库路径',
      debugRecentSamples: '最近 7 天样本',
      debugTotalSamples: '样本总数',
      debugCheckinCount: '每日校验总数',
      debugDraftStatus: '草稿状态',
      debugRecentCheckinDate: '最近校验日期',
      debugLatestExport: '最近导出文件',
      debugExportContents: '导出内容',
      debugExportTime: '导出时间',
      debugLatestRestore: '最近恢复文件',
      debugRestoreContents: '恢复内容',
      debugRestoreTime: '恢复时间',
      debugCountSuffix: ' 条',
      debugTimestampTemplate: '{date} {time}',
      title: '设置',
      subtitle: '先保留当前阶段需要的系统入口，方便查看本地状态、真空节奏和数据备份。',
      backupTitle: '数据导出与备份',
      backupBody: '把关键本地表导出成 JSON 备份文件，先保存在应用文档目录的 backups 文件夹里。',
      focusPanelTitle: '认知真空准备区',
      focusPanelBody: '查看降噪准备、专注时段和提醒节奏',
      resetLabel: '重置为首次引导',
      resettingLabel: '重置中...',
      debugPanelTitle: '本地数据库调试面板',
    );
  }

  static String settingsDebugTimestamp(DateTime value) {
    final year = value.year.toString();
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final second = value.second.toString().padLeft(2, '0');
    return CopyLexicon.formatTemplate(
      CopyStrategy.settings().debugTimestampTemplate,
      {
        'date': '$year-$month-$day',
        'time': '$hour:$minute:$second',
      },
    );
  }

  static ArchiveCopy archive() {
    return const ArchiveCopy(
      fieldIdentity: '新身份',
      fieldBelief: '限制性信念',
      fieldFear: '底层恐惧',
      fieldAntiVision: '反愿景',
      fieldVision: '愿景 MVP',
      fieldYearGoal: '一年镜头',
      fieldMonthProject: '一月镜头',
      fieldConstraints: '避坑机制',
      fieldYearlyIdentity: '年度身份快照',
      gameSectionTitle: '人生游戏化闭环',
      anchorSectionTitle: '身份库（今日聚焦）',
    );
  }

  static HomeAntiVisionCopy homeAntiVision() {
    return const HomeAntiVisionCopy(
      badge: '你要避开的未来',
      title: '反愿景赌注',
      bodyPrefix: '如果什么都不改变，这就是你要走向的生活：',
      visionPrefix: '你正在走向：',
      emptyHint: '还没有写下反愿景。完成一次重构后，它会常驻在这里提醒你。',
      ctaLabel: '查看完整重构',
    );
  }

  static DaytimeInterruptCopy daytimeInterrupt() {
    return const DaytimeInterruptCopy(
      title: '日间打断',
      subtitle: '在固定的六个时点，用 3 分钟看清：\n此刻的行为，是在走向新身份，还是退回旧惯性。',
      recordedTemplate: '今天已完成 {count} 次自省',
      pendingLabel: '还没到下一个打断时点',
      promptEyebrow: '此刻的自省问题',
      reflectionLabel: '写下你此刻的觉察',
      reflectionHint: '不用写多，两三句就够。',
      tagLabel: '把这次行为先归类',
      growthTag: '成长性行为',
      escapeTag: '逃避性行为',
      saveLabel: '记录这次自省',
      savedTitle: '这次自省已经被记下来',
      savedBody: '它不是评判，而是一条让你看清旧惯性出现时段的样本。',
      disabledTitle: '日间打断还没有开启',
      disabledBody: '可以在认知真空准备区打开"日间打断"，让这六个时点提醒你停下来。',
      historyTitle: '今天留下的自省',
      historyEmpty: '今天还没有留下自省记录。',
      prompts: [
        InterruptPrompt(time: '11:00', question: '我现在通过正在做的事，在逃避什么？'),
        InterruptPrompt(
          time: '13:30',
          question: '如果有人拍下过去两个小时，会得出我想从人生中得到什么？',
        ),
        InterruptPrompt(time: '15:15', question: '我是在走向自己讨厌的人生，还是想要的人生？'),
        InterruptPrompt(time: '17:00', question: '我正在假装不重要的、最重要的事情是什么？'),
        InterruptPrompt(
          time: '19:30',
          question: '我今天有哪些事是出于身份保护，而不是真正渴望？',
        ),
        InterruptPrompt(
          time: '21:00',
          question: '今天什么时候我感觉最有生命力？什么时候最死气沉沉？',
        ),
      ],
    );
  }

  static String daytimeInterruptRecorded(int count) {
    return CopyLexicon.formatTemplate(
      CopyStrategy.daytimeInterrupt().recordedTemplate,
      {'count': '$count'},
    );
  }
}

/// 语义原子层。基础短句不再出现在页面里，只在这里定义和复用。
class CopyLexicon {
  const CopyLexicon._();

  static String deviationNoun({required bool intense}) {
    return intense ? '强烈拉扯' : '日常拉扯';
  }

  static String deviationFrame({required bool intense}) {
    return intense ? '这不是你的错，是旧惯性的防御。' : '这不是失败，只是一条珍贵的数据。';
  }

  static String returnSignalPhrase({required bool strong}) {
    return strong ? '你已经开始主动把自己带回来了' : '这一周已经出现第一批回流信号';
  }

  static String anchorPhrase() {
    return '它们不是口号，而是你重新站回来的依据。';
  }

  static String focusActionPhrase() {
    return '先进入一段真空专注，把自己带回稳定区。';
  }

  static String archiveEvidencePhrase() {
    return '留下来的不是完美，而是可以回看的证据。';
  }

  static String smallestActionPhrase(String minAction) {
    return '现在继续：$minAction';
  }

  static String keepActionSmallPhrase(String minAction) {
    return '先只做这一件小事：$minAction';
  }

  static String focusThenReturnPhrase(String minAction) {
    return '先给自己一段安静区，再回到今天这一个动作：$minAction';
  }

  static String returnToActionPhrase(String minAction) {
    return '接下来不要扩张目标，只继续：$minAction';
  }

  static String rebuildAnchorPhrase() {
    return '现在回到重构页，重新对齐今天的身份与动作。';
  }

  static String focusDurationOption(int minutes) {
    return '$minutes 分钟';
  }

  static String formatTemplate(String template, Map<String, String> values) {
    var result = template;
    values.forEach((key, value) {
      result = result.replaceAll('{$key}', value);
    });
    return result;
  }
}

/// 场景文案模型。给页面直接绑定使用的成组文案。
class OnboardingCopy {
  const OnboardingCopy({
    required this.airBadgeLabel,
    required this.title,
    required this.subtitle,
    required this.vacuumPrepCta,
    required this.restructureCta,
    required this.reopenFocus,
  });

  final String airBadgeLabel;
  final String title;
  final String subtitle;
  final String vacuumPrepCta;
  final String restructureCta;
  final String reopenFocus;
}

class VacuumModeCopy {
  const VacuumModeCopy({
    required this.backLabel,
    required this.title,
    required this.subtitle,
    required this.durationLabel,
    required this.minutesUnit,
    required this.muteChannelsLabel,
    required this.defaultReminder,
    required this.enterFocus,
    required this.readyCta,
  });

  final String backLabel;
  final String title;
  final String subtitle;
  final String durationLabel;
  final String minutesUnit;
  final String muteChannelsLabel;
  final String defaultReminder;
  final String enterFocus;
  final String readyCta;
}

class HomeCopy {
  const HomeCopy({
    required this.identityBadge,
    required this.minActionLabel,
    required this.todayStatusCheckinMissing,
    required this.todayStatusEmptyHint,
    required this.todayStatusRecordedHint,
    required this.todayStatusMatch,
    required this.todayStatusPartial,
    required this.todayStatusFullDeviation,
    required this.todayStatusGeneric,
    required this.checkinCtaMissing,
    required this.checkinCtaRecorded,
    required this.weeklySectionEyebrow,
    required this.weeklySectionTitle,
    required this.positiveSectionEyebrow,
    required this.positiveSectionTitle,
    required this.vacuumActiveRemaining,
    required this.vacuumActiveEnded,
    required this.vacuumActiveOngoing,
    required this.vacuumReminderOn,
    required this.vacuumReminderOff,
    required this.vacuumNoiseOn,
    required this.vacuumNoiseOff,
    required this.vacuumFinishedReturnPrompt,
    required this.sampleSourceSos,
    required this.sampleSourceDailyDeviation,
    required this.sampleSourceRestructure,
    required this.sampleSourceVacuumFocus,
    required this.sampleSourceGeneric,
  });

  final String identityBadge;
  final String minActionLabel;
  final String todayStatusCheckinMissing;
  final String todayStatusEmptyHint;
  final String todayStatusRecordedHint;
  final String todayStatusMatch;
  final String todayStatusPartial;
  final String todayStatusFullDeviation;
  final String todayStatusGeneric;
  final String checkinCtaMissing;
  final String checkinCtaRecorded;
  final String weeklySectionEyebrow;
  final String weeklySectionTitle;
  final String positiveSectionEyebrow;
  final String positiveSectionTitle;
  final String vacuumActiveRemaining;
  final String vacuumActiveEnded;
  final String vacuumActiveOngoing;
  final String vacuumReminderOn;
  final String vacuumReminderOff;
  final String vacuumNoiseOn;
  final String vacuumNoiseOff;
  final String vacuumFinishedReturnPrompt;
  final String sampleSourceSos;
  final String sampleSourceDailyDeviation;
  final String sampleSourceRestructure;
  final String sampleSourceVacuumFocus;
  final String sampleSourceGeneric;
}

class InsightsCopy {
  const InsightsCopy({
    required this.pageTitle,
    required this.loadingHint,
    required this.errorHint,
    required this.defaultStatusSos,
    required this.defaultStatusManual,
    required this.defaultStatusVacuumFocus,
    required this.defaultStatusGeneric,
    required this.statMatch,
    required this.statPartial,
    required this.statFullDeviation,
    required this.statSos,
    required this.statVacuumFocus,
    required this.statFullMatch,
    required this.statDailyDeviation,
    required this.statRestructure,
    required this.footer,
    required this.todayTimeTemplate,
    required this.yesterdayTimeTemplate,
    required this.monthDayTimeTemplate,
  });

  final String pageTitle;
  final String loadingHint;
  final String errorHint;
  final String defaultStatusSos;
  final String defaultStatusManual;
  final String defaultStatusVacuumFocus;
  final String defaultStatusGeneric;
  final String statMatch;
  final String statPartial;
  final String statFullDeviation;
  final String statSos;
  final String statVacuumFocus;
  final String statFullMatch;
  final String statDailyDeviation;
  final String statRestructure;
  final String footer;
  final String todayTimeTemplate;
  final String yesterdayTimeTemplate;
  final String monthDayTimeTemplate;
}



class ArchiveCopy {
  const ArchiveCopy({
    required this.fieldIdentity,
    required this.fieldBelief,
    required this.fieldFear,
    required this.fieldAntiVision,
    required this.fieldVision,
    required this.fieldYearGoal,
    required this.fieldMonthProject,
    required this.fieldConstraints,
    required this.fieldYearlyIdentity,
    required this.gameSectionTitle,
    required this.anchorSectionTitle,
  });

  final String fieldIdentity;
  final String fieldBelief;
  final String fieldFear;
  final String fieldAntiVision;
  final String fieldVision;
  final String fieldYearGoal;
  final String fieldMonthProject;
  final String fieldConstraints;
  final String fieldYearlyIdentity;
  final String gameSectionTitle;
  final String anchorSectionTitle;
}

class InterruptPrompt {
  const InterruptPrompt({required this.time, required this.question});

  final String time;
  final String question;
}

class DaytimeInterruptCopy {
  const DaytimeInterruptCopy({
    required this.title,
    required this.subtitle,
    required this.recordedTemplate,
    required this.pendingLabel,
    required this.promptEyebrow,
    required this.reflectionLabel,
    required this.reflectionHint,
    required this.tagLabel,
    required this.growthTag,
    required this.escapeTag,
    required this.saveLabel,
    required this.savedTitle,
    required this.savedBody,
    required this.disabledTitle,
    required this.disabledBody,
    required this.historyTitle,
    required this.historyEmpty,
    required this.prompts,
  });

  final String title;
  final String subtitle;
  final String recordedTemplate;
  final String pendingLabel;
  final String promptEyebrow;
  final String reflectionLabel;
  final String reflectionHint;
  final String tagLabel;
  final String growthTag;
  final String escapeTag;
  final String saveLabel;
  final String savedTitle;
  final String savedBody;
  final String disabledTitle;
  final String disabledBody;
  final String historyTitle;
  final String historyEmpty;
  final List<InterruptPrompt> prompts;
}

class HomeAntiVisionCopy {
  const HomeAntiVisionCopy({
    required this.badge,
    required this.title,
    required this.bodyPrefix,
    required this.visionPrefix,
    required this.emptyHint,
    required this.ctaLabel,
  });

  final String badge;
  final String title;
  final String bodyPrefix;
  final String visionPrefix;
  final String emptyHint;
  final String ctaLabel;
}

class NeutralCopyEngine {
  const NeutralCopyEngine._();

  static String deviationNoun({
    required bool intense,
  }) {
    return intense ? '强烈拉扯' : '日常拉扯';
  }

  static String deviationFrame({
    required bool intense,
  }) {
    return intense ? '这不是你的错，是旧惯性的防御。' : '这不是失败，只是一条珍贵的数据。';
  }

  static String returnSignalPhrase({
    required bool strong,
  }) {
    return strong ? '你已经开始主动把自己带回来了' : '这一周已经出现第一批回流信号';
  }

  static String anchorPhrase() {
    return '它们不是口号，而是你重新站回来的依据。';
  }

  static String focusActionPhrase() {
    return '先进入一段真空专注，把自己带回稳定区。';
  }

  static String archiveEvidencePhrase() {
    return '留下来的不是完美，而是可以回看的证据。';
  }

  static String smallestActionPhrase(String minAction) {
    return '现在继续：$minAction';
  }

  static String keepActionSmallPhrase(String minAction) {
    return '先只做这一件小事：$minAction';
  }

  static String focusThenReturnPhrase(String minAction) {
    return '先给自己一段安静区，再回到今天这一个动作：$minAction';
  }

  static String returnToActionPhrase(String minAction) {
    return '接下来不要扩张目标，只继续：$minAction';
  }

  static String rebuildAnchorPhrase() {
    return '现在回到重构页，重新对齐今天的身份与动作。';
  }

  static CheckinCopy checkin(String statusValue) {
    return switch (statusValue) {
      'match' => const CheckinCopy(
        optionLabel: '完全匹配，状态很好',
        sampleStatusTag: '完全匹配',
        systemComment: '今天的行为与新身份一致，这是一条稳定的新证据。',
        completionTitle: '已完成今日校验',
        completionBody: '你今天和新的自己站在同一边。\n这份稳定，会慢慢长成新的惯性。',
      ),
      'partial' => const CheckinCopy(
        optionLabel: '部分偏离，被旧习惯拉扯',
        sampleStatusTag: '部分偏离',
        systemComment: '今天出现了轻微拉扯，系统已记录为旧惯性样本。',
        completionTitle: '已收录至惯性样本库',
        completionBody: '这不是失败，只是一条珍贵的数据。\n看见它，就是在松动旧惯性。',
      ),
      'full_deviation' => const CheckinCopy(
        optionLabel: '完全偏离，只记作偏差数据',
        sampleStatusTag: '完全偏离',
        systemComment: '今天明显偏离了目标，但系统只将其视作一次旧惯性回弹。',
        completionTitle: '已收录至惯性样本库',
        completionBody: '这不是你的错，是旧惯性在自我防御。\n先被接住，再继续向前。',
      ),
      _ => const CheckinCopy(
        optionLabel: '记录今天的状态',
        sampleStatusTag: '状态记录',
        systemComment: '今天的状态已经被系统记下来了。',
        completionTitle: '已完成状态记录',
        completionBody: '今天的状态已经被留下来，接下来只回到下一步动作。',
      ),
    };
  }

  static String sosError() {
    return '这次拉扯还没记下来，你可以再点一次。';
  }

  static String sosIntroTitle() {
    return '这不是你的错，\n是旧惯性的防御。';
  }

  static String sosIntroBody() {
    return '你正试图改变，潜意识感到了害怕。\n深呼吸，告诉系统刚才发生了什么？';
  }

  static String sosSaving() {
    return '系统正在接住这次波动...';
  }

  static String sosDoneTitle() {
    return '已记作一次旧惯性波动';
  }

  static String sosDoneBody(String selectedLabel) {
    return '刚才发生的是：$selectedLabel\n\n你没有做错什么，系统只是先替你把它接住。';
  }

  static String weeklySummaryTitle({
    required int totalCheckins,
    required int sosCount,
    required int vacuumFocusCount,
    required int matchCount,
    required int partialCount,
    required int fullDeviationCount,
  }) {
    if (totalCheckins == 0 && sosCount == 0 && vacuumFocusCount == 0) {
      return '这一周还没有形成复盘样本';
    }

    if (vacuumFocusCount >= 3 && matchCount >= fullDeviationCount) {
      return '这一周已经开始形成稳定回流';
    }

    if (matchCount >= partialCount + fullDeviationCount) {
      return '这一周的新身份正在慢慢站稳';
    }

    if (fullDeviationCount > partialCount) {
      return '这一周旧惯性的反扑更明显一些';
    }

    return '这一周处在拉扯中，但已经开始被看见';
  }

  static String weeklyPositiveSignalTitle({
    required int vacuumFocusCount,
    required int matchCount,
  }) {
    if (vacuumFocusCount == 0 && matchCount == 0) {
      return '正向回流还在积累中';
    }

    if (vacuumFocusCount >= 3) {
      return returnSignalPhrase(strong: true);
    }

    if (matchCount >= 2) {
      return '新的身份匹配开始有连续性了';
    }

    return returnSignalPhrase(strong: false);
  }

  static String insightDominantLabel({
    required int totalCount,
    required int dailyDeviationCount,
    required int sosCount,
    required int restructureCount,
    required int vacuumFocusCount,
  }) {
    if (totalCount == 0) {
      return '最近 7 天还没有趋势样本';
    }

    if (sosCount >= dailyDeviationCount && sosCount >= restructureCount) {
      return '情绪波动型样本更集中';
    }

    if (dailyDeviationCount >= restructureCount) {
      return '日常偏离型样本更集中';
    }

    if (vacuumFocusCount >= restructureCount) {
      return '真空专注完成样本正在增加';
    }

    return '重构锚点型样本更集中';
  }

  static String yearlyHighlight({
    required int sampleCount,
    required String checkinStability,
  }) {
    if (sampleCount == 0) {
      return '这一年还处在起步阶段，系统正在等待更多真实记录。';
    }

    if (checkinStability.contains('稳定回流')) {
      return '稳定开始变多，新的轨道正在被反复印证。';
    }

    if (checkinStability.contains('明显偏离')) {
      return '即使偏离较多，这一年也已经留下了足够多可复盘的证据。';
    }

    return '这一年最重要的变化，不是完美，而是你开始${archiveEvidencePhrase()}';
  }

  static HomeSuggestionCopy homeFocusActive(String remainingText) {
    return HomeSuggestionCopy(
      title: '先完成这段专注',
      body: remainingText,
      actionLabel: '回到专注页',
    );
  }

  static HomeSuggestionCopy homeNeedCheckin({
    required bool justEndedFocus,
  }) {
    return HomeSuggestionCopy(
      title: '先完成今日校验',
      body: justEndedFocus
          ? '你刚结束一段专注，先用一次温和校验把今天的状态记下来。'
          : '先做一次轻量校准，再决定今天接下来怎么走。',
      actionLabel: '去做校验',
    );
  }

  static HomeSuggestionCopy homeAfterSos(String minAction) {
    return HomeSuggestionCopy(
      title: '先把自己带回安静区',
      body: '刚刚那次 SOS 已经被接住了。现在不要急着证明什么，${focusThenReturnPhrase(minAction)}',
      actionLabel: '先去专注',
    );
  }

  static HomeSuggestionCopy homeAfterVacuumReturn(String minAction) {
    return HomeSuggestionCopy(
      title: '现在直接回到最小动作',
      body: '你刚完成一段真空专注，说明拉扯已经被放下来了。${returnToActionPhrase(minAction)}',
      actionLabel: '看回流记录',
    );
  }

  static HomeSuggestionCopy homeFullDeviation(String minAction) {
    return HomeSuggestionCopy(
      title: '先重启一段真空专注',
      body: '今天已经出现明显偏离，先不要硬推自己。先回到安静区，再回来只做最小动作：$minAction',
      actionLabel: '重启专注',
    );
  }

  static HomeSuggestionCopy homePartialDeviation(String minAction) {
    return HomeSuggestionCopy(
      title: '先把动作收小，再继续',
      body: '今天有一点被旧习惯拉走了，但不用补偿。${keepActionSmallPhrase(minAction)}',
      actionLabel: '看偏离记录',
    );
  }

  static HomeSuggestionCopy homeMatch(String minAction) {
    return HomeSuggestionCopy(
      title: '保持今天这条新轨道',
      body: '今天已经完成一次完全匹配，不需要再额外加码。${smallestActionPhrase(minAction)}',
      actionLabel: '看本周回流',
    );
  }

  static HomeSuggestionCopy homeRecentDailyDeviation(String minAction) {
    return HomeSuggestionCopy(
      title: '先进入一段真空专注',
      body: '最近一次记录还带着日常拉扯感。${focusThenReturnPhrase(minAction)}',
      actionLabel: '开始专注',
    );
  }

  static HomeSuggestionCopy homeWeeklyPositive({
    required int vacuumFocusCount,
    required int matchCount,
    required String minAction,
  }) {
    return HomeSuggestionCopy(
      title: '把今天这一个动作做稳',
      body: '这周已经出现 $vacuumFocusCount 次真空专注、$matchCount 次完全匹配。${smallestActionPhrase(minAction)}',
      actionLabel: '查看本周回流',
    );
  }

  static HomeSuggestionCopy homeFallback() {
    return const HomeSuggestionCopy(
      title: '先开始一段安静区',
      body: '如果还没想清楚今天从哪里开始，就先进入真空专注，让自己只面对眼前这一个动作。',
      actionLabel: '进入真空专注',
    );
  }

  static String insightsFilterLead(String filterKey) {
    return switch (filterKey) {
      'all' => '偏差=迭代数据，偏差≠失败。\n这里记录了最近 7 天被旧惯性拉扯的时刻。',
      'daily_deviation' => '这里聚焦每天的日常拉扯。先看清最常发生的偏离，再决定要把动作缩到哪里。',
      'sos' => '这里是最强烈拉扯被系统接住的时刻。先被接住，再慢慢回到今天这一小步。',
      'restructure' => '这里保存身份重构留下的锚点。${anchorPhrase()}',
      'vacuum_focus' => '这里记录你主动把自己带回来的证据。每一段完成的真空专注，都是回流正在发生。',
      _ => '这里记录了最近 7 天的状态样本。',
    };
  }

  static FilterContextCopy insightsFilterContext({
    required String filterKey,
    required int partialCount,
    required int fullDeviationCount,
    required int sosCount,
    required int restructureCount,
    required int focusCount,
  }) {
    return switch (filterKey) {
      'daily_deviation' => FilterContextCopy(
        eyebrow: '当前筛选：每日偏离',
        title: '先看日常拉扯最常从哪里开始',
        body: '最近 7 天记录到部分偏离 $partialCount 次、完全偏离 $fullDeviationCount 次。先识别最常见的偏离场景，再把动作收小。',
      ),
      'sos' => FilterContextCopy(
        eyebrow: '当前筛选：SOS',
        title: '先看那些最需要被接住的时刻',
        body: '最近 7 天触发 SOS $sosCount 次。这里不是失败记录，而是潜意识最强烈防御出现时，你依然留下来的证据。',
      ),
      'restructure' => FilterContextCopy(
        eyebrow: '当前筛选：首次重构',
        title: '先回到身份锚点，而不是只盯着偏离',
        body: '最近 7 天可见的重构锚点样本有 $restructureCount 条。它们提醒你为什么开始，以及现在要回到哪里。',
      ),
      'vacuum_focus' => FilterContextCopy(
        eyebrow: '当前筛选：真空专注',
        title: '先看你是怎么把自己带回来的',
        body: '最近 7 天已完成真空专注 $focusCount 次。这里呈现的不是拉扯本身，而是你主动回流、重新站稳的证据。',
      ),
      _ => const FilterContextCopy(
        eyebrow: '当前筛选：全部样本',
        title: '先从全貌看这一周发生了什么',
        body: '这里会同时看到偏离、SOS、重构锚点和真空专注。先看全貌，再决定今天更需要回到哪一类信号。',
      ),
    };
  }

  static FollowupCopy insightsFollowup({
    required String filterKey,
    String? sourceKey,
  }) {
    if (sourceKey == 'home_suggestion') {
      return switch (filterKey) {
        'all' => const FollowupCopy(
          title: '回首页，继续刚才那一个动作',
          body: '你是从首页建议卡进来的，全貌已经看够了。现在回首页，把那一个最小动作继续做完。',
          label: '回首页继续',
        ),
        'daily_deviation' => const FollowupCopy(
          title: '看清之后，回首页把动作收小',
          body: '这次偏离已经被看见了，不需要继续分析。回首页，只把今天那一个动作做得更小一点。',
          label: '回首页继续',
        ),
        'vacuum_focus' => const FollowupCopy(
          title: '接住这次回流，回首页行动',
          body: '刚完成真空专注后的记录已经看到了，现在不要停在复盘里，直接回首页继续那一个动作。',
          label: '回首页继续',
        ),
        _ => _defaultFollowup(filterKey),
      };
    }

    if (sourceKey == 'positive_signal' &&
        (filterKey == 'all' || filterKey == 'vacuum_focus')) {
      return const FollowupCopy(
        title: '把这股稳定继续带回今天',
        body: '这些正向信号已经足够说明你能把自己带回来。现在回首页，把今天的动作继续做稳。',
        label: '回首页行动',
      );
    }

    return _defaultFollowup(filterKey);
  }

  static String insightsFollowupEyebrow(String? sourceKey) {
    return switch (sourceKey) {
      'home_suggestion' => '回到首页前',
      'weekly_summary' => '看完全貌之后',
      'positive_signal' => '接住这次稳定',
      'home_archive' => '看完之后',
      _ => '看完之后',
    };
  }

  static EntrySourceCopy insightsEntrySource({
    required String sourceKey,
    required String filterLabel,
  }) {
    return switch (sourceKey) {
      'home_archive' => const EntrySourceCopy(
        eyebrow: '来自首页样本入口',
        title: '先快速看一眼最近 7 天的记录',
        body: '你是从首页右上角的样本入口进来的。这里更适合快速扫一眼全貌，不需要停太久。',
      ),
      'weekly_summary' => EntrySourceCopy(
        eyebrow: '来自首页本周摘要',
        title: '先借 $filterLabel 看清这一周的节奏',
        body: '你是从首页的本周摘要进来的。先看清这一类信号在最近 7 天如何出现，再决定下一步回到哪里。',
      ),
      'positive_signal' => const EntrySourceCopy(
        eyebrow: '来自首页正向回流',
        title: '先看自己最近是怎么把状态带回来的',
        body: '你是顺着首页的正向信号进来的。这里更适合看清哪些动作正在把你稳稳带回新的轨道。',
      ),
      'home_suggestion' => const EntrySourceCopy(
        eyebrow: '来自首页建议卡',
        title: '这里先帮你看清刚才那一步为什么重要',
        body: '你是被首页建议带到这里的。看清当前这类记录后，就回去继续刚才那一个最小动作，不需要停留太久。',
      ),
      _ => const EntrySourceCopy(
        eyebrow: '来自首页',
        title: '先看清这一段记录',
        body: '这里适合快速看清最近的状态变化，然后回到今天的动作。',
      ),
    };
  }

  static FollowupCopy _defaultFollowup(String filterKey) {
    return switch (filterKey) {
      'daily_deviation' => const FollowupCopy(
        title: '回去做一次温和校验',
        body: '偏离被看见之后，下一步不是自责，而是回到今天的状态校准。',
        label: '去做校验',
      ),
      'sos' => FollowupCopy(
        title: '先回到安静区，再做下一步',
        body: '看完这些强烈拉扯后，不需要立刻证明自己。${focusActionPhrase()}',
        label: '先去专注',
      ),
      'restructure' => FollowupCopy(
        title: '回到身份锚点，再往前走',
        body: '这些重构记录提醒了你为什么开始。${rebuildAnchorPhrase()}',
        label: '回到重构',
      ),
      'vacuum_focus' => const FollowupCopy(
        title: '别停在复盘里，回去做动作',
        body: '这些专注完成记录已经说明你能把自己带回来。现在回首页，把今天的最小动作做稳。',
        label: '回首页行动',
      ),
      _ => const FollowupCopy(
        title: '回到首页，只做今天这一个动作',
        body: '全貌已经看过了，不用再继续分析。现在回到首页，把最小动作做完。',
        label: '回首页继续',
      ),
    };
  }

  static SettingsCopy settingsPage() {
    return CopyStrategy.settings();
  }

  static String settingsBackupExported(String path) {
    return '本地备份已导出到：$path';
  }

  static String settingsBackupExportFailed() {
    return '本地备份导出失败，请稍后再试。';
  }

  static String settingsBackupRestored(String path) {
    return '已从最近备份恢复：$path';
  }

  static String settingsBackupRestoreFailed() {
    return '本地备份恢复失败，请稍后再试。';
  }

  static String settingsFocusSettingsLoading() {
    return '正在读取本地设置...';
  }

  static String settingsFocusSettingsError() {
    return '本地设置暂时未展开';
  }

  static String settingsFocusStatusLoading() {
    return '正在读取本地专注状态...';
  }

  static String settingsFocusStatusError() {
    return '专注状态暂时未展开';
  }

  static String settingsDebugLoading() {
    return '正在整理本地调试信息...';
  }

  static String settingsDebugError() {
    return '调试信息暂时没有展开，但本地数据仍然保留在设备里。';
  }

  static String settingsBackupExporting() {
    return '导出中...';
  }

  static String settingsBackupExportLabel() {
    return '导出本地备份';
  }

  static String settingsBackupRestoring() {
    return '恢复中...';
  }

  static String settingsBackupRestoreLabel() {
    return '从最近备份恢复';
  }

  static String settingsOpenFocusPageLabel() {
    return '打开专注页';
  }

  static String settingsFocusSummary({
    required bool isActive,
    int? remainingMinutes,
    int? plannedMinutes,
    bool hasStartedAt = false,
    DateTime? lastEndedAt,
  }) {
    if (isActive) {
      if (remainingMinutes != null && plannedMinutes != null) {
        return '这一段原计划 $plannedMinutes 分钟，目前还剩约 $remainingMinutes 分钟。';
      }

      if (hasStartedAt) {
        return '这段专注已经开始，首页和洞察页会同步感知当前状态。';
      }

      return '这段专注已经开始，先把自己留在当前动作里。';
    }

    if (lastEndedAt != null) {
      final hour = lastEndedAt.hour.toString().padLeft(2, '0');
      final minute = lastEndedAt.minute.toString().padLeft(2, '0');
      return '上一段真空专注结束于 $hour:$minute，可以随时再开始一段安静区。';
    }

    return '还没有开始过新的真空专注，可以从这里直接进入一段安静区。';
  }

  static ArchivePageCopy restructureArchivePage() {
    return const ArchivePageCopy(
      title: '重构归档',
      subtitle: '把每一次身份重构留下来。这里先收纳当前锚点、历史版本和年度归档。',
      historyTitle: '历史重构记录',
      yearlyReportTitle: '年度变化报告',
      yearlyArchiveTitle: '年度归档',
      historyLoading: '正在整理你的重构归档...',
      historyError: '重构归档暂时没有展开，但当前身份和动作仍然保存在本地。',
      yearlyLoading: '正在整理年度归档...',
      yearlyError: '年度归档暂时没有展开，但历史重构仍然保存在本地。',
      yearlyReportLoading: '正在生成年度变化报告...',
      yearlyReportError: '年度变化报告暂时没有展开，但年度归档仍然保存在本地。',
      currentIdentityBadge: '当前身份锚点',
      refreshIdentityLabel: '重新做一次身份重构',
      historyEmptyTitle: '还没有更多历史版本',
      historyEmptyBody: '当前这次首次重构已经被保留下来了。后续每一次新的身份重构，都会继续沉淀在这里。',
      yearlyEmptyTitle: '年度归档还没有展开',
      yearlyEmptyBody: '当你有年度身份快照后，这里会按年份沉淀身份、信念和样本总量。',
      minActionLabel: '当前最小动作',
      yearlyIdentityLabel: '年度身份快照',
      yearlyBeliefLabel: '年度信念快照',
      yearlySampleCountLabel: '年度样本总量',
      yearlyStabilityLabel: '年度校验稳定度',
    );
  }

  static String restructureLatestRecordSummary({
    required String periodLabel,
    required String? minAction,
  }) {
    final action = minAction == null || minAction.trim().isEmpty
        ? '还没有写下最小动作'
        : '最近绑定的动作是：${minAction.trim()}';
    return '$periodLabel 的身份重构已经落地。$action';
  }

  static String restructureArchiveRecordTitle(String? year) {
    if (year != null && year.isNotEmpty) {
      return '$year 重构版本';
    }
    return '历史版本';
  }

  static String restructureArchiveRecordTime(DateTime? createdAt) {
    if (createdAt == null) {
      return '时间未记录';
    }

    final month = createdAt.month.toString().padLeft(2, '0');
    final day = createdAt.day.toString().padLeft(2, '0');
    return '$month-$day';
  }

  static String restructureYearlyArchiveTime(DateTime? createdAt) {
    if (createdAt == null) {
      return '归档时间未记录';
    }

    final month = createdAt.month.toString().padLeft(2, '0');
    final day = createdAt.day.toString().padLeft(2, '0');
    return '$month-$day 归档';
  }

  static String archiveFieldEmpty() {
    return '暂无记录';
  }
}

class CheckinCopy {
  const CheckinCopy({
    required this.optionLabel,
    required this.sampleStatusTag,
    required this.systemComment,
    required this.completionTitle,
    required this.completionBody,
  });

  final String optionLabel;
  final String sampleStatusTag;
  final String systemComment;
  final String completionTitle;
  final String completionBody;
}

class HomeSuggestionCopy {
  const HomeSuggestionCopy({
    required this.title,
    required this.body,
    required this.actionLabel,
  });

  final String title;
  final String body;
  final String actionLabel;
}

class FilterContextCopy {
  const FilterContextCopy({
    required this.eyebrow,
    required this.title,
    required this.body,
  });

  final String eyebrow;
  final String title;
  final String body;
}

class FollowupCopy {
  const FollowupCopy({
    required this.title,
    required this.body,
    required this.label,
  });

  final String title;
  final String body;
  final String label;
}

class EntrySourceCopy {
  const EntrySourceCopy({
    required this.eyebrow,
    required this.title,
    required this.body,
  });

  final String eyebrow;
  final String title;
  final String body;
}

class SettingsCopy {
  const SettingsCopy({
    required this.flowSectionTitle,
    required this.vacuumSectionTitle,
    required this.focusSectionTitle,
    required this.debugDbPath,
    required this.debugRecentSamples,
    required this.debugTotalSamples,
    required this.debugCheckinCount,
    required this.debugDraftStatus,
    required this.debugRecentCheckinDate,
    required this.debugLatestExport,
    required this.debugExportContents,
    required this.debugExportTime,
    required this.debugLatestRestore,
    required this.debugRestoreContents,
    required this.debugRestoreTime,
    required this.debugCountSuffix,
    required this.debugTimestampTemplate,
    required this.title,
    required this.subtitle,
    required this.backupTitle,
    required this.backupBody,
    required this.focusPanelTitle,
    required this.focusPanelBody,
    required this.resetLabel,
    required this.resettingLabel,
    required this.debugPanelTitle,
  });

  final String flowSectionTitle;
  final String vacuumSectionTitle;
  final String focusSectionTitle;
  final String debugDbPath;
  final String debugRecentSamples;
  final String debugTotalSamples;
  final String debugCheckinCount;
  final String debugDraftStatus;
  final String debugRecentCheckinDate;
  final String debugLatestExport;
  final String debugExportContents;
  final String debugExportTime;
  final String debugLatestRestore;
  final String debugRestoreContents;
  final String debugRestoreTime;
  final String debugCountSuffix;
  final String debugTimestampTemplate;
  final String title;
  final String subtitle;
  final String backupTitle;
  final String backupBody;
  final String focusPanelTitle;
  final String focusPanelBody;
  final String resetLabel;
  final String resettingLabel;
  final String debugPanelTitle;
}

class ArchivePageCopy {
  const ArchivePageCopy({
    required this.title,
    required this.subtitle,
    required this.historyTitle,
    required this.yearlyReportTitle,
    required this.yearlyArchiveTitle,
    required this.historyLoading,
    required this.historyError,
    required this.yearlyLoading,
    required this.yearlyError,
    required this.yearlyReportLoading,
    required this.yearlyReportError,
    required this.currentIdentityBadge,
    required this.refreshIdentityLabel,
    required this.historyEmptyTitle,
    required this.historyEmptyBody,
    required this.yearlyEmptyTitle,
    required this.yearlyEmptyBody,
    required this.minActionLabel,
    required this.yearlyIdentityLabel,
    required this.yearlyBeliefLabel,
    required this.yearlySampleCountLabel,
    required this.yearlyStabilityLabel,
  });

  final String title;
  final String subtitle;
  final String historyTitle;
  final String yearlyReportTitle;
  final String yearlyArchiveTitle;
  final String historyLoading;
  final String historyError;
  final String yearlyLoading;
  final String yearlyError;
  final String yearlyReportLoading;
  final String yearlyReportError;
  final String currentIdentityBadge;
  final String refreshIdentityLabel;
  final String historyEmptyTitle;
  final String historyEmptyBody;
  final String yearlyEmptyTitle;
  final String yearlyEmptyBody;
  final String minActionLabel;
  final String yearlyIdentityLabel;
  final String yearlyBeliefLabel;
  final String yearlySampleCountLabel;
  final String yearlyStabilityLabel;
}
