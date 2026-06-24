import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../config/theme.dart';
import '../../core/models/expense.dart';
import '../../core/models/trip.dart';
import '../checklist/application/checklist_notifier.dart';
import '../expenses/application/expenses_notifier.dart';
import '../shopping/application/shopping_notifier.dart';

class TripSummaryScreen extends ConsumerWidget {
  final Trip trip;

  const TripSummaryScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allExpenses = ref.watch(expensesProvider);
    final allChecklist = ref.watch(checklistProvider);
    final allShopping = ref.watch(shoppingProvider);

    final expenses =
        allExpenses.where((e) => e.tripId == trip.id).toList();
    final checklist =
        allChecklist.where((i) => i.tripId == trip.id).toList();
    final shopping =
        allShopping.where((i) => i.tripId == trip.id).toList();

    final totalSpent =
        expenses.fold(0.0, (sum, e) => sum + e.amount);
    final budget = trip.budget;
    final progress =
        budget > 0 ? (totalSpent / budget).clamp(0.0, 1.0) : 0.0;
    final remaining = budget - totalSpent;

    final checkedCount = checklist.where((i) => i.isChecked).length;
    final checklistProgress =
        checklist.isEmpty ? 0.0 : checkedCount / checklist.length;

    final purchasedCount = shopping.where((i) => i.isPurchased).length;
    final shoppingProgress =
        shopping.isEmpty ? 0.0 : purchasedCount / shopping.length;

    // Category breakdown
    final catTotals = <ExpenseCategory, double>{};
    for (final e in expenses) {
      catTotals[e.category] = (catTotals[e.category] ?? 0) + e.amount;
    }
    final sortedCats = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final gradient =
        AppColors.tripGradients[trip.gradientIndex % AppColors.tripGradients.length];

    Color barColor(double p) {
      if (p < 0.6) return AppColors.success;
      if (p < 0.85) return AppColors.warning;
      return Colors.redAccent;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            stretch: true,
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          trip.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded,
                                color: Colors.white70, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${trip.destination}, ${trip.country}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.calendar_today_rounded,
                                color: Colors.white70, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              trip.formattedDateRange,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Stats row ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  _StatBox(
                    label: 'Duration',
                    value: '${trip.tripDuration}',
                    unit: 'days',
                    icon: Icons.timelapse_rounded,
                    color: const Color(0xFF0284C7),
                  ),
                  const SizedBox(width: 12),
                  _StatBox(
                    label: 'Status',
                    value: _statusLabel(trip.status),
                    unit: _statusSub(trip),
                    icon: _statusIcon(trip.status),
                    color: _statusColor(trip.status),
                  ),
                  const SizedBox(width: 12),
                  _StatBox(
                    label: 'Expenses',
                    value: '${expenses.length}',
                    unit: 'records',
                    icon: Icons.receipt_long_rounded,
                    color: const Color(0xFFBE185D),
                  ),
                ],
              ),
            ),
          ),

          // ── Budget card ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _SummaryCard(
                title: 'Budget Overview',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Spent',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${trip.currency} ${_fmt(totalSpent)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (budget > 0)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Budget',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${trip.currency} ${_fmt(budget)}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    if (budget > 0) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: AppColors.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              barColor(progress)),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            remaining >= 0
                                ? '${trip.currency} ${_fmt(remaining)} remaining'
                                : '${trip.currency} ${_fmt(-remaining)} over budget',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: remaining >= 0
                                  ? AppColors.success
                                  : Colors.redAccent,
                            ),
                          ),
                          Text(
                            '${(progress * 100).toStringAsFixed(0)}% used',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      const Text(
                        'No budget set for this trip',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // ── Category breakdown ───────────────────────────────────────────
          if (sortedCats.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _SummaryCard(
                  title: 'Spending by Category',
                  child: Column(
                    children: sortedCats.map((entry) {
                      final catColor = _catColor(entry.key);
                      final share = totalSpent > 0
                          ? entry.value / totalSpent
                          : 0.0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(_catIcon(entry.key),
                                    size: 14, color: catColor),
                                const SizedBox(width: 8),
                                Text(
                                  _catLabel(entry.key),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: catColor,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${trip.currency} ${_fmt(entry.value)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 36,
                                  child: Text(
                                    '${(share * 100).toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textHint,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: share,
                                backgroundColor: AppColors.surfaceVariant,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(catColor),
                                minHeight: 5,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

          // ── Checklist progress ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _SummaryCard(
                title: 'Packing Progress',
                child: _ProgressRow(
                  label: checklist.isEmpty
                      ? 'No items added'
                      : '$checkedCount / ${checklist.length} packed',
                  progress: checklistProgress,
                  color: checklist.isEmpty
                      ? AppColors.textHint
                      : checklistProgress == 1.0
                          ? AppColors.success
                          : context.appPrimary,
                  icon: Icons.luggage_rounded,
                  emptyText: 'Add packing items in the Checklist tab',
                  isEmpty: checklist.isEmpty,
                ),
              ),
            ),
          ),

          // ── Shopping progress ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _SummaryCard(
                title: 'Shopping Progress',
                child: _ProgressRow(
                  label: shopping.isEmpty
                      ? 'No items added'
                      : '$purchasedCount / ${shopping.length} bought',
                  progress: shoppingProgress,
                  color: shopping.isEmpty
                      ? AppColors.textHint
                      : shoppingProgress == 1.0
                          ? AppColors.success
                          : context.appPrimary,
                  icon: Icons.shopping_bag_rounded,
                  emptyText: 'Add shopping items in the Shopping tab',
                  isEmpty: shopping.isEmpty,
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  static String _fmt(double v) {
    final parts = v.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final buf = StringBuffer();
    int count = 0;
    for (int i = intPart.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buf.write(',');
      buf.write(intPart[i]);
      count++;
    }
    return '${buf.toString().split('').reversed.join()}.${parts[1]}';
  }

  static String _statusLabel(TripStatus s) {
    switch (s) {
      case TripStatus.upcoming:
        return 'Upcoming';
      case TripStatus.ongoing:
        return 'Ongoing';
      case TripStatus.completed:
        return 'Done';
    }
  }

  static String _statusSub(Trip t) {
    switch (t.status) {
      case TripStatus.upcoming:
        return 'in ${t.daysUntilTrip}d';
      case TripStatus.ongoing:
        return 'day ${t.dayOfTrip}/${t.tripDuration}';
      case TripStatus.completed:
        return t.formattedDateRange.split(' ').last;
    }
  }

  static IconData _statusIcon(TripStatus s) {
    switch (s) {
      case TripStatus.upcoming:
        return Icons.schedule_rounded;
      case TripStatus.ongoing:
        return Icons.flight_takeoff_rounded;
      case TripStatus.completed:
        return Icons.check_circle_rounded;
    }
  }

  static Color _statusColor(TripStatus s) {
    switch (s) {
      case TripStatus.upcoming:
        return const Color(0xFF0284C7);
      case TripStatus.ongoing:
        return AppColors.success;
      case TripStatus.completed:
        return AppColors.textSecondary;
    }
  }

  static IconData _catIcon(ExpenseCategory cat) {
    switch (cat) {
      case ExpenseCategory.food:
        return Icons.restaurant_rounded;
      case ExpenseCategory.transport:
        return Icons.directions_car_rounded;
      case ExpenseCategory.accommodation:
        return Icons.hotel_rounded;
      case ExpenseCategory.activities:
        return Icons.local_activity_rounded;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag_rounded;
      case ExpenseCategory.other:
        return Icons.more_horiz_rounded;
    }
  }

  static Color _catColor(ExpenseCategory cat) {
    switch (cat) {
      case ExpenseCategory.food:
        return const Color(0xFFEA580C);
      case ExpenseCategory.transport:
        return const Color(0xFF1B6CA8);
      case ExpenseCategory.accommodation:
        return const Color(0xFF7C3AED);
      case ExpenseCategory.activities:
        return const Color(0xFF0D9488);
      case ExpenseCategory.shopping:
        return const Color(0xFFBE185D);
      case ExpenseCategory.other:
        return AppColors.textSecondary;
    }
  }

  static String _catLabel(ExpenseCategory cat) {
    switch (cat) {
      case ExpenseCategory.food:
        return 'Food & Drink';
      case ExpenseCategory.transport:
        return 'Transport';
      case ExpenseCategory.accommodation:
        return 'Stay';
      case ExpenseCategory.activities:
        return 'Activities';
      case ExpenseCategory.shopping:
        return 'Shopping';
      case ExpenseCategory.other:
        return 'Other';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable summary card container
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SummaryCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat box (small)
// ─────────────────────────────────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
              ),
            ),
            Text(
              unit,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Progress row (checklist / shopping)
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressRow extends StatelessWidget {
  final String label;
  final double progress;
  final Color color;
  final IconData icon;
  final String emptyText;
  final bool isEmpty;

  const _ProgressRow({
    required this.label,
    required this.progress,
    required this.color,
    required this.icon,
    required this.emptyText,
    required this.isEmpty,
  });

  @override
  Widget build(BuildContext context) {
    if (isEmpty) {
      return Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textHint),
          const SizedBox(width: 10),
          Text(
            emptyText,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textHint,
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const Spacer(),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
