import 'package:flutter/material.dart';

import '../../models/site.dart';
import '../../services/sites_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/components.dart';
import 'site_details_page.dart';
import 'edit_site_page.dart';
import 'add_site_page.dart';

/// SitesPage displays the directory of all community and distribution sites.
///
/// Flow:
/// SitesPage -> View Details -> SiteDetailsPage
/// SitesPage -> Edit -> EditSitePage -> Save Changes -> Updated SitesPage
class SitesPage extends StatefulWidget {
  final bool isAdmin;
  final Stream<List<Site>>? sitesStream;
  final SitesService? sitesService;

  const SitesPage({
    super.key,
    this.isAdmin = false,
    this.sitesStream,
    this.sitesService,
  });

  @override
  State<SitesPage> createState() => _SitesPageState();
}

class _SitesPageState extends State<SitesPage> {
  SitesService? _sitesService;
  int _retryKey = 0;

  SitesService get _effectiveSitesService =>
      _sitesService ??= widget.sitesService ?? SitesService();

  Stream<List<Site>> get _stream =>
      widget.sitesStream ?? _effectiveSitesService.getSitesStream();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sites & Communities'),
        actions: [
          if (widget.isAdmin)
            IconButton(
              tooltip: 'Add Sites',
              icon: const Icon(Icons.add_location_alt_outlined, size: 20),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddSitePage(
                      isAdmin: widget.isAdmin,
                      sitesService: _sitesService,
                    ),
                  ),
                );
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<Site>>(
          key: ValueKey(_retryKey),
          stream: _stream,
          builder: (context, snapshot) {
            // 1. Loading state
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              );
            }

            // 2. Error state
            if (snapshot.hasError) {
              return Center(
                child: ConstrainedContent(
                  maxWidth: 520,
                  padding: const EdgeInsets.all(24),
                  child: SoberCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 28,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.error,
                            size: 26,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Unable to Load Distribution Sites',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Retry'),
                          onPressed: () {
                            setState(() {
                              _retryKey++;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final sites = snapshot.data ?? <Site>[];

            // 3. Empty state
            if (sites.isEmpty) {
              return Center(
                child: ConstrainedContent(
                  maxWidth: 440,
                  padding: const EdgeInsets.all(24),
                  child: SoberCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 36,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.secondaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.location_off_outlined,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Distribution Sites Found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.isAdmin
                              ? 'No community distribution sites have been registered yet. Tap "Add Site" to register a new location.'
                              : 'There are currently no community distribution sites registered in the network.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        if (widget.isAdmin) ...[
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            icon: const Icon(
                              Icons.add_location_alt_outlined,
                              size: 16,
                            ),
                            label: const Text('Add Site'),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddSitePage(
                                    isAdmin: widget.isAdmin,
                                    sitesService: _sitesService,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }

            // 4. Populated site list
            return SingleChildScrollView(
              child: ConstrainedContent(
                maxWidth: 760,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (SitesService.isUsingFallback) ...[
                      const NoticeBanner(
                        message: 'Demo / Fallback Mode: Cloud Firestore rules for "Sites" are pending in Firebase Console. Showing test sites (Jaipur North, Jaipur South, Ajmer Central). You can view details, edit, and save changes normally.',
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
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final site = sites[index];
                        return SiteItemCard(
                          site: site,
                          isAdmin: widget.isAdmin,
                          onViewDetails: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SiteDetailsPage(
                                  initialSite: site,
                                  isAdmin: widget.isAdmin,
                                ),
                              ),
                            );
                          },
                          onEdit: widget.isAdmin
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          EditSitePage(site: site),
                                    ),
                                  );
                                }
                              : null,
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
/// - [ View Details ] and optionally [ Edit ] button for Admins
class SiteItemCard extends StatelessWidget {
  final Site site;
  final bool isAdmin;
  final VoidCallback onViewDetails;
  final VoidCallback? onEdit;

  const SiteItemCard({
    super.key,
    required this.site,
    this.isAdmin = false,
    required this.onViewDetails,
    this.onEdit,
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

          // Buttons: [ View Details ] and conditionally [ Edit ]
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onViewDetails,
                  child: const Text('View Details'),
                ),
              ),
              if (isAdmin && onEdit != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onEdit,
                    child: const Text('Edit'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
