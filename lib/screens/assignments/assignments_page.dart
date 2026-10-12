import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/assignment.dart';
import '../../models/site.dart';
import '../../services/assignments_service.dart';
import '../../services/sites_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/components.dart';

/// AssignmentsPage displays volunteer assignments with real-time Firestore sync,
/// status filtering, and workflow transitions (Pending -> In Progress -> Completed).
class AssignmentsPage extends StatefulWidget {
  final bool isAdmin;
  final String? volunteerId;

  const AssignmentsPage({super.key, this.isAdmin = false, this.volunteerId});

  @override
  State<AssignmentsPage> createState() => _AssignmentsPageState();
}

class _AssignmentsPageState extends State<AssignmentsPage> {
  final AssignmentsService _assignmentsService = AssignmentsService();
  final SitesService _sitesService = SitesService();

  // Filter state: null represents 'All'
  AssignmentStatus? _selectedStatusFilter;
  int _retryKey = 0;

  // Track in-flight status updates per assignment ID
  final Set<String> _updatingAssignmentIds = {};

  String get _currentUserId =>
      widget.volunteerId ?? FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _handleStatusUpdate(
    Assignment assignment,
    AssignmentStatus newStatus,
  ) async {
    setState(() {
      _updatingAssignmentIds.add(assignment.id);
    });

    try {
      final persisted = await _assignmentsService.updateAssignmentStatus(
        assignmentId: assignment.id,
        newStatus: newStatus,
        currentUserId: _currentUserId,
        isAdmin: widget.isAdmin,
        assignedVolunteerId: assignment.volunteerId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            persisted
                ? 'Assignment updated to ${newStatus.label}'
                : 'Assignment updated to ${newStatus.label} (saved locally)',
          ),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingAssignmentIds.remove(assignment.id);
        });
      }
    }
  }

  void _showCreateAssignmentDialog(List<Site> availableSites) {
    final formKey = GlobalKey<FormState>();
    final taskController = TextEditingController();
    final volunteerIdController = TextEditingController();
    Site? selectedSite = availableSites.isNotEmpty
        ? availableSites.first
        : null;
    DateTime selectedDate = DateTime.now();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Create Assignment'),
              content: SizedBox(
                width: 440,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Site selector
                        DropdownButtonFormField<Site>(
                          initialValue: selectedSite,
                          decoration: const InputDecoration(
                            labelText: 'Community Site',
                            prefixIcon: Icon(
                              Icons.location_on_outlined,
                              size: 20,
                            ),
                          ),
                          items: availableSites.map((site) {
                            return DropdownMenuItem<Site>(
                              value: site,
                              child: Text(
                                site.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setDialogState(() {
                              selectedSite = val;
                            });
                          },
                          validator: (val) => val == null
                              ? 'Please select a community site'
                              : null,
                        ),
                        const SizedBox(height: 14),

                        // Volunteer ID field
                        TextFormField(
                          controller: volunteerIdController,
                          decoration: const InputDecoration(
                            labelText: 'Volunteer UID',
                            hintText: 'Enter volunteer user ID',
                            prefixIcon: Icon(Icons.person_outline, size: 20),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter a volunteer UID';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Task Description
                        TextFormField(
                          controller: taskController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Task Description',
                            hintText: 'e.g. Distribute 50 kg grain kits at shelter #2',
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter task description';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Date display
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Date: ${_formatDate(selectedDate)}',
                              style: AppTypography.bodyMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() {
                            isSubmitting = true;
                          });

                          try {
                            await _assignmentsService.createAssignment(
                              siteId: selectedSite?.id ?? '',
                              siteName: selectedSite?.name,
                              volunteerId: volunteerIdController.text.trim(),
                              taskDescription: taskController.text.trim(),
                              assignedAt: selectedDate,
                            );

                            if (!dialogContext.mounted) return;
                            Navigator.pop(dialogContext);

                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Assignment created successfully',
                                ),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          } catch (e) {
                            setDialogState(() {
                              isSubmitting = false;
                            });
                            if (!dialogContext.mounted) return;
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text('Error creating assignment: $e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAdmin ? 'All Assignments' : 'My Assignments'),
        actions: [
          if (widget.isAdmin)
            StreamBuilder<List<Site>>(
              stream: _sitesService.getSitesStream(),
              builder: (context, siteSnapshot) {
                final sites = siteSnapshot.data ?? [];
                return IconButton(
                  tooltip: 'Create Assignment',
                  icon: const Icon(Icons.add_task_rounded),
                  onPressed: () => _showCreateAssignmentDialog(sites),
                );
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<Site>>(
          stream: _sitesService.getSitesStream(),
          builder: (context, siteSnapshot) {
            // Build a lookup map of siteId -> Site
            final siteMap = <String, Site>{};
            if (siteSnapshot.hasData) {
              for (final site in siteSnapshot.data!) {
                siteMap[site.id] = site;
              }
            }

            return StreamBuilder<List<Assignment>>(
              key: ValueKey(_retryKey),
              stream: widget.isAdmin
                  ? _assignmentsService.getAllAssignmentsStream()
                  : _assignmentsService.getVolunteerAssignmentsStream(
                      _currentUserId,
                    ),
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

                // 2. Error state with clear message and retry option (when no data available)
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
                                'Unable to load assignments: ${snapshot.error}',
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

                final allAssignments = snapshot.data ?? [];

                // 3. Global Empty State (no assignments created yet)
                if (allAssignments.isEmpty) {
                  return Center(
                    child: ConstrainedContent(
                      maxWidth: 440,
                      padding: const EdgeInsets.all(24),
                      child: SoberCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 32,
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
                                Icons.assignment_outlined,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.isAdmin
                                  ? 'No Assignments Yet'
                                  : 'No Tasks Assigned',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.isAdmin
                                  ? 'No volunteer assignments have been created in the organization yet.'
                                  : 'You currently have no active or pending tasks assigned to your account.',
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
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Create First Assignment'),
                                onPressed: () {
                                  final sites = siteSnapshot.data ?? [];
                                  _showCreateAssignmentDialog(sites);
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }

                // Apply local status filtering
                final filteredAssignments = _selectedStatusFilter == null
                    ? allAssignments
                    : allAssignments
                          .where((a) => a.status == _selectedStatusFilter)
                          .toList();

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
                        if (AssignmentsService.isUsingFallback ||
                            snapshot.hasError) ...[
                          NoticeBanner(
                            message:
                                'Demo / Fallback Mode: Cloud Firestore rules for "Assignments" are restricted or pending in Firebase Console (${AssignmentsService.lastFirestoreError ?? snapshot.error ?? "permission-denied"}). Showing sample assignments for interactive testing.',
                            isError: false,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Filter Bar Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'FILTER BY STATUS',
                              style: AppTypography.labelSmall,
                            ),
                            SoberBadge(
                              label:
                                  '${filteredAssignments.length} of ${allAssignments.length}',
                              backgroundColor: AppColors.secondaryContainer,
                              textColor: AppColors.textSecondary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Status Filter Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip(
                                label: 'All',
                                count: allAssignments.length,
                                isSelected: _selectedStatusFilter == null,
                                onSelected: () {
                                  setState(() {
                                    _selectedStatusFilter = null;
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                label: 'Pending',
                                count: allAssignments
                                    .where(
                                      (a) =>
                                          a.status == AssignmentStatus.pending,
                                    )
                                    .length,
                                isSelected:
                                    _selectedStatusFilter ==
                                    AssignmentStatus.pending,
                                onSelected: () {
                                  setState(() {
                                    _selectedStatusFilter =
                                        AssignmentStatus.pending;
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                label: 'In Progress',
                                count: allAssignments
                                    .where(
                                      (a) =>
                                          a.status ==
                                          AssignmentStatus.inProgress,
                                    )
                                    .length,
                                isSelected:
                                    _selectedStatusFilter ==
                                    AssignmentStatus.inProgress,
                                onSelected: () {
                                  setState(() {
                                    _selectedStatusFilter =
                                        AssignmentStatus.inProgress;
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                label: 'Completed',
                                count: allAssignments
                                    .where(
                                      (a) =>
                                          a.status ==
                                          AssignmentStatus.completed,
                                    )
                                    .length,
                                isSelected:
                                    _selectedStatusFilter ==
                                    AssignmentStatus.completed,
                                onSelected: () {
                                  setState(() {
                                    _selectedStatusFilter =
                                        AssignmentStatus.completed;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // 4. Filter-Specific Empty State
                        if (filteredAssignments.isEmpty)
                          SoberCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 28,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.filter_list_off_outlined,
                                    size: 32,
                                    color: AppColors.textMuted,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No ${_selectedStatusFilter?.label} assignments',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Try selecting a different filter above to view other tasks.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedStatusFilter = null;
                                      });
                                    },
                                    child: const Text('View All Assignments'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          // Populated Assignment Cards
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredAssignments.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final assignment = filteredAssignments[index];
                              final isUpdating = _updatingAssignmentIds
                                  .contains(assignment.id);

                              // Resolve community site name
                              final site = siteMap[assignment.siteId];
                              final siteName =
                                  assignment.siteName ??
                                  site?.name ??
                                  (assignment.siteId.isNotEmpty
                                      ? 'Site: ${assignment.siteId}'
                                      : 'Central Distribution Hub');

                              return _AssignmentCard(
                                assignment: assignment,
                                siteName: siteName,
                                isUpdating: isUpdating,
                                onUpdateStatus: (newStatus) =>
                                    _handleStatusUpdate(assignment, newStatus),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : AppColors.secondaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

/// Card component displaying:
/// - Community site name
/// - Task description
/// - Assigned date
/// - Current status badge
/// - Workflow action buttons
class _AssignmentCard extends StatelessWidget {
  final Assignment assignment;
  final String siteName;
  final bool isUpdating;
  final ValueChanged<AssignmentStatus> onUpdateStatus;

  const _AssignmentCard({
    required this.assignment,
    required this.siteName,
    required this.isUpdating,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    return SoberCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Site Name & Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        siteName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusBadge(assignment.status),
            ],
          ),

          const SizedBox(height: 10),

          // Task Description
          Text(
            assignment.taskDescription,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.45,
            ),
          ),

          const SizedBox(height: 12),

          // Assigned Date
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 5),
              Text(
                'Assigned: ${_formatDate(assignment.assignedAt)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Actions appropriate to current status
          if (isUpdating)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            )
          else
            _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(AssignmentStatus status) {
    Color bg;
    Color fg;
    IconData icon;

    switch (status) {
      case AssignmentStatus.pending:
        bg = AppColors.warningContainer;
        fg = AppColors.warning;
        icon = Icons.schedule_outlined;
        break;
      case AssignmentStatus.inProgress:
        bg = AppColors.primaryContainer;
        fg = AppColors.primary;
        icon = Icons.sync_outlined;
        break;
      case AssignmentStatus.completed:
        bg = AppColors.successContainer;
        fg = AppColors.success;
        icon = Icons.check_circle_outline;
        break;
    }

    return SoberBadge(
      label: status.label,
      backgroundColor: bg,
      textColor: fg,
      icon: icon,
    );
  }

  Widget _buildActionButtons() {
    switch (assignment.status) {
      case AssignmentStatus.pending:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.play_arrow_outlined, size: 16),
                label: const Text('Start Task'),
                onPressed: () => onUpdateStatus(AssignmentStatus.inProgress),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Mark Complete'),
                onPressed: () => onUpdateStatus(AssignmentStatus.completed),
              ),
            ),
          ],
        );

      case AssignmentStatus.inProgress:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: const Text('Mark Completed'),
                onPressed: () => onUpdateStatus(AssignmentStatus.completed),
              ),
            ),
          ],
        );

      case AssignmentStatus.completed:
        return Row(
          children: const [
            Icon(Icons.check_circle, size: 16, color: AppColors.success),
            SizedBox(width: 6),
            Text(
              'Task Completed',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ],
        );
    }
  }

  static String _formatDate(DateTime date) {
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
