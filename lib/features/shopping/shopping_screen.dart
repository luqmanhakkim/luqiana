import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../config/theme.dart';
import '../../core/models/shopping.dart';
import '../../core/models/trip.dart';
import '../../core/widgets/trip_selector.dart';
import '../home/application/trips_notifier.dart';
import 'application/shopping_notifier.dart';

class ShoppingScreen extends HookConsumerWidget {
  const ShoppingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = ref.watch(tripsProvider);
    final allItems = ref.watch(shoppingProvider);

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
    final purchasedCount = items.where((i) => i.isPurchased).length;
    final total = items.length;
    final progress = total == 0 ? 0.0 : purchasedCount / total;

    // Compute estimated total (items with a price)
    final estimatedTotal = items.fold<double>(
      0,
      (sum, i) => sum + (i.estimatedPrice ?? 0) * i.quantity,
    );
    final purchasedTotal = items
        .where((i) => i.isPurchased)
        .fold<double>(0, (sum, i) => sum + (i.estimatedPrice ?? 0) * i.quantity);
    final hasPrices = items.any((i) => i.estimatedPrice != null);

    // Group by category; unpurchased first within each group
    final grouped = <ShoppingCategory, List<ShoppingItem>>{};
    for (final cat in ShoppingCategory.values) {
      final catItems = items.where((i) => i.category == cat).toList()
        ..sort((a, b) {
          if (a.isPurchased == b.isPurchased) return 0;
          return a.isPurchased ? 1 : -1;
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
                        'Shopping List',
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
                            Icons.shopping_bag_rounded,
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
              selectedIndex: selectedTripIndex.value,
              onSelected: (i) => selectedTripIndex.value = i,
            ),
          ),

        // ── Summary card ─────────────────────────────────────────────────────
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
                        'Shopping Progress',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        total == 0
                            ? 'No items yet'
                            : '$purchasedCount / $total bought',
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
                  if (hasPrices) ...[
                    const SizedBox(height: 14),
                    const Divider(color: AppColors.divider, height: 1),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _SummaryChip(
                          label: 'Estimated',
                          value:
                              '${trip.currency} ${estimatedTotal.toStringAsFixed(2)}',
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 12),
                        _SummaryChip(
                          label: 'Spent',
                          value:
                              '${trip.currency} ${purchasedTotal.toStringAsFixed(2)}',
                          color: AppColors.success,
                        ),
                      ],
                    ),
                  ],
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
                          'All items bought! 🛍️',
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
            child: _EmptyShopping(),
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
                  return _ShoppingItemTile(
                    key: ValueKey(item.id),
                    item: item,
                    currency: trip.currency,
                    onToggle: () => ref
                        .read(shoppingProvider.notifier)
                        .toggleItem(item.id),
                    onDelete: () => ref
                        .read(shoppingProvider.notifier)
                        .deleteItem(item.id),
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
// Summary chip
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
// Category header
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryHeader extends StatelessWidget {
  final ShoppingCategory category;
  final int count;

  const _CategoryHeader({required this.category, required this.count});

  static IconData _icon(ShoppingCategory cat) {
    switch (cat) {
      case ShoppingCategory.clothing:
        return Icons.checkroom_rounded;
      case ShoppingCategory.electronics:
        return Icons.electrical_services_rounded;
      case ShoppingCategory.food:
        return Icons.restaurant_rounded;
      case ShoppingCategory.souvenirs:
        return Icons.card_giftcard_rounded;
      case ShoppingCategory.beauty:
        return Icons.face_rounded;
      case ShoppingCategory.accessories:
        return Icons.watch_rounded;
      case ShoppingCategory.other:
        return Icons.more_horiz_rounded;
    }
  }

  static Color _color(ShoppingCategory cat) {
    switch (cat) {
      case ShoppingCategory.clothing:
        return const Color(0xFFBE185D);
      case ShoppingCategory.electronics:
        return const Color(0xFF7C3AED);
      case ShoppingCategory.food:
        return const Color(0xFFEA580C);
      case ShoppingCategory.souvenirs:
        return const Color(0xFF0D9488);
      case ShoppingCategory.beauty:
        return const Color(0xFFDB2777);
      case ShoppingCategory.accessories:
        return const Color(0xFF4F46E5);
      case ShoppingCategory.other:
        return AppColors.textSecondary;
    }
  }

  static String _label(ShoppingCategory cat) {
    switch (cat) {
      case ShoppingCategory.clothing:
        return 'Clothing';
      case ShoppingCategory.electronics:
        return 'Electronics';
      case ShoppingCategory.food:
        return 'Food & Drinks';
      case ShoppingCategory.souvenirs:
        return 'Souvenirs';
      case ShoppingCategory.beauty:
        return 'Beauty';
      case ShoppingCategory.accessories:
        return 'Accessories';
      case ShoppingCategory.other:
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
// Shopping item tile — checkbox + quantity + price + swipe-to-delete
// ─────────────────────────────────────────────────────────────────────────────

class _ShoppingItemTile extends StatelessWidget {
  final ShoppingItem item;
  final String currency;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _ShoppingItemTile({
    super.key,
    required this.item,
    required this.currency,
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
                    // Animated checkbox
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: item.isPurchased
                            ? AppColors.success
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: item.isPurchased
                              ? AppColors.success
                              : AppColors.divider,
                          width: 2,
                        ),
                      ),
                      child: item.isPurchased
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 14,
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    // Name + optional price
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: item.isPurchased
                                  ? AppColors.textHint
                                  : AppColors.textPrimary,
                              decoration: item.isPurchased
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: AppColors.textHint,
                            ),
                          ),
                          if (item.estimatedPrice != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              '$currency ${(item.estimatedPrice! * item.quantity).toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: item.isPurchased
                                    ? AppColors.textHint
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Quantity badge
                    if (item.quantity > 1) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: item.isPurchased
                              ? AppColors.surfaceVariant
                              : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'x${item.quantity}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: item.isPurchased
                                ? AppColors.textHint
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
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

class _EmptyShopping extends StatelessWidget {
  const _EmptyShopping();

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
                Icons.shopping_bag_outlined,
                size: 44,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nothing to buy yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Tap + to add items you want\nto buy on your trip!',
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
    final nameCtrl = useTextEditingController();
    final priceCtrl = useTextEditingController();
    final quantity = useState(1);
    final selectedCategory = useState(ShoppingCategory.clothing);

    void submit() {
      if (!formKey.currentState!.validate()) return;
      final priceText = priceCtrl.text.trim();
      final item = ShoppingItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        tripId: tripId,
        name: nameCtrl.text.trim(),
        quantity: quantity.value,
        estimatedPrice:
            priceText.isEmpty ? null : double.tryParse(priceText),
        category: selectedCategory.value,
      );
      ref.read(shoppingProvider.notifier).addItem(item);
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
                  'Add to Shopping List',
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
          // Scrollable form
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
                      controller: nameCtrl,
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _fieldDecoration(
                        'Item name (e.g. Sneakers, Matcha Kit Kat…)',
                        Icons.shopping_bag_outlined,
                        context.appPrimary,
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),

                    // Quantity + Estimated price row
                    Row(
                      children: [
                        // Quantity stepper
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Quantity',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.divider),
                                ),
                                child: Row(
                                  children: [
                                    _StepperButton(
                                      icon: Icons.remove_rounded,
                                      onTap: () {
                                        if (quantity.value > 1) {
                                          quantity.value--;
                                        }
                                      },
                                    ),
                                    Expanded(
                                      child: Text(
                                        '${quantity.value}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    _StepperButton(
                                      icon: Icons.add_rounded,
                                      onTap: () => quantity.value++,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Estimated price
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Est. Price (optional)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: priceCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,2}'),
                                  ),
                                ],
                                decoration: _fieldDecoration(
                                  '0.00',
                                  Icons.attach_money_rounded,
                                  context.appPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

                    // Submit
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

  static InputDecoration _fieldDecoration(
      String hint, IconData icon, Color primary) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
      prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quantity stepper button
// ─────────────────────────────────────────────────────────────────────────────

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 52,
          child: Icon(icon, size: 20, color: context.appPrimary),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category chip selector
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryChipSelector extends StatelessWidget {
  final ShoppingCategory selected;
  final ValueChanged<ShoppingCategory> onChanged;

  const _CategoryChipSelector({
    required this.selected,
    required this.onChanged,
  });

  static IconData _icon(ShoppingCategory cat) {
    switch (cat) {
      case ShoppingCategory.clothing:
        return Icons.checkroom_rounded;
      case ShoppingCategory.electronics:
        return Icons.electrical_services_rounded;
      case ShoppingCategory.food:
        return Icons.restaurant_rounded;
      case ShoppingCategory.souvenirs:
        return Icons.card_giftcard_rounded;
      case ShoppingCategory.beauty:
        return Icons.face_rounded;
      case ShoppingCategory.accessories:
        return Icons.watch_rounded;
      case ShoppingCategory.other:
        return Icons.more_horiz_rounded;
    }
  }

  static Color _color(ShoppingCategory cat) {
    switch (cat) {
      case ShoppingCategory.clothing:
        return const Color(0xFFBE185D);
      case ShoppingCategory.electronics:
        return const Color(0xFF7C3AED);
      case ShoppingCategory.food:
        return const Color(0xFFEA580C);
      case ShoppingCategory.souvenirs:
        return const Color(0xFF0D9488);
      case ShoppingCategory.beauty:
        return const Color(0xFFDB2777);
      case ShoppingCategory.accessories:
        return const Color(0xFF4F46E5);
      case ShoppingCategory.other:
        return AppColors.textSecondary;
    }
  }

  static String _label(ShoppingCategory cat) {
    switch (cat) {
      case ShoppingCategory.clothing:
        return 'Clothing';
      case ShoppingCategory.electronics:
        return 'Electronics';
      case ShoppingCategory.food:
        return 'Food & Drinks';
      case ShoppingCategory.souvenirs:
        return 'Souvenirs';
      case ShoppingCategory.beauty:
        return 'Beauty';
      case ShoppingCategory.accessories:
        return 'Accessories';
      case ShoppingCategory.other:
        return 'Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ShoppingCategory.values.map((cat) {
        final isSelected = cat == selected;
        final color = _color(cat);
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
