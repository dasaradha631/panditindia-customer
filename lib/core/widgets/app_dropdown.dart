import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppDropdownOption<T> {
  const AppDropdownOption({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// Compact dropdown that opens a modal bottom sheet instead of navigating to
/// an unrelated page (PDF section 13 - keep web dropdowns as in-place
/// selectors on mobile).
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.label,
    required this.hint,
    required this.options,
    this.value,
    this.onChanged,
    this.prefixIcon,
    this.validator,
  });

  final String label;
  final String hint;
  final List<AppDropdownOption<T>> options;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final IconData? prefixIcon;
  final String? Function(T?)? validator;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppDropdownOption<T>? selected = value == null
        ? null
        : options.where((AppDropdownOption<T> o) => o.value == value).firstOrNull;

    final String? errorText = validator?.call(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: options.isEmpty ? null : () => _showSheet(context),
          child: InputDecorator(
            decoration: InputDecoration(
              hintText: hint,
              errorText: errorText,
              prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 20),
              suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded, size: 22),
            ),
            child: Text(
              selected?.label ?? hint,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: selected == null ? AppColors.muted : AppColors.ink,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showSheet(BuildContext context) async {
    final T? picked = await showModalBottomSheet<T>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: 14),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: Theme.of(sheetContext).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 12),
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final AppDropdownOption<T> option = options[index];
                  final bool isSelected = option.value == value;
                  return ListTile(
                    leading: option.icon == null
                        ? null
                        : Icon(option.icon, color: AppColors.primary),
                    title: Text(option.label),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: AppColors.primary)
                        : null,
                    onTap: () => Navigator.of(sheetContext).pop(option.value),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
    if (picked != null) {
      onChanged?.call(picked);
    }
  }
}
