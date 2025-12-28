import 'package:flutter_test/flutter_test.dart';
import 'package:uv_exposure_app/core/constants/app_constants.dart';
import 'package:uv_exposure_app/core/constants/app_strings.dart';

void main() {
  group('AppConstants', () {
    test('should have correct TEP values for all skin types', () {
      expect(AppConstants.tepBySkinType['Type 0 - Test'], equals(0.1));
      expect(AppConstants.tepBySkinType['Type I - Very Fair'], equals(7.5));
      expect(AppConstants.tepBySkinType['Type II - Fair'], equals(15.0));
      expect(AppConstants.tepBySkinType['Type III - Medium Fair'], equals(25.0));
      expect(AppConstants.tepBySkinType['Type IV - Medium Dark'], equals(35.0));
      expect(AppConstants.tepBySkinType['Type V - Dark'], equals(50.0));
      expect(AppConstants.tepBySkinType['Type VI - Very Dark'], equals(75.0));
    });

    test('should have correct threshold values', () {
      expect(AppConstants.exposureWarningThreshold, equals(75.0));
      expect(AppConstants.exposureCriticalThreshold, equals(100.0));
    });

    test('should have correct timeout durations', () {
      expect(AppConstants.httpTimeout, equals(const Duration(seconds: 10)));
      expect(AppConstants.connectionCheckTimeout, equals(const Duration(seconds: 5)));
      expect(AppConstants.dataFetchInterval, equals(const Duration(seconds: 1)));
    });

    test('should have device URL configuration', () {
      expect(AppConstants.deviceBaseUrl, equals('http://sunsense.local'));
      expect(AppConstants.deviceDataEndpoint, equals('/data'));
    });
  });

  group('AppStrings', () {
    test('should have correct app name', () {
      expect(AppStrings.appName, equals('SunSense'));
      expect(AppStrings.appTitle, equals('SUNSENSE'));
    });

    test('should have all skin types', () {
      expect(AppStrings.skinTypes.length, equals(7));
      expect(AppStrings.skinTypes, contains('Type I - Very Fair'));
      expect(AppStrings.skinTypes, contains('Type VI - Very Dark'));
    });

    test('should have all SPF values', () {
      expect(AppStrings.spfValues, equals(['15', '30', '50', '70']));
    });

    test('should have notification strings', () {
      expect(AppStrings.notificationChannelId, isNotEmpty);
      expect(AppStrings.exposureWarningTitle, isNotEmpty);
      expect(AppStrings.exposureCriticalTitle, isNotEmpty);
    });
  });
}
