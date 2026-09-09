import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:money_control/Config/feature_flags.dart';
import 'package:money_control/Controllers/privacy_controller.dart';
import 'package:money_control/Services/biometric_service.dart';
import 'package:money_control/Services/feature_flag_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeFeatureFlagService extends FeatureFlagService {
  @override
  void onInit() {
    super.onInit();
    adminOverride = false;
  }

  @override
  void startRealtime() {}
}

void main() {
  setUp(() {
    Get.reset();
    SharedPreferences.setMockInitialValues({});
    Get.put<FeatureFlagService>(_FakeFeatureFlagService());
  });

  group('BiometricService.lockActive', () {
    test('false when the user never enabled the lock', () {
      final bio = BiometricService();
      expect(bio.lockActive, isFalse);
    });

    test('true when enabled and the feature is available', () {
      final bio = BiometricService()..isBiometricEnabled.value = true;
      expect(bio.lockActive, isTrue);
    });

    test('false when enabled but the admin hid biometric_app_lock', () {
      FeatureFlagService.to
          .applyRaw({'biometric_app_lock': FeatureStatus.hidden});
      final bio = BiometricService()..isBiometricEnabled.value = true;
      expect(bio.lockActive, isFalse);
    });
  });

  group('PrivacyController.toggle', () {
    test('toggles normally when the feature is enabled', () {
      final privacy = PrivacyController();
      expect(privacy.isPrivacyMode.value, isFalse);
      privacy.toggle();
      expect(privacy.isPrivacyMode.value, isTrue);
    });

    test('no-ops when an admin hid privacy_mode', () {
      FeatureFlagService.to
          .applyRaw({'privacy_mode': FeatureStatus.hidden});
      final privacy = PrivacyController();
      privacy.toggle();
      expect(privacy.isPrivacyMode.value, isFalse);
    });

    test('toggles again once the feature is re-enabled', () {
      FeatureFlagService.to
          .applyRaw({'privacy_mode': FeatureStatus.hidden});
      final privacy = PrivacyController();
      privacy.toggle();
      expect(privacy.isPrivacyMode.value, isFalse);
      FeatureFlagService.to
          .applyRaw({'privacy_mode': FeatureStatus.enabled});
      privacy.toggle();
      expect(privacy.isPrivacyMode.value, isTrue);
    });
  });
}