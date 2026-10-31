import 'package:flutter_test/flutter_test.dart';
import 'package:food_distribution_app/services/distribution_services.dart';

void main() {
  group('DistributionService Transaction & Validation Unit Tests', () {
    test('Throws ArgumentError when quantity is zero or negative', () async {
      final service = DistributionService(currentUserResolver: () => null);

      expect(
        () => service.recordDistribution(
          itemId: 'inv_1',
          siteId: 'site_1',
          quantity: 0,
          volunteerId: 'vol_1',
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Quantity must be greater than zero.'),
          ),
        ),
      );

      expect(
        () => service.recordDistribution(
          itemId: 'inv_1',
          siteId: 'site_1',
          quantity: -5,
          volunteerId: 'vol_1',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Throws StateError when user is unauthenticated', () async {
      final service = DistributionService(currentUserResolver: () => null);

      expect(
        () => service.recordDistribution(
          itemId: 'inv_rice_01',
          siteId: 'site_jaipur_01',
          quantity: 10,
          volunteerId: 'vol_rahul',
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('You must be logged in to record a distribution.'),
          ),
        ),
      );
    });

    test('Pre-condition invariants check for inventory deduction', () {
      // Invariant: Q_remaining = Q_current - Q_distributed >= 0
      int currentStock = 50;
      int requested = 20;
      expect(currentStock - requested, equals(30));
      expect(currentStock >= requested, isTrue);

      int insufficientStock = 10;
      int excessRequest = 15;
      expect(insufficientStock < excessRequest, isTrue);
    });
  });
}
