import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/database_providers.dart';
import '../../data/models/restructure_draft.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/user_profile_repository.dart';

final appControllerProvider = ChangeNotifierProvider<AppController>((ref) {
  return AppController(ref.watch(userProfileRepositoryProvider));
});

class AppController extends ChangeNotifier {
  AppController(this._repository) {
    unawaited(init());
  }

  AppController.test({
    UserProfile? profile,
    bool isInitializing = false,
    bool isSaving = false,
    String? errorMessage,
  })  : _repository = null,
        _profile = profile,
        _isInitializing = isInitializing,
        _isSaving = isSaving,
        _errorMessage = errorMessage;

  final UserProfileRepository? _repository;

  UserProfile? _profile;
  bool _didInit = false;
  bool _isInitializing = true;
  bool _isSaving = false;
  String? _errorMessage;

  UserProfile get profile => _profile ?? UserProfile.empty();
  bool get isInitializing => _isInitializing;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  bool get hasCompletedInitialRestructure => profile.hasCompletedInitialRestructure;

  Future<void> init() async {
    // 已经成功初始化过就不再重复；但失败后允许通过"重新初始化"重试。
    if (_repository == null || (_didInit && _errorMessage == null)) {
      _isInitializing = false;
      notifyListeners();
      return;
    }

    _didInit = true;
    _isInitializing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.ensureSingleProfile();
      _profile = await _repository.getCurrentProfile();
    } catch (error, stackTrace) {
      debugPrint('[init] failed: $error');
      debugPrint('$stackTrace');
      _errorMessage = error.toString();
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> submitInitialRestructure(RestructureDraft draft) async {
    final repository = _repository;
    if (repository == null || _isSaving) {
      return;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await repository.submitInitialRestructure(draft);
      _profile = await repository.getCurrentProfile();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> resetExperience() async {
    final repository = _repository;
    if (repository == null || _isSaving) {
      return;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await repository.resetToOnboarding();
      _profile = await repository.getCurrentProfile();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> reloadProfile() async {
    final repository = _repository;
    if (repository == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await repository.getCurrentProfile();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      notifyListeners();
    }
  }
}
