import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../config/theme.dart';
import '../../core/models/expense.dart';
import '../../core/models/trip.dart';
import '../../core/widgets/trip_selector.dart';
import '../home/application/trips_notifier.dart';
import 'application/expenses_notifier.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Amount formatter helper
// ─────────────────────────────────────────────────────────────────────────────

String _fmtAmount(double amount) {
  final parts = amount.toStringAsFixed(2).split('.');
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

// ─────────────────────────────────────────────────────────────────────────────
// Category metadata helper
// ─────────────────────────────────────────────────────────────────────────────

class _Cat {
  static IconData icon(ExpenseCategory cat) {
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

  static Color color(ExpenseCategory cat) {
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

  static String label(ExpenseCategory cat) {
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
// Main screen
// ─────────────────────────────────────────────────────────────────────────────

class ExpensesScreen extends HookConsumerWidget {
  const ExpensesScreen({super.key});


  static String _dateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = ref.watch(tripsProvider);
    final allExpenses = ref.watch(expensesProvider);

    if (trips.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text(
            'No trips yet.\nCreate a trip first!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
        ),
      );
    }

    final defaultIdx = trips.indexWhere((t) => t.status == TripStatus.ongoing);
    final selectedIdx = useState(defaultIdx == -1 ? 0 : defaultIdx);
    final trip = trips[selectedIdx.value];

    final expenses = allExpenses.where((e) => e.tripId == trip.id).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final totalSpent = expenses.fold(0.0, (s, e) => s + e.amount);
    final budget = trip.budget;
    final progress = budget > 0 ? (totalSpent / budget).clamp(0.0, 1.0) : 0.0;
    final remaining = budget - totalSpent;

    Color barColor() {
      if (progress < 0.6) return AppColors.success;
      if (progress < 0.85) return AppColors.warning;
      return Colors.redAccent;
    }

    final grouped = <String, List<Expense>>{};
    for (final e in expenses) {
      grouped.putIfAbsent(_dateKey(e.date), () => []).add(e);
    }

    void showAddSheet() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) =>
            _AddExpenseSheet(tripId: trip.id, currency: trip.currency),
      );
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── App bar ─────────────────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 140,
          pinned: true,
          stretch: true,
          backgroundColor: context.appPrimaryDark,
          actions: [
            IconButton(
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              onPressed: showAddSheet,
            ),
            const SizedBox(width: 4),
          ],
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [context.appPrimaryDark, context.appPrimary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 60, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Expenses',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Colors.white60,
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${trip.name} · ${trip.destination}',
                            style: const TextStyle(
                              color: Colors.white60,
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

        // ── Trip selector ────────────────────────────────────────────────────
        if (trips.length > 1)
          SliverToBoxAdapter(
            child: TripSelectorButton(
              trips: trips,
              selectedIndex: selectedIdx.value,
              onSelected: (i) => selectedIdx.value = i,
            ),
          ),

        // ── Budget / spend summary card ──────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Container(
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
                            '${trip.currency} ${_fmtAmount(totalSpent)}',
                            style: const TextStyle(
                              fontSize: 26,
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
                              '${trip.currency} ${_fmtAmount(budget)}',
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
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(barColor()),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          remaining >= 0
                              ? '${trip.currency} ${_fmtAmount(remaining)} remaining'
                              : '${trip.currency} ${_fmtAmount(-remaining)} over budget',
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
                  ],
                  if (budget == 0) ...[
                    if (expenses.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${expenses.length} transaction${expenses.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 6),
                      const Text(
                        'No budget set for this trip',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),

        // ── Category breakdown row ───────────────────────────────────────────
        if (expenses.isNotEmpty)
          SliverToBoxAdapter(
            child: _CategorySummaryRow(
              expenses: expenses,
              currency: trip.currency,
            ),
          ),

        // ── Transactions section header ──────────────────────────────────────
        if (expenses.isNotEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Text(
                'Transactions',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),

        // ── Empty state or grouped expense list ──────────────────────────────
        if (expenses.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyExpenses(),
          )
        else
          for (final entry in grouped.entries) ...[
            SliverToBoxAdapter(
              child: _DateHeader(label: entry.key),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final expense = entry.value[index];
                  return _ExpenseTile(
                    key: ValueKey(expense.id),
                    expense: expense,
                    currency: trip.currency,
                    onDelete: () => ref
                        .read(expensesProvider.notifier)
                        .deleteExpense(expense.id),
                  );
                },
                childCount: entry.value.length,
              ),
            ),
          ],

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Category summary horizontal scroll row
// ─────────────────────────────────────────────────────────────────────────────

class _CategorySummaryRow extends StatelessWidget {
  final List<Expense> expenses;
  final String currency;

  const _CategorySummaryRow({
    required this.expenses,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final totals = <ExpenseCategory, double>{};
    for (final e in expenses) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'By Category',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: sorted.map((entry) {
                final color = _Cat.color(entry.key);
                return Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_Cat.icon(entry.key), size: 15, color: color),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _Cat.label(entry.key),
                            style: TextStyle(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '$currency ${_fmtAmount(entry.value)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Date section header
// ─────────────────────────────────────────────────────────────────────────────

class _DateHeader extends StatelessWidget {
  final String label;

  const _DateHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single expense tile — swipe left to delete
// ─────────────────────────────────────────────────────────────────────────────

class _ExpenseTile extends StatelessWidget {
  final Expense expense;
  final String currency;
  final VoidCallback onDelete;

  const _ExpenseTile({
    super.key,
    required this.expense,
    required this.currency,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = _Cat.color(expense.category);
    final icon = _Cat.icon(expense.category);

    return Dismissible(
      key: ValueKey(expense.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_rounded, color: Colors.white, size: 22),
            SizedBox(height: 4),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (expense.note.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          expense.note,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ] else ...[
                        const SizedBox(height: 2),
                        Text(
                          _Cat.label(expense.category),
                          style: TextStyle(
                            fontSize: 12,
                            color: color.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${currency} ${_fmtAmount(expense.amount)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyExpenses extends StatelessWidget {
  const _EmptyExpenses();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 44,
              color: Theme.of(context).colorScheme.primary,
            ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No expenses yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Tap + to record your\nfirst expense!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add expense bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AddExpenseSheet extends HookConsumerWidget {
  final String tripId;
  final String currency;

  const _AddExpenseSheet({required this.tripId, required this.currency});

  static String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  static InputDecoration _fieldDecoration({
    required String hint,
    required Color primary,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: AppColors.textSecondary, size: 20)
          : null,
      filled: true,
      fillColor: AppColors.surfaceVariant,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final amountCtrl = useTextEditingController();
    final titleCtrl = useTextEditingController();
    final noteCtrl = useTextEditingController();
    final selectedCategory = useState(ExpenseCategory.food);
    final selectedDate = useState(DateTime.now());

    Future<void> pickDate() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: selectedDate.value,
        firstDate: DateTime(2020),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: context.appPrimary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        ),
      );
      if (picked != null) selectedDate.value = picked;
    }

    void submit() {
      if (!formKey.currentState!.validate()) return;
      final amount = double.tryParse(amountCtrl.text.trim());
      if (amount == null || amount <= 0) return;

      final expense = Expense(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        tripId: tripId,
        title: titleCtrl.text.trim(),
        amount: amount,
        category: selectedCategory.value,
        date: selectedDate.value,
        note: noteCtrl.text.trim(),
      );
      ref.read(expensesProvider.notifier).addExpense(expense);
      Navigator.of(context).pop();
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Sheet header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
            child: Row(
              children: [
                const Text(
                  'Add Expense',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          // Scrollable form body
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                MediaQuery.of(context).viewInsets.bottom + 28,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount field
                    TextFormField(
                      controller: amountCtrl,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9.]'),
                        ),
                      ],
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: const TextStyle(
                          color: AppColors.textHint,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        prefixText: '$currency  ',
                        prefixStyle: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: context.appPrimary,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Colors.redAccent),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.redAccent,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Enter an amount';
                        }
                        final parsed = double.tryParse(v.trim());
                        if (parsed == null || parsed <= 0) {
                          return 'Enter a valid amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Description / title field
                    TextFormField(
                      controller: titleCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _fieldDecoration(
                        hint: 'What did you spend on?',
                        primary: context.appPrimary,
                        prefixIcon: Icons.edit_rounded,
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),
                    // Category picker
                    const Text(
                      'Category',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _CategoryChips(
                      selected: selectedCategory.value,
                      onChanged: (c) => selectedCategory.value = c,
                    ),
                    const SizedBox(height: 20),
                    // Date picker row
                    GestureDetector(
                      onTap: pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _dateLabel(selectedDate.value),
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Note field (optional)
                    TextFormField(
                      controller: noteCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 2,
                      decoration: _fieldDecoration(
                        hint: 'Note (optional)',
                        primary: context.appPrimary,
                        prefixIcon: Icons.notes_rounded,
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.appPrimary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Add Expense',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category chip selector
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryChips extends StatelessWidget {
  final ExpenseCategory selected;
  final ValueChanged<ExpenseCategory> onChanged;

  const _CategoryChips({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ExpenseCategory.values.map((cat) {
        final isSelected = cat == selected;
        final color = _Cat.color(cat);
        return GestureDetector(
          onTap: () => onChanged(cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withOpacity(0.12)
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? color : AppColors.divider,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _Cat.icon(cat),
                  size: 15,
                  color: isSelected ? color : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  _Cat.label(cat),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected ? color : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
