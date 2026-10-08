import 'package:flutter/material.dart';
import '../../models/site.dart';
import '../../services/sites_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/components.dart';

/// EditSitePage allows editing a distribution site's:
/// - Site Name
/// - Location
/// - Beneficiaries
/// - Active/Inactive status
class EditSitePage extends StatefulWidget {
  final Site site;

  const EditSitePage({
    super.key,
    required this.site,
  });

  @override
  State<EditSitePage> createState() => _EditSitePageState();
}

class _EditSitePageState extends State<EditSitePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _beneficiariesController;
  late bool _isActive;

  final SitesService _sitesService = SitesService();
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.site.name);
    _locationController = TextEditingController(text: widget.site.location);
    _beneficiariesController =
        TextEditingController(text: widget.site.beneficiaries.toString());
    _isActive = widget.site.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _beneficiariesController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final beneficiaries = int.parse(_beneficiariesController.text.trim());

      await _sitesService.updateSite(
        siteId: widget.site.id,
        name: _nameController.text.trim(),
        location: _locationController.text.trim(),
        beneficiaries: beneficiaries,
        isActive: _isActive,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Site updated successfully'),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to save changes. Please try again.';
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
      appBar: AppBar(
        title: const Text('Edit Site'),
      ),
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
                    title: 'Edit Community Site',
                    subtitle: 'Update site details and beneficiary counts',
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

                        // Site Name Field
                        TextFormField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Site Name',
                            hintText: 'e.g., Jaipur North',
                            prefixIcon: Icon(Icons.business_outlined, size: 20),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a site name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Location Field
                        TextFormField(
                          controller: _locationController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Location',
                            hintText: 'e.g., Jaipur, Rajasthan',
                            prefixIcon: Icon(Icons.place_outlined, size: 20),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a location';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Beneficiaries Field
                        TextFormField(
                          controller: _beneficiariesController,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            labelText: 'Beneficiaries',
                            hintText: 'e.g., 120',
                            prefixIcon: Icon(Icons.people_outline, size: 20),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter number of beneficiaries';
                            }
                            final parsed = int.tryParse(value.trim());
                            if (parsed == null || parsed < 0) {
                              return 'Please enter a valid positive number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Active / Inactive Switch
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.canvas,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Operational Status',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    _isActive ? 'Site is active for relief' : 'Site is temporarily inactive',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              Switch.adaptive(
                                value: _isActive,
                                activeTrackColor: AppColors.primary,
                                onChanged: (val) {
                                  setState(() {
                                    _isActive = val;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),

                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          NoticeBanner(message: _errorMessage!),
                        ],

                        const SizedBox(height: 24),

                        // Save Button
                        ElevatedButton(
                          onPressed: _isSaving ? null : _saveChanges,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Save Changes'),
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
