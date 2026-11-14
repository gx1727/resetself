import 'package:flutter/material.dart';

import '../../data/models/restructure_archive_record.dart';

/// A saved direction, distinct from the current editable draft.
class DirectionSummary extends StatelessWidget {
  const DirectionSummary({
    required this.record,
    this.title = '查看完整方向',
    super.key,
  });
  final RestructureArchiveRecord record;
  final String title;

  @override
  Widget build(BuildContext context) => Card(
    child: ExpansionTile(
      title: Text(title),
      subtitle: Text(
        record.monthProject.trim().isEmpty
            ? '月项目尚未填写'
            : '月项目：${record.monthProject}',
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        for (final field in directionFields(record))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${field.$1}\n${field.$2.trim().isEmpty ? '尚未填写' : field.$2}',
              ),
            ),
          ),
      ],
    ),
  );
}

List<(String, String)> directionFields(RestructureArchiveRecord r) => [
  ('反愿景', r.antiVision),
  ('愿景', r.visionText),
  ('一年目标', r.yearGoal),
  ('一月项目', r.monthProject),
  ('每日杠杆', r.dailyLevers),
  ('价值约束', r.valueConstraints),
  ('身份表达', r.identityDraft),
  ('最小启动行动', r.minActionDraft),
  ('环境避坑规则', r.constraints),
  ('自我保护', r.fearContent),
  ('待核对的内部模式', r.beliefDraft),
  if (r.changeReason.trim().isNotEmpty) ('这次调整的原因', r.changeReason),
];

String directionSnapshot(
  RestructureArchiveRecord record, {
  required String minAction,
}) => [
  '方向记录 #${record.id}',
  for (final field in directionFields(record))
    if (field.$2.trim().isNotEmpty && field.$1 != '最小启动行动')
      '${field.$1}：${field.$2}',
  if (minAction.trim().isNotEmpty) '当前最小启动行动：$minAction',
].join('\n');
