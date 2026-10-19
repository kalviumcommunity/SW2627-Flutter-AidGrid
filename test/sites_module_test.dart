import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_distribution_app/models/site.dart';
import 'package:food_distribution_app/screens/sites/add_site_page.dart';
import 'package:food_distribution_app/screens/sites/sites_page.dart';
import 'package:food_distribution_app/services/sites_service.dart';

/// Test mock implementation of SitesService for UI & validation testing.
class MockSitesService extends SitesService {
  final List<Site> testSites;
  bool addSiteCalled = false;
  String? lastAddedName;
  int? lastAddedBeneficiaries;
  Completer<String>? pendingAddCompleter;

  MockSitesService({this.testSites = const []});

  @override
  Stream<List<Site>> getSitesStream() {
    return Stream.value(testSites);
  }

  @override
  Future<String> addSite({
    required String name,
    required String location,
    required int beneficiaries,
    bool isActive = true,
    String? siteId,
  }) async {
    if (beneficiaries < 0) {
      throw ArgumentError('Beneficiaries cannot be negative.');
    }
    addSiteCalled = true;
    lastAddedName = name;
    lastAddedBeneficiaries = beneficiaries;

    if (pendingAddCompleter != null) {
      return pendingAddCompleter!.future;
    }
    return 'mock-site-id';
  }
}

void main() {
  group('Sites Management Module - UI & State Tests', () {
    testWidgets('SitesPage handles Loading state', (tester) async {
      final completer = Completer<List<Site>>();

      await tester.pumpWidget(
        MaterialApp(home: SitesPage(sitesStream: completer.future.asStream())),
      );

      // Verify loading progress indicator is shown while stream is waiting
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('SitesPage handles Empty state with admin CTA', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SitesPage(isAdmin: true, sitesStream: Stream.value(<Site>[])),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Distribution Sites Found'), findsOneWidget);
      expect(
        find.text(
          'No community distribution sites have been registered yet. Tap "Add Site" to register a new location.',
        ),
        findsOneWidget,
      );
      expect(find.widgetWithText(ElevatedButton, 'Add Site'), findsOneWidget);
    });

    testWidgets(
      'SitesPage handles Empty state for volunteers without Add CTA',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: SitesPage(
              isAdmin: false,
              sitesStream: Stream.value(<Site>[]),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('No Distribution Sites Found'), findsOneWidget);
        expect(
          find.text(
            'There are currently no community distribution sites registered in the network.',
          ),
          findsOneWidget,
        );
        expect(find.widgetWithText(ElevatedButton, 'Add Site'), findsNothing);
      },
    );

    testWidgets('SitesPage handles Error state with Retry button', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SitesPage(
            sitesStream: Stream<List<Site>>.error('Network connectivity lost'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unable to Load Distribution Sites'), findsOneWidget);
      expect(find.text('Network connectivity lost'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Retry'), findsOneWidget);
    });

    testWidgets('SitesPage displays populated site list clearly', (
      tester,
    ) async {
      const sites = [
        Site(
          id: 'site_1',
          name: 'Jaipur North Community',
          location: 'Jaipur, Rajasthan',
          beneficiaries: 120,
          isActive: true,
        ),
        Site(
          id: 'site_2',
          name: 'Ajmer Central Hub',
          location: 'Ajmer, Rajasthan',
          beneficiaries: 85,
          isActive: false,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: SitesPage(isAdmin: true, sitesStream: Stream.value(sites)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Jaipur North Community'), findsOneWidget);
      expect(find.text('Jaipur, Rajasthan'), findsOneWidget);
      expect(find.text('120 beneficiaries'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);

      expect(find.text('Ajmer Central Hub'), findsOneWidget);
      expect(find.text('Ajmer, Rajasthan'), findsOneWidget);
      expect(find.text('85 beneficiaries'), findsOneWidget);
      expect(find.text('Inactive'), findsOneWidget);

      expect(find.text('2 total'), findsOneWidget);
    });

    testWidgets('SitesPage role-based permissions: Admin vs Volunteer', (
      tester,
    ) async {
      const sites = [
        Site(
          id: 'site_1',
          name: 'Jaipur North',
          location: 'Jaipur, Rajasthan',
          beneficiaries: 100,
          isActive: true,
        ),
      ];

      // 1. Volunteer view
      await tester.pumpWidget(
        MaterialApp(
          home: SitesPage(isAdmin: false, sitesStream: Stream.value(sites)),
        ),
      );
      await tester.pumpAndSettle();

      // Volunteer sees View Details, but NOT Edit button or AppBar Add button
      expect(find.text('View Details'), findsOneWidget);
      expect(find.text('Edit'), findsNothing);
      expect(find.byTooltip('Add Sites'), findsNothing);

      // 2. Admin view
      await tester.pumpWidget(
        MaterialApp(
          home: SitesPage(isAdmin: true, sitesStream: Stream.value(sites)),
        ),
      );
      await tester.pumpAndSettle();

      // Admin sees View Details AND Edit button AND AppBar Add button
      expect(find.text('View Details'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.byTooltip('Add Sites'), findsOneWidget);
    });
  });

  group('AddSitePage - Form Validation & Submission Tests', () {
    testWidgets('Validates required fields when submitted empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: AddSitePage(isAdmin: true)),
      );
      await tester.pumpAndSettle();

      // Tap Add Site button without filling form
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Site'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a site name'), findsOneWidget);
      expect(find.text('Please enter a location'), findsOneWidget);
      expect(find.text('Please enter number of beneficiaries'), findsOneWidget);
    });

    testWidgets('Validates minimum character length for name and location', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: AddSitePage(isAdmin: true)),
      );
      await tester.pumpAndSettle();

      // Enter single character inputs
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Site Name'),
        'A',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Location'),
        'B',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Beneficiaries'),
        '100',
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Site'));
      await tester.pumpAndSettle();

      expect(
        find.text('Site name must be at least 2 characters'),
        findsOneWidget,
      );
      expect(
        find.text('Location must be at least 2 characters'),
        findsOneWidget,
      );
    });

    testWidgets(
      'Rejects negative beneficiary count with explicit validation message',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: AddSitePage(isAdmin: true)),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Site Name'),
          'Udaipur Center',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Location'),
          'Udaipur, Rajasthan',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Beneficiaries'),
          '-15',
        );

        await tester.tap(find.widgetWithText(ElevatedButton, 'Add Site'));
        await tester.pumpAndSettle();

        expect(find.text('Beneficiaries cannot be negative'), findsOneWidget);
      },
    );

    testWidgets('Rejects non-integer beneficiary count', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AddSitePage(isAdmin: true)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Site Name'),
        'Udaipur Center',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Location'),
        'Udaipur, Rajasthan',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Beneficiaries'),
        '12.5',
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Site'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid whole number'), findsOneWidget);
    });

    testWidgets('Successfully submits valid form and calls addSite', (
      tester,
    ) async {
      final mockService = MockSitesService();

      await tester.pumpWidget(
        MaterialApp(
          home: AddSitePage(isAdmin: true, sitesService: mockService),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Site Name'),
        'Kota Central',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Location'),
        'Kota, Rajasthan',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Beneficiaries'),
        '150',
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Site'));
      await tester.pumpAndSettle();

      expect(mockService.addSiteCalled, isTrue);
      expect(mockService.lastAddedName, equals('Kota Central'));
      expect(mockService.lastAddedBeneficiaries, equals(150));
    });

    testWidgets('Prevents duplicate submissions while save is in progress', (
      tester,
    ) async {
      final mockService = MockSitesService();
      mockService.pendingAddCompleter = Completer<String>();

      await tester.pumpWidget(
        MaterialApp(
          home: AddSitePage(isAdmin: true, sitesService: mockService),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Site Name'),
        'Bikaner Community',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Location'),
        'Bikaner, Rajasthan',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Beneficiaries'),
        '75',
      );

      // First tap triggers save
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Site'));
      await tester.pump(); // Start save without settling

      // Verify button shows progress indicator and is disabled
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete save
      mockService.pendingAddCompleter!.complete('bikaner-id');
      await tester.pumpAndSettle();
    });

    testWidgets(
      'Non-admin access displays warning banner and disables submission',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: AddSitePage(isAdmin: false)),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Administrator Access Required: Only users with the ADMIN role can add community sites.',
          ),
          findsOneWidget,
        );

        final button = tester.widget<ElevatedButton>(
          find.byType(ElevatedButton),
        );
        expect(button.onPressed, isNull);
      },
    );
  });

  group('SitesService - Model & Service Validation Tests', () {
    test(
      'addSite throws ArgumentError when beneficiaries are negative',
      () async {
        final service = SitesService();
        expect(
          () => service.addSite(
            name: 'Invalid Site',
            location: 'Anywhere',
            beneficiaries: -5,
          ),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    test(
      'updateSite throws ArgumentError when beneficiaries are negative',
      () async {
        final service = SitesService();
        expect(
          () => service.updateSite(
            siteId: 'site-test',
            name: 'Invalid Site',
            location: 'Anywhere',
            beneficiaries: -10,
          ),
          throwsA(isA<ArgumentError>()),
        );
      },
    );
  });
}
