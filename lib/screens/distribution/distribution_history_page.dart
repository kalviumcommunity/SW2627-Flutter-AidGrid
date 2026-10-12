import 'package:flutter/material.dart';

import '../../models/distribution_record.dart';
import '../../services/distribution_history_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/components.dart';

/// DistributionHistoryPage displays a real-time, chronological log of food
/// and ration distributions across community sites.
class DistributionHistoryPage extends StatefulWidget {
  final bool isAdmin;
  final String? volunteerId;

  const DistributionHistoryPage({
    super.key,
    this.isAdmin = true,
    this.volunteerId,
  });

  @override
  State<DistributionHistoryPage> createState() =>
      _DistributionHistoryPageState();
}

class _DistributionHistoryPageState extends State<DistributionHistoryPage> {
  final DistributionHistoryService _historyService =
      DistributionHistoryService();

  int _retryKey = 0;
  String _searchQuery = '';

  static String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return (month >= 1 && month <= 12) ? months[month - 1] : '';
  }

  static String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  static String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return mins <= 1 ? 'Just now' : '$mins mins ago';
    } else if (difference.inHours < 24 && now.day == dt.day) {
      return 'Today at ${_formatTime(dt)}';
    } else if (difference.inHours < 48 &&
        now.subtract(const Duration(days: 1)).day == dt.day) {
      return 'Yesterday at ${_formatTime(dt)}';
    }

    return '${dt.day} ${_monthName(dt.month)} ${dt.year} · ${_formatTime(dt)}';
  }

  Stream<List<DistributionRecord>> get _stream {
    if (!widget.isAdmin &&
        widget.volunteerId != null &&
        widget.volunteerId!.isNotEmpty) {
      return _historyService.getVolunteerDistributionHistoryStream(
        widget.volunteerId!,
      );
    }
    return _historyService.getDistributionHistoryStream();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isAdmin ? 'Distribution History' : 'My Distribution History',
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<DistributionRecord>>(
          key: ValueKey(_retryKey),
          stream: _stream,
          builder: (context, snapshot) {
            // 1. Loading state
            if (snapshot.connectionState == ConnectionState.waiting) {
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

            // 2. Error state with retry option (when no data available)
            if (snapshot.hasError &&
                (snapshot.data == null || snapshot.data!.isEmpty)) {
              return Center(
                child: ConstrainedContent(
                  maxWidth: 520,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      NoticeBanner(
                        message:
                            'Unable to load distribution history: ${snapshot.error}',
                      ),
                      const SizedBox(height: 16),
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
              );
            }

            final allRecords = snapshot.data ?? [];

            // 3. Global Empty State (no distributions recorded yet)
            if (allRecords.isEmpty) {
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
                            Icons.history_toggle_off_rounded,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Distributions Recorded Yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'When food and supply dispatches are recorded, they will appear chronologically in this audit log.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            // Filter by search query if provided
            final filteredRecords = _searchQuery.trim().isEmpty
                ? allRecords
                : allRecords.where((r) {
                    final q = _searchQuery.toLowerCase();
                    return r.itemName.toLowerCase().contains(q) ||
                        r.siteName.toLowerCase().contains(q) ||
                        r.volunteerName.toLowerCase().contains(q);
                  }).toList();

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
                    // Demo / Fallback notice banner if Firestore rules pending
                    if (DistributionHistoryService.isUsingFallback ||
                        snapshot.hasError) ...[
                      NoticeBanner(
                        message:
                            'Notice: Cloud Firestore rules for "Distributions" are pending in Firebase Console (${DistributionHistoryService.lastFirestoreError ?? snapshot.error ?? "permission-denied"}). Showing sample distribution history records.',
                        isError: false,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Header with count badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'DISTRIBUTION RECORDS',
                          style: AppTypography.labelSmall,
                        ),
                        SoberBadge(
                          label:
                              '${filteredRecords.length} of ${allRecords.length} dispatches',
                          backgroundColor: AppColors.secondaryContainer,
                          textColor: AppColors.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Search input
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search by food item, community site, or volunteer...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Filtered empty state
                    if (filteredRecords.isEmpty) ...[
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.search_off_rounded,
                                size: 36,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No records matching "$_searchQuery"',
                                style: AppTypography.bodyMedium,
                              ),
                              const SizedBox(height: 10),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                                child: const Text('Clear search'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      // Distribution Records List
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredRecords.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final record = filteredRecords[index];
                          return _DistributionRecordCard(
                            record: record,
                            formattedDate: _formatDate(record.distributedAt),
                          );
                        },
                      ),
                    ],
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

class _DistributionRecordCard extends StatelessWidget {
  final DistributionRecord record;
  final String formattedDate;

  const _DistributionRecordCard({
    required this.record,
    required this.formattedDate,
  });

  @override
  Widget build(BuildContext context) {
    return SoberCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Item name + Quantity Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.local_shipping_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.itemName, style: AppTypography.titleMedium),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            record.siteName,
                            style: AppTypography.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Quantity pill badge
              SoberBadge(
                label: '${record.quantity} ${record.unit}',
                backgroundColor: AppColors.successContainer,
                textColor: AppColors.success,
                icon: Icons.check_circle_outline,
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Footer: Volunteer Name and Timestamp
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Volunteer name
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    record.volunteerName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),

              // Date / Time
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
