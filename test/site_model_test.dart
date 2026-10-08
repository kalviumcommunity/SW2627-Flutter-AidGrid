import 'package:flutter_test/flutter_test.dart';
import 'package:food_distribution_app/models/site.dart';

void main() {
  group('Site Model Tests', () {
    test('Site fromMap correctly parses standard integer values', () {
      final data = {
        'name': 'Jaipur North',
        'location': 'Jaipur, Rajasthan',
        'beneficiaries': 120,
        'isActive': true,
      };

      final site = Site.fromMap(data, 'doc_123');

      expect(site.id, equals('doc_123'));
      expect(site.name, equals('Jaipur North'));
      expect(site.location, equals('Jaipur, Rajasthan'));
      expect(site.beneficiaries, equals(120));
      expect(site.isActive, isTrue);
    });

    test('Site fromMap handles string and null values gracefully', () {
      final data = {
        'name': '   Ajmer Central   ',
        'location': ' Ajmer, Rajasthan ',
        'beneficiaries': '150',
        'isActive': false,
      };

      final site = Site.fromMap(data, 'doc_456');

      expect(site.name, equals('Ajmer Central'));
      expect(site.location, equals('Ajmer, Rajasthan'));
      expect(site.beneficiaries, equals(150));
      expect(site.isActive, isFalse);
    });

    test('Site toMap serializes fields correctly', () {
      const site = Site(
        id: 'doc_789',
        name: 'Jaipur South',
        location: 'Jaipur, Rajasthan',
        beneficiaries: 85,
        isActive: true,
      );

      final map = site.toMap();

      expect(map['name'], equals('Jaipur South'));
      expect(map['location'], equals('Jaipur, Rajasthan'));
      expect(map['beneficiaries'], equals(85));
      expect(map['isActive'], isTrue);
    });

    test('Site copyWith updates values as expected', () {
      const site = Site(
        id: 'doc_1',
        name: 'Old Name',
        location: 'Old Location',
        beneficiaries: 50,
        isActive: false,
      );

      final updated = site.copyWith(
        name: 'New Name',
        beneficiaries: 100,
        isActive: true,
      );

      expect(updated.id, equals('doc_1'));
      expect(updated.name, equals('New Name'));
      expect(updated.location, equals('Old Location'));
      expect(updated.beneficiaries, equals(100));
      expect(updated.isActive, isTrue);
    });
  });
}
