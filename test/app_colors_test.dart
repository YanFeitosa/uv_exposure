import 'package:flutter_test/flutter_test.dart';
import 'package:uv_exposure_app/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

void main() {
  group('AppColors', () {
    group('getUVIndexColor', () {
      test('should return green for UV index 0-2', () {
        expect(AppColors.getUVIndexColor(0), equals(AppColors.uvLow));
        expect(AppColors.getUVIndexColor(1), equals(AppColors.uvLow));
        expect(AppColors.getUVIndexColor(2), equals(AppColors.uvLow));
      });

      test('should return yellow for UV index 3-5', () {
        expect(AppColors.getUVIndexColor(3), equals(AppColors.uvModerate));
        expect(AppColors.getUVIndexColor(4), equals(AppColors.uvModerate));
        expect(AppColors.getUVIndexColor(5), equals(AppColors.uvModerate));
      });

      test('should return orange for UV index 6-7', () {
        expect(AppColors.getUVIndexColor(6), equals(AppColors.uvHigh));
        expect(AppColors.getUVIndexColor(7), equals(AppColors.uvHigh));
      });

      test('should return red for UV index 8-10', () {
        expect(AppColors.getUVIndexColor(8), equals(AppColors.uvVeryHigh));
        expect(AppColors.getUVIndexColor(9), equals(AppColors.uvVeryHigh));
        expect(AppColors.getUVIndexColor(10), equals(AppColors.uvVeryHigh));
      });

      test('should return purple for UV index 11+', () {
        expect(AppColors.getUVIndexColor(11), equals(AppColors.uvExtreme));
        expect(AppColors.getUVIndexColor(15), equals(AppColors.uvExtreme));
      });
    });

    group('getExposureColor', () {
      test('should return green-ish for low exposure (0-25%)', () {
        final color = AppColors.getExposureColor(10);
        // Should be closer to green
        expect(color.green, greaterThan(color.red));
      });

      test('should return yellow-ish for medium exposure (50%)', () {
        final color = AppColors.getExposureColor(50);
        // Should be yellow (high red and green, low blue)
        expect(color.value, equals(AppColors.exposureWarning.value));
      });

      test('should return red-ish for high exposure (75-100%)', () {
        final color = AppColors.getExposureColor(90);
        // Should be closer to red
        expect(color.red, greaterThan(color.green));
      });
    });
  });

  group('AppColors constants', () {
    test('should have correct primary color', () {
      expect(AppColors.primary, equals(const Color(0xFFFFCE26)));
    });

    test('should have correct secondary color', () {
      expect(AppColors.secondary, equals(const Color(0xFF77347A)));
    });
  });
}
