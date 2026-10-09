import 'package:flutter/material.dart';

import '../../models/site.dart';
import '../../services/sites_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/components.dart';

class AddSitePage extends StatefulWidget {
  const AddSitePage({super.key});

  @override
  State<AddSitePage> createState() => _AddSitePageState();
}

class _AddSitePageState extends State<AddSitePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _beneficiariesController = TextEditingController();

  final SitesService _sitesService = SitesService();

  bool _isActive = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _beneficiariesController.dispose();
    super.dispose();
  }

  Future<void> _addSite() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final siteId = DateTime.now().microsecondsSinceEpoch.toString();

      await _sitesService.updateSite(
        siteId: siteId,
        name: _nameController.text.trim(),
        location: _locationController.text.trim(),
        beneficiaries: int.parse(_beneficiariesController.text.trim()),
        isActive: _isActive,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Site added successfully'),
          backgroundColor: AppColors.primary,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Failed to add site. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Site')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedContent(
            maxWidth: 520,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const BrandHeader(
                    title: 'Add Community Site',
                    subtitle: 'Register a new food distribution location',
                  ),
                  const SizedBox(height: 24),
                  SoberCard(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'SITE INFORMATION',
                          style: AppTypography.labelSmall,
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Site Name',
                            hintText: 'e.g., Jaipur West',
                            prefixIcon: Icon(Icons.business_outlined),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Please enter a site name'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _locationController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Location',
                            hintText: 'e.g., Jaipur, Rajasthan',
                            prefixIcon: Icon(Icons.place_outlined),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Please enter a location'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _beneficiariesController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Beneficiaries',
                            hintText: 'e.g., 100',
                            prefixIcon: Icon(Icons.people_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter number of beneficiaries';
                            }

                            final count = int.tryParse(value.trim());
                            if (count == null || count < 0) {
                              return 'Enter a valid non-negative whole number';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Site is active'),
                          subtitle: Text(
                            _isActive
                                ? 'Available for relief distribution'
                                : 'Temporarily inactive',
                          ),
                          value: _isActive,
                          onChanged: (value) {
                            setState(() => _isActive = value);
                          },
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          NoticeBanner(message: _errorMessage!),
                        ],
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isSaving ? null : _addSite,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Add Site'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
