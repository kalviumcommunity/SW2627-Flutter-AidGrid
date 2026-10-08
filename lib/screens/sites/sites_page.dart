import 'package:flutter/material.dart';
import '../../models/site.dart';
import '../../services/sites_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/components.dart';
import 'site_details_page.dart';
import 'edit_site_page.dart';

/// SitesPage displays the directory of all community and distribution sites.
///
/// Flow:
/// SitesPage -> View Details -> SiteDetailsPage
/// SitesPage -> Edit -> EditSitePage -> Save Changes -> Updated SitesPage
class SitesPage extends StatefulWidget {
  const SitesPage({super.key});

  @override
  State<SitesPage> createState() => _SitesPageState();
}

class _SitesPageState extends State<SitesPage> {
  final SitesService _sitesService = SitesService();
  bool _isSeeding = false;

  Future<void> _seedSampleSites() async {
    setState(() {
      _isSeeding = true;
    });

    try {
      await _sitesService.seedInitialSites();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Added sample sites (Jaipur North, Jaipur South, Ajmer Central)'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to seed sites: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSeeding = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sites & Communities'),
        actions: [
          IconButton(
            tooltip: 'Add Sample Sites',
            icon: _isSeeding
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(Icons.add_location_alt_outlined, size: 20),
            onPressed: _isSeeding ? null : _seedSampleSites,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<Site>>(
          stream: _sitesService.getSitesStream(),
          initialData: SitesService.defaultSampleSites,
          builder: (context, snapshot) {
            final sites = (snapshot.hasData && snapshot.data!.isNotEmpty)
                ? snapshot.data!
                : SitesService.defaultSampleSites;

            return SingleChildScrollView(
              child: ConstrainedContent(
                maxWidth: 760,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (SitesService.isUsingFallback || snapshot.hasError) ...[
                      const NoticeBanner(
                        message:
                            'Demo / Fallback Mode: Cloud Firestore rules for "Sites" are pending in Firebase Console. Showing test sites (Jaipur North, Jaipur South, Ajmer Central). You can view details, edit, and save changes normally.',
                        isError: false,
                      ),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'COMMUNITY DISTRIBUTION SITES',
                          style: AppTypography.labelSmall,
                        ),
                        SoberBadge(
                          label: '${sites.length} total',
                          backgroundColor: AppColors.secondaryContainer,
                          textColor: AppColors.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sites.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final site = sites[index];
                        return _SiteItemCard(
                          site: site,
                          onViewDetails: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SiteDetailsPage(initialSite: site),
                              ),
                            );
                          },
                          onEdit: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditSitePage(site: site),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Site Card displaying:
/// - Site name
/// - Location
/// - Number of beneficiaries
/// - Active/inactive status
/// - [ View Details ] and [ Edit ] buttons
class _SiteItemCard extends StatelessWidget {
  final Site site;
  final VoidCallback onViewDetails;
  final VoidCallback onEdit;

  const _SiteItemCard({
    required this.site,
    required this.onViewDetails,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return SoberCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Site Name & Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      site.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            site.location,
                            style: AppTypography.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SoberBadge(
                label: site.isActive ? 'Active' : 'Inactive',
                icon: Icons.fiber_manual_record,
                backgroundColor: site.isActive
                    ? AppColors.successContainer
                    : AppColors.surfaceMuted,
                textColor: site.isActive
                    ? AppColors.success
                    : AppColors.textMuted,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Beneficiaries row
          Row(
            children: [
              const Icon(
                Icons.people_outline,
                size: 15,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                '${site.beneficiaries} beneficiaries',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Buttons: [ View Details ] [ Edit ]
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onViewDetails,
                  child: const Text('View Details'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onEdit,
                  child: const Text('Edit'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
