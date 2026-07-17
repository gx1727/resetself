import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/database_providers.dart';
import '../../../data/models/vacuum_focus_state.dart';
import '../../../data/models/vacuum_mode_settings.dart';

final vacuumModeSettingsProvider =
    FutureProvider.autoDispose<VacuumModeSettings>((ref) {
  return ref.watch(userProfileRepositoryProvider).getVacuumModeSettings();
});

final vacuumFocusStateProvider =
    FutureProvider.autoDispose<VacuumFocusState>((ref) {
  return ref.watch(userProfileRepositoryProvider).getVacuumFocusState();
});
