import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/sites_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/components.dart';

class AddSitePage extends StatefulWidget {
  final bool isAdmin;
  final SitesService? sitesService;

  const AddSitePage({super.key, this.isAdmin = true, this.sitesService});

  @override
  State<AddSitePage> createState() => _AddSitePageState();
}

class _AddSitePageState extends State<AddSitePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _beneficiariesController = TextEditingController();

  SitesService? _sitesService;

  bool _isActive = true;
  bool _isSaving = false;
  String? _errorMessage;

  SitesService get _effectiveSitesService =>
      _sitesService ??= widget.sitesService ?? SitesService();

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _beneficiariesController.dispose();
    super.dispose();
  }

  Future<void> _addSite() async {
    // 1. Prevent duplicate submissions while a save is in progress
    if (_isSaving) return;

    // 2. Role-based check
    if (!widget.isAdmin) {
      setState(() {
        _errorMessage =
            'Permission denied: Administrator role is required to add sites.';
      });
      return;
    }

    // 3. Form validation
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final siteName = _nameController.text.trim();
      final siteLocation = _locationController.text.trim();
      final beneficiariesCount = int.parse(
        _beneficiariesController.text.trim(),
      );

      await _effectiveSitesService.addSite(
        name: siteName,
        location: siteLocation,
        beneficiaries: beneficiariesCount,
        isActive: _isActive,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Site "$siteName" added successfully'),
          backgroundColor: AppColors.primary,
        ),
      );

      Navigator.pop(context);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.code == 'permission-denied'
            ? 'Permission denied: Only administrators are authorized to add new sites.'
            : 'Database error: ${e.message ?? e.code}';
      });
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
                  if (!widget.isAdmin) ...[
                    const NoticeBanner(
                      message: 'Administrator Access Required: Only users with the ADMIN role can add community sites.',
                      isError: true,
                    ),
                    const SizedBox(height: 16),
                  ],
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
                          enabled: !_isSaving && widget.isAdmin,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Site Name',
                            hintText: 'e.g., Jaipur West',
                            prefixIcon: Icon(Icons.business_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a site name';
                            }
                            if (value.trim().length < 2) {
                              return 'Site name must be at least 2 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _locationController,
                          enabled: !_isSaving && widget.isAdmin,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Location',
                            hintText: 'e.g., Jaipur, Rajasthan',
                            prefixIcon: Icon(Icons.place_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a location';
                            }
                            if (value.trim().length < 2) {
                              return 'Location must be at least 2 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _beneficiariesController,
                          enabled: !_isSaving && widget.isAdmin,
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
                            if (count == null) {
                              return 'Please enter a valid whole number';
                            }
                            if (count < 0) {
                              return 'Beneficiaries cannot be negative';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Material(
                          color: Colors.transparent,
                          child: SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Site is active'),
                            subtitle: Text(
                              _isActive
                                  ? 'Available for relief distribution'
                                  : 'Temporarily inactive',
                            ),
                            value: _isActive,
                            onChanged: (!_isSaving && widget.isAdmin)
                                ? (value) {
                                    setState(() => _isActive = value);
                                  }
                                : null,
                          ),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          NoticeBanner(message: _errorMessage!),
                        ],
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: (_isSaving || !widget.isAdmin)
                              ? null
                              : _addSite,
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
