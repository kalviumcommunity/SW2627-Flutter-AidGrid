import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/distribution_services.dart';

class RecordDistributionPage extends StatefulWidget {
  const RecordDistributionPage({super.key});

  @override
  State<RecordDistributionPage> createState() => _RecordDistributionPageState();
}

class _RecordDistributionPageState extends State<RecordDistributionPage> {
  String? _selectedSiteId;
  String? _selectedItemId;
  String? _selectedVolunteerId;
  final TextEditingController _quantityController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitDistribution() async {
    if (_selectedSiteId == null ||
        _selectedItemId == null ||
        _selectedVolunteerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a site, an inventory item, and a volunteer.',
          ),
        ),
      );
      return;
    }

    final quantity = int.tryParse(_quantityController.text.trim());

    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid quantity greater than zero.'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await DistributionService().recordDistribution(
        itemId: _selectedItemId!,
        siteId: _selectedSiteId!,
        quantity: quantity,
        volunteerId: _selectedVolunteerId!,
      );

      if (!mounted) return;

      _quantityController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Distribution recorded successfully.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not record distribution: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record Distribution')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('Sites')
            .where('isActive', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Could not load sites. Check your connection.'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final sites = snapshot.data!.docs;

          if (sites.isEmpty) {
            return const Center(child: Text('No active sites available.'));
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedSiteId,
                  decoration: const InputDecoration(
                    labelText: 'Select a site',
                    border: OutlineInputBorder(),
                  ),
                  items: sites.map((doc) {
                    final data = doc.data();

                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text(data['name'] ?? 'Unnamed Site'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSiteId = value;
                    });
                  },
                ),

                const SizedBox(height: 16),

                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('role', isEqualTo: 'VOLUNTEER')
                      .snapshots(),
                  builder: (context, volunteerSnapshot) {
                    if (volunteerSnapshot.hasError) {
                      debugPrint(
                        'VOLUNTEER LOAD ERROR: ${volunteerSnapshot.error}',
                      );

                      return Text(
                        'Could not load volunteers: ${volunteerSnapshot.error}',
                      );
                    }

                    if (volunteerSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final volunteers = volunteerSnapshot.data!.docs;

                    if (volunteers.isEmpty) {
                      return const Text('No registered volunteers found.');
                    }

                    return DropdownButtonFormField<String>(
                      initialValue: _selectedVolunteerId,
                      decoration: const InputDecoration(
                        labelText: 'Select a volunteer',
                        border: OutlineInputBorder(),
                      ),
                      items: volunteers.map((doc) {
                        final data = doc.data();
                        final name =
                            data['name'] as String? ??
                            data['email'] as String? ??
                            'Unnamed volunteer';

                        return DropdownMenuItem<String>(
                          value: doc.id,
                          child: Text(name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedVolunteerId = value;
                        });
                      },
                    );
                  },
                ),

                const SizedBox(height: 16),

                const SizedBox(height: 16),

                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('Inventory')
                      .snapshots(),
                  builder: (context, inventorySnapshot) {
                    if (inventorySnapshot.hasError) {
                      return const Text(
                        'Could not load inventory. Check your connection.',
                      );
                    }

                    if (inventorySnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final items = inventorySnapshot.data!.docs;

                    if (items.isEmpty) {
                      return const Text('No inventory items available.');
                    }

                    return DropdownButtonFormField<String>(
                      initialValue: _selectedItemId,
                      decoration: const InputDecoration(
                        labelText: 'Select an inventory item',
                        border: OutlineInputBorder(),
                      ),
                      items: items.map((doc) {
                        final data = doc.data();
                        final name = data['name'] ?? 'Unnamed item';
                        final quantity = data['quantity'] ?? 0;
                        final unit = data['unit'] ?? '';

                        return DropdownMenuItem<String>(
                          value: doc.id,
                          child: Text('$name — $quantity $unit'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedItemId = value;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantity to distribute',
                    hintText: 'Enter quantity',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitDistribution,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Record Distribution'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
