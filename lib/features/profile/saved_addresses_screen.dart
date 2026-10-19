import 'package:flutter/material.dart' hide Text;
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/location_detect.dart';
import '../../core/widgets/common.dart';
import '../../models/misc_models.dart';
import '../../providers/profile_provider.dart';
import 'package:customer_app/core/l10n/localized_text.dart';

class SavedAddressesScreen extends StatelessWidget {
  const SavedAddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProfileProvider>();
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: const GradientAppBar(title: 'Saved Addresses'),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Address',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const _AddressSheet(),
        ),
      ),
      body: p.addresses.isEmpty
          ? const EmptyState(
              icon: Icons.bookmark_border_rounded,
              title: 'No saved addresses',
              subtitle:
                  'Save frequently used ceremony locations for faster booking.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: p.addresses.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final a = p.addresses[i];
                return Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.accentLight,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.accent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.label ?? 'Address',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              a.fullDisplay,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            context.read<ProfileProvider>().removeAddress(a.id),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.danger,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _AddressSheet extends StatefulWidget {
  const _AddressSheet();

  @override
  State<_AddressSheet> createState() => _AddressSheetState();
}

class _AddressSheetState extends State<_AddressSheet> {
  final _label = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _pincode = TextEditingController();
  double? _latitude;
  double? _longitude;

  @override
  void dispose() {
    _label.dispose();
    _address.dispose();
    _city.dispose();
    _state.dispose();
    _pincode.dispose();
    super.dispose();
  }

  void _save() {
    if (_address.text.trim().isEmpty) {
      showAppToast(
        context,
        'Please enter the address.',
        type: ToastType.warning,
        title: 'Address',
      );
      return;
    }
    if (_pincode.text.trim().length != 6) {
      showAppToast(
        context,
        'Please enter a valid 6-digit pincode.',
        type: ToastType.warning,
        title: 'Address',
      );
      return;
    }
    context.read<ProfileProvider>().upsertAddress(
      SavedAddress(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        label: _label.text.trim().isEmpty ? 'Home' : _label.text.trim(),
        address: _address.text.trim(),
        city: _city.text.trim(),
        state: _state.text.trim(),
        pincode: _pincode.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
      ),
    );
    showAppToast(
      context,
      'Address saved.',
      type: ToastType.success,
      title: 'Address',
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Address',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Label',
                controller: _label,
                hint: 'Home / Office / Temple',
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Address',
                controller: _address,
                hint: 'House, Street, Landmark',
                maxLines: 2,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(label: 'City', controller: _city),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(label: 'State', controller: _state),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Pincode',
                controller: _pincode,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),
              DetectLocationButton(
                onDetected: (loc) => setState(() {
                  if ((loc.city ?? '').isNotEmpty) _city.text = loc.city!;
                  if ((loc.state ?? '').isNotEmpty) _state.text = loc.state!;
                  if ((loc.pincode ?? '').isNotEmpty) {
                    _pincode.text = loc.pincode!;
                  }
                  if (_address.text.trim().isEmpty &&
                      (loc.addressLine ?? '').isNotEmpty) {
                    _address.text = loc.addressLine!;
                  }
                  _latitude = loc.latitude;
                  _longitude = loc.longitude;
                }),
              ),
              const SizedBox(height: 22),
              AppButton(label: 'Save Address', onPressed: _save),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
