import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../config/theme.dart';
import '../../core/models/travel_document.dart';
import '../../core/models/trip.dart';
import '../../core/widgets/trip_selector.dart';
import '../home/application/trips_notifier.dart';
import 'application/documents_notifier.dart';

class DocumentsScreen extends HookConsumerWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = ref.watch(tripsProvider);
    final allDocs = ref.watch(documentsProvider);

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

    final docs = allDocs.where((d) => d.tripId == trip.id).toList();

    void showAddSheet({TravelDocument? initial}) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _DocumentSheet(tripId: trip.id, initialDoc: initial),
      );
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 140,
          pinned: true,
          stretch: true,
          backgroundColor: context.appPrimaryDark,
          actions: [
            IconButton(
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              onPressed: () => showAddSheet(),
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
                        'Travel Docs',
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
                          const Icon(Icons.folder_outlined,
                              color: Colors.white60, size: 13),
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
        if (trips.length > 1)
          SliverToBoxAdapter(
            child: TripSelectorButton(
              trips: trips,
              selectedIndex: selectedIdx.value,
              onSelected: (i) => selectedIdx.value = i,
            ),
          ),
        if (docs.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyDocuments(),
          )
        else ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final doc = docs[index];
                  return _DocumentCard(
                    key: ValueKey(doc.id),
                    doc: doc,
                    onEdit: () => showAddSheet(initial: doc),
                    onDelete: () => ref
                        .read(documentsProvider.notifier)
                        .deleteDocument(doc.id),
                  );
                },
                childCount: docs.length,
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Document type metadata
// ─────────────────────────────────────────────────────────────────────────────

class _DocMeta {
  static IconData icon(DocumentType type) {
    switch (type) {
      case DocumentType.flight:
        return Icons.flight_rounded;
      case DocumentType.hotel:
        return Icons.hotel_rounded;
      case DocumentType.visa:
        return Icons.verified_rounded;
      case DocumentType.insurance:
        return Icons.health_and_safety_rounded;
      case DocumentType.other:
        return Icons.description_rounded;
    }
  }

  static Color color(DocumentType type) {
    switch (type) {
      case DocumentType.flight:
        return const Color(0xFF0284C7);
      case DocumentType.hotel:
        return const Color(0xFF7C3AED);
      case DocumentType.visa:
        return const Color(0xFF059669);
      case DocumentType.insurance:
        return const Color(0xFFEA580C);
      case DocumentType.other:
        return AppColors.textSecondary;
    }
  }

  static String label(DocumentType type) {
    switch (type) {
      case DocumentType.flight:
        return 'Flight';
      case DocumentType.hotel:
        return 'Hotel';
      case DocumentType.visa:
        return 'Visa';
      case DocumentType.insurance:
        return 'Insurance';
      case DocumentType.other:
        return 'Other';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Document card with expand/collapse
// ─────────────────────────────────────────────────────────────────────────────

class _DocumentCard extends HookWidget {
  final TravelDocument doc;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DocumentCard({
    super.key,
    required this.doc,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final expanded = useState(false);
    final color = _DocMeta.color(doc.type);
    final icon = _DocMeta.icon(doc.type);
    final typeLabel = _DocMeta.label(doc.type);

    final filledFields = doc.fields.entries
        .where((e) => e.value.trim().isNotEmpty)
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => expanded.value = !expanded.value,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 22, color: color),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                typeLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                            ),
                            if (filledFields.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                '${filledFields.length} field${filledFields.length == 1 ? '' : 's'}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    color: context.appPrimary.withOpacity(0.7),
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onEdit,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    color: Colors.redAccent.withOpacity(0.7),
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onDelete,
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    expanded.value
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textHint,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (expanded.value && filledFields.isNotEmpty) ...[
            const Divider(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: filledFields.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 110,
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          if (expanded.value && filledFields.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                'No details added yet. Tap edit to fill in.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textHint,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyDocuments extends StatelessWidget {
  const _EmptyDocuments();

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
                color:
                    Theme.of(context).colorScheme.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder_open_rounded,
                size: 44,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No documents yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Store your flight, hotel, visa\nand insurance details here!',
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
// Add / Edit document bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _DocumentSheet extends HookConsumerWidget {
  final String tripId;
  final TravelDocument? initialDoc;

  const _DocumentSheet({required this.tripId, this.initialDoc});

  bool get _isEditing => initialDoc != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedType = useState(
      initialDoc?.type ?? DocumentType.flight,
    );
    final titleCtrl = useTextEditingController(
      text: initialDoc?.title ?? '',
    );

    final fieldKeys = useMemoized(
      () => TravelDocument.fieldsForType(selectedType.value),
      [selectedType.value],
    );

    final controllers = useMemoized<Map<String, TextEditingController>>(
      () {
        final keys = TravelDocument.fieldsForType(selectedType.value);
        return {
          for (final k in keys)
            k: TextEditingController(
              text: initialDoc?.fields[k] ?? '',
            ),
        };
      },
      [selectedType.value],
    );

    useEffect(() {
      return () {
        for (final c in controllers.values) {
          c.dispose();
        }
      };
    }, [controllers]);

    void submit() {
      final title = titleCtrl.text.trim();
      if (title.isEmpty) return;
      final fields = <String, String>{
        for (final k in fieldKeys) k: controllers[k]?.text.trim() ?? '',
      };
      if (_isEditing) {
        final updated = initialDoc!.copyWith(
          type: selectedType.value,
          title: title,
          fields: fields,
        );
        ref.read(documentsProvider.notifier).updateDocument(updated);
      } else {
        final doc = TravelDocument(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          tripId: tripId,
          type: selectedType.value,
          title: title,
          fields: fields,
        );
        ref.read(documentsProvider.notifier).addDocument(doc);
      }
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
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
            child: Row(
              children: [
                Text(
                  _isEditing ? 'Edit Document' : 'Add Document',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                MediaQuery.of(context).viewInsets.bottom + 28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type selector
                  const Text(
                    'Type',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: DocumentType.values.map((type) {
                      final isSelected = type == selectedType.value;
                      final color = _DocMeta.color(type);
                      return GestureDetector(
                        onTap: () => selectedType.value = type,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 9),
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
                              Icon(_DocMeta.icon(type),
                                  size: 15,
                                  color: isSelected
                                      ? color
                                      : AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Text(
                                _DocMeta.label(type),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? color
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  // Title
                  const Text(
                    'Title',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: titleCtrl,
                    autofocus: !_isEditing,
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDeco(
                      'e.g. SQ456 to Tokyo',
                      Icons.title_rounded,
                      context.appPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Dynamic fields for type
                  const Text(
                    'Details',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...fieldKeys.map((key) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextFormField(
                        controller: controllers[key],
                        textCapitalization: TextCapitalization.words,
                        decoration: _inputDeco(
                          key,
                          Icons.notes_rounded,
                          context.appPrimary,
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
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
                      child: Text(
                        _isEditing ? 'Save Changes' : 'Add Document',
                        style: const TextStyle(
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
        ],
      ),
    );
  }

  static InputDecoration _inputDeco(
      String hint, IconData icon, Color primary) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
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
    );
  }
}
