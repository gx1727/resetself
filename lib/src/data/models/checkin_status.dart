import '../../core/copy/neutral_copy_engine.dart';

enum CheckinStatus {
  match(
    value: 'match',
    shouldCreateSample: false,
  ),
  partial(
    value: 'partial',
    shouldCreateSample: true,
  ),
  fullDeviation(
    value: 'full_deviation',
    shouldCreateSample: true,
  );

  const CheckinStatus({
    required this.value,
    required this.shouldCreateSample,
  });

  final String value;
  final bool shouldCreateSample;

  String get optionLabel => NeutralCopyEngine.checkin(value).optionLabel;
  String get sampleStatusTag => NeutralCopyEngine.checkin(value).sampleStatusTag;
  String get systemComment => NeutralCopyEngine.checkin(value).systemComment;
  String get completionTitle => NeutralCopyEngine.checkin(value).completionTitle;
  String get completionBody => NeutralCopyEngine.checkin(value).completionBody;
}
