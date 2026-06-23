import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../config/theme.dart';
import '../../core/models/checklist.dart';
import '../../core/models/trip.dart';
import '../../core/widgets/trip_selector.dart';
import '../home/application/trips_notifier.dart';
import 'application/checklist_notifier.dart';

class ChecklistScreen extends HookConsumerWidget {
  const ChecklistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = ref.watch(tripsProvider);
    final allItems = ref.watch(checklistProvider);

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

    final defaultTripIdx =
        trips.indexWhere((t) => t.status == TripStatus.ongoing);
    final selectedTripIndex =
        useState(defaultTripIdx == -1 ? 0 : defaultTripIdx);
    final trip = trips[selectedTripIndex.value];

    final items = allItems.where((i) => i.tripId == trip.id).toList();
    final checkedCount = items.where((i) => i.isChecked).length;
    final total = items.length;
    final progress = total == 0 ? 0.0 : checkedCount / total;

    // Group by category, only categories that have items; unchecked items first
    final grouped = <ChecklistCategory, List<ChecklistItem>>{};
    for (final cat in ChecklistCategory.values) {
      final catItems = items.where((i) => i.category == cat).toList()
        ..sort((a, b) {
          if (a.isChecked == b.isChecked) return 0;
          return a.isChecked ? 1 : -1;
        });
      if (catItems.isNotEmpty) grouped[cat] = catItems;
    }

    void showAddSheet() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _AddItemSheet(tripId: trip.id),
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
                        'Packing List',
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
                            Icons.luggage_rounded,
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

        // ── Trip selector (multi-trip) ───────────────────────────────────────
        if (trips.length > 1)
          SliverToBoxAdapter(
            child: TripSelectorButton(
              trips: trips,
              selectedIndex: selectedTripIndex.value,
              onSelected: (i) => selectedTripIndex.value = i,
            ),
          ),

        // ── Progress card ────────────────────────────────────────────────────
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Packing Progress',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        total == 0
                            ? 'No items yet'
                            : '$checkedCount / $total packed',
                        style: TextStyle(
                          fontSize: 13,
                          color: total == 0
                              ? AppColors.textHint
                              : context.appPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress == 1.0 && total > 0
                            ? AppColors.success
                            : context.appPrimary,
                      ),
                      minHeight: 8,
                    ),
                  ),
                  if (total > 0 && progress == 1.0) ...[
                    const SizedBox(height: 10),
                    const Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.success,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'All packed! Ready to go 🎉',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // ── Empty state or grouped items ─────────────────────────────────────
        if (items.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyChecklist(),
          )
        else
          for (final entry in grouped.entries) ...[
            SliverToBoxAdapter(
              child: _CategoryHeader(
                category: entry.key,
                count: entry.value.length,
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = entry.value[index];
                  return _ChecklistItemTile(
                    key: ValueKey(item.id),
                    item: item,
                    onToggle: () =>
                        ref.read(checklistProvider.notifier).toggleItem(item.id),
                    onDelete: () =>
                        ref.read(checklistProvider.notifier).deleteItem(item.id),
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
// Category header
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryHeader extends StatelessWidget {
  final ChecklistCategory category;
  final int count;

  const _CategoryHeader({required this.category, required this.count});

  static IconData _icon(ChecklistCategory cat) {
    switch (cat) {
      case ChecklistCategory.documents:
        return Icons.description_rounded;
      case ChecklistCategory.clothing:
        return Icons.checkroom_rounded;
      case ChecklistCategory.electronics:
        return Icons.electrical_services_rounded;
      case ChecklistCategory.toiletries:
        return Icons.soap_rounded;
      case ChecklistCategory.health:
        return Icons.medical_services_rounded;
      case ChecklistCategory.money:
        return Icons.account_balance_wallet_rounded;
      case ChecklistCategory.other:
        return Icons.more_horiz_rounded;
    }
  }

  static Color _color(ChecklistCategory cat) {
    switch (cat) {
      case ChecklistCategory.documents:
        return const Color(0xFF1B6CA8);
      case ChecklistCategory.clothing:
        return const Color(0xFFBE185D);
      case ChecklistCategory.electronics:
        return const Color(0xFF7C3AED);
      case ChecklistCategory.toiletries:
        return const Color(0xFF0D9488);
      case ChecklistCategory.health:
        return const Color(0xFFEA580C);
      case ChecklistCategory.money:
        return const Color(0xFF059669);
      case ChecklistCategory.other:
        return AppColors.textSecondary;
    }
  }

  static String _label(ChecklistCategory cat) {
    switch (cat) {
      case ChecklistCategory.documents:
        return 'Documents';
      case ChecklistCategory.clothing:
        return 'Clothing';
      case ChecklistCategory.electronics:
        return 'Electronics';
      case ChecklistCategory.toiletries:
        return 'Toiletries';
      case ChecklistCategory.health:
        return 'Health & Medicine';
      case ChecklistCategory.money:
        return 'Money & Cards';
      case ChecklistCategory.other:
        return 'Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(category);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_icon(category), size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Text(
            _label(category),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const Spacer(),
          Text(
            '$count item${count == 1 ? '' : 's'}',
            style: const TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single checklist item tile — animated checkbox + swipe-to-delete
// ─────────────────────────────────────────────────────────────────────────────

class _ChecklistItemTile extends StatelessWidget {
  final ChecklistItem item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _ChecklistItemTile({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.id),
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
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: item.isChecked
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: item.isChecked
                              ? Theme.of(context).colorScheme.primary
                              : AppColors.divider,
                          width: 2,
                        ),
                      ),
                      child: item.isChecked
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 14,
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: item.isChecked
                              ? AppColors.textHint
                              : AppColors.textPrimary,
                          decoration: item.isChecked
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: AppColors.textHint,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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

class _EmptyChecklist extends StatelessWidget {
  const _EmptyChecklist();

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
              Icons.checklist_rounded,
              size: 44,
              color: Theme.of(context).colorScheme.primary,
            ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nothing to pack yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Tap + to start building\nyour packing list!',
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
// Add item bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AddItemSheet extends HookConsumerWidget {
  final String tripId;

  const _AddItemSheet({required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final titleCtrl = useTextEditingController();
    final selectedCategory = useState(ChecklistCategory.documents);

    void submit() {
      if (!formKey.currentState!.validate()) return;
      final item = ChecklistItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        tripId: tripId,
        title: titleCtrl.text.trim(),
        category: selectedCategory.value,
      );
      ref.read(checklistProvider.notifier).addItem(item);
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
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
            child: Row(
              children: [
                const Text(
                  'Add to Packing List',
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
                    // Item name
                    TextFormField(
                      controller: titleCtrl,
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'e.g. Passport, Charger, Sunscreen…',
                        hintStyle: const TextStyle(
                          color: AppColors.textHint,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.add_box_outlined,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
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
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),
                    // Category
                    const Text(
                      'Category',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _CategoryChipSelector(
                      selected: selectedCategory.value,
                      onChanged: (c) => selectedCategory.value = c,
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
                          'Add to List',
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

class _CategoryChipSelector extends StatelessWidget {
  final ChecklistCategory selected;
  final ValueChanged<ChecklistCategory> onChanged;

  const _CategoryChipSelector({
    required this.selected,
    required this.onChanged,
  });

  static IconData _icon(ChecklistCategory cat) {
    switch (cat) {
      case ChecklistCategory.documents:
        return Icons.description_rounded;
      case ChecklistCategory.clothing:
        return Icons.checkroom_rounded;
      case ChecklistCategory.electronics:
        return Icons.electrical_services_rounded;
      case ChecklistCategory.toiletries:
        return Icons.soap_rounded;
      case ChecklistCategory.health:
        return Icons.medical_services_rounded;
      case ChecklistCategory.money:
        return Icons.account_balance_wallet_rounded;
      case ChecklistCategory.other:
        return Icons.more_horiz_rounded;
    }
  }

  static Color _color(ChecklistCategory cat) {
    switch (cat) {
      case ChecklistCategory.documents:
        return const Color(0xFF1B6CA8);
      case ChecklistCategory.clothing:
        return const Color(0xFFBE185D);
      case ChecklistCategory.electronics:
        return const Color(0xFF7C3AED);
      case ChecklistCategory.toiletries:
        return const Color(0xFF0D9488);
      case ChecklistCategory.health:
        return const Color(0xFFEA580C);
      case ChecklistCategory.money:
        return const Color(0xFF059669);
      case ChecklistCategory.other:
        return AppColors.textSecondary;
    }
  }

  static String _label(ChecklistCategory cat) {
    switch (cat) {
      case ChecklistCategory.documents:
        return 'Documents';
      case ChecklistCategory.clothing:
        return 'Clothing';
      case ChecklistCategory.electronics:
        return 'Electronics';
      case ChecklistCategory.toiletries:
        return 'Toiletries';
      case ChecklistCategory.health:
        return 'Health';
      case ChecklistCategory.money:
        return 'Money';
      case ChecklistCategory.other:
        return 'Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ChecklistCategory.values.map((cat) {
        final isSelected = cat == selected;
        final color = _color(cat);
        return GestureDetector(
          onTap: () => onChanged(cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
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
                  _icon(cat),
                  size: 15,
                  color: isSelected ? color : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  _label(cat),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
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
