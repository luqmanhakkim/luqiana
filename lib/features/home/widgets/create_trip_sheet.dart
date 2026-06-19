import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../config/theme.dart';
import '../../../constants/app_strings.dart';
import '../../../core/data/location_data.dart';
import '../../../core/models/trip.dart';
import '../application/trips_notifier.dart';

class CreateTripSheet extends HookConsumerWidget {
  const CreateTripSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateTripSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController();
    final destController = useTextEditingController();
    final countryController = useTextEditingController();

    final selectedCountry = useState<CountryData?>(null);

    final startDate = useState<DateTime?>(null);
    final endDate = useState<DateTime?>(null);

    final formKey = useMemoized(() => GlobalKey<FormState>());

    Future<void> pickDateRange() async {
      final initialDateRange = startDate.value != null && endDate.value != null
          ? DateTimeRange(start: startDate.value!, end: endDate.value!)
          : null;

      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime.now().subtract(const Duration(days: 365)),
        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
        initialDateRange: initialDateRange,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.primary,
                onPrimary: Colors.white,
                surface: AppColors.surface,
                onSurface: AppColors.textPrimary,
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null) {
        startDate.value = picked.start;
        endDate.value = picked.end;
      }
    }

    void selectCountry() {
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.background,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Select Country',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: availableCountries.length,
                    itemBuilder: (context, index) {
                      final country = availableCountries[index];
                      return ListTile(
                        leading: Text(country.flag, style: const TextStyle(fontSize: 24)),
                        title: Text(country.name),
                        onTap: () {
                          selectedCountry.value = country;
                          countryController.text = '${country.flag} ${country.name}';
                          // Reset destination if country changes
                          destController.text = '';
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    void selectDestination() {
      if (selectedCountry.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a country first')),
        );
        return;
      }

      final cities = selectedCountry.value!.cities;

      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.background,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Select Destination',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: cities.length,
                    itemBuilder: (context, index) {
                      final city = cities[index];
                      return ListTile(
                        leading: const Icon(Icons.location_city_rounded, color: AppColors.primary),
                        title: Text(city),
                        onTap: () {
                          destController.text = city;
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    void submit() {
      if (formKey.currentState!.validate()) {
        if (startDate.value == null || endDate.value == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select dates')),
          );
          return;
        }

        final newTrip = Trip(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: nameController.text.trim(),
          destination: destController.text.trim(),
          country: selectedCountry.value?.name ?? countryController.text.trim(),
          startDate: startDate.value!,
          endDate: endDate.value!,
          gradientIndex: Random().nextInt(AppColors.tripGradients.length),
        );

        ref.read(tripsProvider.notifier).addTrip(newTrip);
        Navigator.of(context).pop();
      }
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    AppStrings.createTripTitle,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _InputField(
                        label: AppStrings.tripNameLabel,
                        hint: AppStrings.tripNameHint,
                        controller: nameController,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                        icon: Icons.title_rounded,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _InputField(
                              label: AppStrings.countryLabel,
                              hint: AppStrings.countryHint,
                              controller: countryController,
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                              icon: Icons.map_rounded,
                              readOnly: true,
                              onTap: selectCountry,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _InputField(
                              label: AppStrings.destinationLabel,
                              hint: AppStrings.destinationHint,
                              controller: destController,
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                              icon: Icons.location_city_rounded,
                              readOnly: true,
                              onTap: selectDestination,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        AppStrings.dateRangeLabel,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: pickDateRange,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  startDate.value != null && endDate.value != null
                                      ? '${_formatDate(startDate.value!)} - ${_formatDate(endDate.value!)}'
                                      : 'Select dates',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: startDate.value != null
                                        ? AppColors.textPrimary
                                        : AppColors.textHint,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (startDate.value == null)
                        const Padding(
                          padding: EdgeInsets.only(top: 6, left: 12),
                          child: Text(
                            '* Required',
                            style: TextStyle(color: Colors.redAccent, fontSize: 12),
                          ),
                        ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          AppStrings.saveTrip,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
      ),
    );
  }
}

String _formatDate(DateTime date) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

class _InputField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final IconData icon;
  final bool readOnly;
  final VoidCallback? onTap;

  const _InputField({
    required this.label,
    required this.hint,
    required this.controller,
    this.validator,
    required this.icon,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textHint),
            prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
          ),
        ),
      ],
    );
  }
}
