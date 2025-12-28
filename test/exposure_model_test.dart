import 'package:flutter_test/flutter_test.dart';
import 'package:uv_exposure_app/core/models/exposure_model.dart';

void main() {
  group('ExposureModel', () {
    late ExposureModel model;

    setUp(() {
      model = ExposureModel(spf: 30, skinType: 'Type II - Fair');
    });

    test('should initialize with correct TEP for skin type', () {
      expect(model.tep, equals(15.0));
    });

    test('should initialize with correct SPF', () {
      expect(model.spf, equals(30.0));
    });

    test('should start with 0% accumulated exposure', () {
      expect(model.accumulatedExposurePercent, equals(0.0));
    });

    test('should calculate initial safe exposure time correctly', () {
      // SPF 30 * TEP 15 / UV 5 = 90 minutes = 5400 seconds
      final safeTime = model.calculateInitialSafeExposureTime(5.0);
      expect(safeTime, equals(5400));
    });

    test('should handle zero UV index in safe exposure calculation', () {
      // Should default to UV 1
      final safeTime = model.calculateInitialSafeExposureTime(0.0);
      // SPF 30 * TEP 15 / UV 1 = 450 minutes = 27000 seconds
      expect(safeTime, equals(27000));
    });

    test('should accumulate exposure correctly', () {
      // UV 5, 60 seconds
      // Exposure = (5 * 60) / (15 * 30 * 60) = 300 / 27000 ≈ 0.0111%
      model.accumulateExposure(5.0, 60);
      expect(model.accumulatedExposurePercent, closeTo(0.0111, 0.001));
    });

    test('should not accumulate exposure for zero UV index', () {
      model.accumulateExposure(0.0, 60);
      expect(model.accumulatedExposurePercent, equals(0.0));
    });

    test('should detect warning threshold', () {
      model.setAccumulatedExposure(74.9);
      expect(model.isWarning, isFalse);
      
      model.setAccumulatedExposure(75.0);
      expect(model.isWarning, isTrue);
    });

    test('should detect critical threshold', () {
      model.setAccumulatedExposure(99.9);
      expect(model.isCritical, isFalse);
      
      model.setAccumulatedExposure(100.0);
      expect(model.isCritical, isTrue);
    });

    test('should reset accumulated exposure', () {
      model.setAccumulatedExposure(50.0);
      model.reset();
      expect(model.accumulatedExposurePercent, equals(0.0));
    });

    test('should calculate remaining safe time correctly', () {
      // After 300 seconds at UV 5
      model.accumulateExposure(5.0, 300);
      final remaining = model.calculateRemainingSafeTime(300);
      expect(remaining, greaterThan(0));
    });
  });

  group('ExposureModel with different skin types', () {
    test('should have correct TEP for Type I - Very Fair', () {
      final model = ExposureModel(spf: 30, skinType: 'Type I - Very Fair');
      expect(model.tep, equals(7.5));
    });

    test('should have correct TEP for Type III - Medium Fair', () {
      final model = ExposureModel(spf: 30, skinType: 'Type III - Medium Fair');
      expect(model.tep, equals(25.0));
    });

    test('should have correct TEP for Type VI - Very Dark', () {
      final model = ExposureModel(spf: 30, skinType: 'Type VI - Very Dark');
      expect(model.tep, equals(75.0));
    });

    test('should use default TEP for unknown skin type', () {
      final model = ExposureModel(spf: 30, skinType: 'Unknown Type');
      expect(model.tep, equals(15.0)); // Default
    });
  });

  group('ExposureSession', () {
    test('should calculate duration correctly', () {
      final startTime = DateTime(2025, 1, 1, 10, 0, 0);
      final endTime = DateTime(2025, 1, 1, 11, 30, 0);
      
      final session = ExposureSession(
        id: '1',
        startTime: startTime,
        endTime: endTime,
        spf: 30,
        skinType: 'Type II - Fair',
        maxExposurePercent: 50,
        maxUVIndex: 7,
      );
      
      expect(session.duration, equals(const Duration(hours: 1, minutes: 30)));
    });

    test('should serialize and deserialize correctly', () {
      final original = ExposureSession(
        id: 'test-123',
        startTime: DateTime(2025, 1, 1, 10, 0, 0),
        endTime: DateTime(2025, 1, 1, 11, 0, 0),
        spf: 50,
        skinType: 'Type III - Medium Fair',
        maxExposurePercent: 75.5,
        maxUVIndex: 8.5,
        readings: [
          UVReading(uvIndex: 7, timestamp: DateTime(2025, 1, 1, 10, 30, 0)),
        ],
      );
      
      final json = original.toJson();
      final restored = ExposureSession.fromJson(json);
      
      expect(restored.id, equals(original.id));
      expect(restored.spf, equals(original.spf));
      expect(restored.skinType, equals(original.skinType));
      expect(restored.maxExposurePercent, equals(original.maxExposurePercent));
      expect(restored.maxUVIndex, equals(original.maxUVIndex));
      expect(restored.readings.length, equals(1));
    });
  });

  group('UVReading', () {
    test('should serialize and deserialize correctly', () {
      final original = UVReading(
        uvIndex: 6.5,
        timestamp: DateTime(2025, 1, 1, 12, 0, 0),
      );
      
      final json = original.toJson();
      final restored = UVReading.fromJson(json);
      
      expect(restored.uvIndex, equals(original.uvIndex));
      expect(restored.timestamp, equals(original.timestamp));
    });
  });
}
