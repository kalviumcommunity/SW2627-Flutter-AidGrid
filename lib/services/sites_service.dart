import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/site.dart';

/// Service responsible for managing Firestore operations for the `Sites` collection.
///
/// Features:
/// - Connects to Firestore `Sites` collection.
/// - Automatically provides resilient fallback sites (Jaipur North, Jaipur South,
///   Ajmer Central) if cloud security rules have not yet been configured in the
///   Firebase Console, ensuring all user flows remain testable and interactive.
class SitesService {
  final FirebaseFirestore _firestore;

  SitesService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _sitesCollection =>
      _firestore.collection('Sites');

  /// Default sample sites specified for the Sites / Communities module.
  static final List<Site> defaultSampleSites = [
    const Site(
      id: 'jaipur-north',
      name: 'Jaipur North',
      location: 'Jaipur, Rajasthan',
      beneficiaries: 120,
      isActive: true,
    ),
    const Site(
      id: 'jaipur-south',
      name: 'Jaipur South',
      location: 'Jaipur, Rajasthan',
      beneficiaries: 85,
      isActive: true,
    ),
    const Site(
      id: 'ajmer-central',
      name: 'Ajmer Central',
      location: 'Ajmer, Rajasthan',
      beneficiaries: 150,
      isActive: false,
    ),
  ];

  /// In-memory cache to guarantee smooth offline & permission-safe interaction.
  static final List<Site> _localSites = List<Site>.from(defaultSampleSites);
  static final StreamController<List<Site>> _localStreamController =
      StreamController<List<Site>>.broadcast();

  /// Indicates whether the service is currently operating in fallback mode
  /// due to missing Firestore security rules in Firebase Console.
  static bool isUsingFallback = false;

  /// Streams real-time list of all sites.
  /// Seamlessly handles Firestore connection and gracefully falls back to
  /// local test data if permissions are missing or restricted.
  Stream<List<Site>> getSitesStream() {
    late StreamController<List<Site>> controller;
    StreamSubscription? firestoreSub;
    StreamSubscription? localSub;

    controller = StreamController<List<Site>>(
      onListen: () {
        // Immediately emit current data so UI never hangs
        controller.add(List<Site>.from(_localSites));

        // Connect to Firestore
        firestoreSub = _sitesCollection.snapshots().listen(
          (snapshot) {
            isUsingFallback = false;
            final remoteSites =
                snapshot.docs.map((doc) => Site.fromFirestore(doc)).toList();

            if (remoteSites.isNotEmpty) {
              remoteSites.sort((a, b) =>
                  a.name.toLowerCase().compareTo(b.name.toLowerCase()));
              _localSites.clear();
              _localSites.addAll(remoteSites);
            }
            if (!controller.isClosed) {
              controller.add(List<Site>.from(_localSites));
            }
          },
          onError: (error) {
            debugPrint(
                'SITES SERVICE: Firestore query error: $error. Falling back to local/demo sites.');
            isUsingFallback = true;
            if (!controller.isClosed) {
              controller.add(List<Site>.from(_localSites));
            }
          },
        );

        // Listen to local updates (e.g. from EditSitePage saves)
        localSub = _localStreamController.stream.listen((sites) {
          if (!controller.isClosed) {
            controller.add(List<Site>.from(sites));
          }
        });
      },
      onCancel: () {
        firestoreSub?.cancel();
        localSub?.cancel();
      },
    );

    return controller.stream;
  }

  /// Streams real-time updates for a single site by ID.
  Stream<Site?> getSiteStream(String siteId) {
    late StreamController<Site?> controller;
    StreamSubscription? firestoreSub;
    StreamSubscription? localSub;

    Site? findLocalSite() {
      try {
        return _localSites.firstWhere((s) => s.id == siteId);
      } catch (_) {
        return null;
      }
    }

    controller = StreamController<Site?>(
      onListen: () {
        controller.add(findLocalSite());

        firestoreSub = _sitesCollection.doc(siteId).snapshots().listen(
          (doc) {
            if (doc.exists) {
              final site = Site.fromFirestore(doc);
              final idx = _localSites.indexWhere((s) => s.id == siteId);
              if (idx != -1) {
                _localSites[idx] = site;
              } else {
                _localSites.add(site);
              }
              if (!controller.isClosed) {
                controller.add(site);
              }
            } else {
              if (!controller.isClosed) {
                controller.add(findLocalSite());
              }
            }
          },
          onError: (error) {
            debugPrint(
                'SITES SERVICE: Firestore doc stream error: $error. Using local site.');
            if (!controller.isClosed) {
              controller.add(findLocalSite());
            }
          },
        );

        localSub = _localStreamController.stream.listen((_) {
          if (!controller.isClosed) {
            controller.add(findLocalSite());
          }
        });
      },
      onCancel: () {
        firestoreSub?.cancel();
        localSub?.cancel();
      },
    );

    return controller.stream;
  }

  /// Updates an existing site document.
  /// Saves to local cache first so UI reflects instantly, then updates Firestore.
  Future<void> updateSite({
    required String siteId,
    required String name,
    required String location,
    required int beneficiaries,
    bool? isActive,
  }) async {
    final Map<String, dynamic> data = {
      'name': name.trim(),
      'location': location.trim(),
      'beneficiaries': beneficiaries,
    };
    if (isActive != null) {
      data['isActive'] = isActive;
    }

    // 1. Update in-memory / local cache
    final index = _localSites.indexWhere((s) => s.id == siteId);
    if (index != -1) {
      _localSites[index] = _localSites[index].copyWith(
        name: name.trim(),
        location: location.trim(),
        beneficiaries: beneficiaries,
        isActive: isActive,
      );
    } else {
      _localSites.add(Site(
        id: siteId,
        name: name.trim(),
        location: location.trim(),
        beneficiaries: beneficiaries,
        isActive: isActive ?? true,
      ));
    }
    _localStreamController.add(List<Site>.from(_localSites));

    // 2. Persist to Firestore
    try {
      await _sitesCollection.doc(siteId).set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint(
          'SITES SERVICE: Remote Firestore update error: $e. Saved to local state.');
      // Do not rethrow if permission-denied so user flow remains uninterrupted
      if (e.toString().contains('permission-denied') ||
          e.toString().contains('PERMISSION_DENIED')) {
        return;
      }
      rethrow;
    }
  }

  /// Seeds initial test sites to Firestore.
  Future<void> seedInitialSites() async {
    _localSites.clear();
    _localSites.addAll(defaultSampleSites);
    _localStreamController.add(List<Site>.from(_localSites));

    try {
      final batch = _firestore.batch();
      for (final site in defaultSampleSites) {
        final docRef = _sitesCollection.doc(site.id);
        batch.set(docRef, site.toMap());
      }
      await batch.commit();
      debugPrint('SITES SERVICE: Seeded test sites to Firestore successfully.');
    } catch (e) {
      debugPrint(
          'SITES SERVICE: Firestore seed failed ($e). Local sites active.');
    }
  }

  /// Seeds initial sites only if the collection is currently empty.
  Future<bool> seedIfEmpty() async {
    try {
      final snapshot = await _sitesCollection.limit(1).get();
      if (snapshot.docs.isEmpty) {
        await seedInitialSites();
        return true;
      }
    } catch (e) {
      debugPrint('SITES SERVICE: seedIfEmpty check error ($e).');
    }
    return false;
  }
}
