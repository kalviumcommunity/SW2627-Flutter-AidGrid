import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_distribution_app/main.dart';

void main() {
  group('InventoryPage Role-Based UI Tests', () {
    testWidgets('Admin view shows Add Inventory button and empty state', (
      WidgetTester tester,
    ) async {
      final stream = Stream<QuerySnapshot<Map<String, dynamic>>>.empty();

      await tester.pumpWidget(
        MaterialApp(
          home: InventoryPage(isAdmin: true, inventoryStream: stream),
        ),
      );

      // Verify AppBar Add button is present for Admin
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byTooltip('Add Inventory'), findsOneWidget);
    });

    testWidgets('Volunteer view hides Add Inventory button', (
      WidgetTester tester,
    ) async {
      final stream = Stream<QuerySnapshot<Map<String, dynamic>>>.empty();

      await tester.pumpWidget(
        MaterialApp(
          home: InventoryPage(isAdmin: false, inventoryStream: stream),
        ),
      );

      // Verify AppBar Add button is NOT present for Volunteer
      expect(find.byIcon(Icons.add), findsNothing);
      expect(find.byTooltip('Add Inventory'), findsNothing);
    });
  });
}
