import 'package:flutter/material.dart';
import '../../models/site.dart';
import '../../services/sites_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/components.dart';
import 'edit_site_page.dart';

/// SiteDetailsPage displays comprehensive details for a specific distribution site.
///
/// Note on Inventory and Activity:
/// As per module specifications, Current Stock, Assigned Volunteers,
/// and Recent Activity use mock display data to maintain strict scope
/// boundaries without altering other team members' inventory/distribution logic.
class SiteDetailsPage extends StatelessWidget {
  final Site initialSite;
  final SitesService _sitesService = SitesService();

  SiteDetailsPage({
    super.key,
    required this.initialSite,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Site?>(
      stream: _sitesService.getSiteStream(initialSite.id),
      initialData: initialSite,
      builder: (context, snapshot) {
        final site = snapshot.data ?? initialSite;

        return Scaffold(
          appBar: AppBar(
            title: Text(site.name),
            actions: [
              IconButton(
                tooltip: 'Edit Site',
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditSitePage(site: site),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedContent(
                maxWidth: 720,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Card with Site Overview
                    SoberCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                      style: AppTypography.titleLarge,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.place_outlined,
                                          size: 15,
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
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'BENEFICIARIES',
                                      style: AppTypography.labelSmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${site.beneficiaries}',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Registered individuals',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.edit_outlined, size: 16),
                                label: const Text('Edit Details'),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditSitePage(site: site),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Assigned Volunteers (Mock display data per module requirements)
                    Text(
                      'ASSIGNED VOLUNTEERS',
                      style: AppTypography.labelSmall,
                    ),
                    const SizedBox(height: 10),
                    SoberCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        children: const [
                          _VolunteerTile(
                            name: 'Rahul',
                            role: 'Site Coordinator',
                          ),
                          Divider(height: 1),
                          _VolunteerTile(
                            name: 'Ananya',
                            role: 'Logistics Volunteer',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Current Stock (Mock display data per module requirements)
                    Text(
                      'CURRENT STOCK',
                      style: AppTypography.labelSmall,
                    ),
                    const SizedBox(height: 10),
                    const Row(
                      children: [
                        Expanded(
                          child: StatMetricTile(
                            label: 'Rice',
                            value: '120 kg',
                            caption: 'Ready for distribution',
                            icon: Icons.grain_outlined,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: StatMetricTile(
                            label: 'Dal',
                            value: '50 kg',
                            caption: 'Ready for distribution',
                            icon: Icons.eco_outlined,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Recent Activity (Mock display data per module requirements)
                    Text(
                      'RECENT ACTIVITY',
                      style: AppTypography.labelSmall,
                    ),
                    const SizedBox(height: 10),
                    SoberCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: const [
                          _ActivityItemTile(
                            title: 'Rice distributed',
                            quantity: '20 kg',
                            time: 'Today',
                            icon: Icons.check_circle_outline,
                          ),
                          Divider(height: 1),
                          _ActivityItemTile(
                            title: 'Dal distributed',
                            quantity: '10 kg',
                            time: 'Yesterday',
                            icon: Icons.check_circle_outline,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _VolunteerTile extends StatelessWidget {
  final String name;
  final String role;

  const _VolunteerTile({
    required this.name,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              name.isNotEmpty ? name[0] : 'V',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  role,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SoberBadge(
            label: 'On Duty',
            backgroundColor: AppColors.secondaryContainer,
            textColor: AppColors.secondary,
          ),
        ],
      ),
    );
  }
}

class _ActivityItemTile extends StatelessWidget {
  final String title;
  final String quantity;
  final String time;
  final IconData icon;

  const _ActivityItemTile({
    required this.title,
    required this.quantity,
    required this.time,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$title — $quantity',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
