import 'package:flutter/material.dart' hide Text;
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../models/user_session.dart';
import '../../providers/profile_provider.dart';
import 'package:customer_app/core/l10n/localized_text.dart';

class FamilyMembersScreen extends StatefulWidget {
  const FamilyMembersScreen({super.key});

  @override
  State<FamilyMembersScreen> createState() => _FamilyMembersScreenState();
}

class _FamilyMembersScreenState extends State<FamilyMembersScreen> {
  bool saving = false;

  static const _relations = [
    'Spouse',
    'Father',
    'Mother',
    'Son',
    'Daughter',
    'Brother',
    'Sister',
    'Grandfather',
    'Grandmother',
    'Other',
  ];

  Future<void> _add() async {
    final member = await showDialog<FamilyMember>(
      context: context,
      builder: (_) => const _MemberDialog(),
    );
    if (member == null || !mounted) return;
    final list = [...context.read<ProfileProvider>().familyMembers, member];
    await _persist(list);
  }

  Future<void> _remove(int index) async {
    final list = [...context.read<ProfileProvider>().familyMembers]
      ..removeAt(index);
    await _persist(list);
  }

  Future<void> _persist(List<FamilyMember> list) async {
    setState(() => saving = true);
    await context.read<ProfileProvider>().saveFamilyMembers(list);
    if (!mounted) return;
    setState(() => saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProfileProvider>();
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: const GradientAppBar(title: 'Family Members'),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text(
          'Add Member',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        onPressed: saving ? null : _add,
      ),
      body: p.loading
          ? const LoadingView(label: 'Loading family members...')
          : p.familyMembers.isEmpty
          ? const EmptyState(
              icon: Icons.family_restroom_rounded,
              title: 'No family members added',
              subtitle: 'Add family details so Acharyas can perform samskaras and blessings for everyone.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: p.familyMembers.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final m = p.familyMembers[i];
                final initials = (m.name ?? '?').trim().isEmpty
                    ? '?'
                    : (m.name!.trim()[0].toUpperCase());
                return Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.accentLight,
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.name ?? '-',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              [
                                m.relation ?? 'Family',
                                if (m.nakshatra != null &&
                                    m.nakshatra!.isNotEmpty)
                                  m.nakshatra!,
                              ].join(' • '),
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: saving ? null : () => _remove(i),
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

class _MemberDialog extends StatefulWidget {
  const _MemberDialog();

  @override
  State<_MemberDialog> createState() => _MemberDialogState();
}

class _MemberDialogState extends State<_MemberDialog> {
  final _name = TextEditingController();
  final _relationOther = TextEditingController();
  final _nakshatra = TextEditingController();
  String relation = 'Spouse';

  @override
  void dispose() {
    _name.dispose();
    _relationOther.dispose();
    _nakshatra.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOther = relation == 'Other';
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Family Member',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(label: 'Full Name', controller: _name),
              const SizedBox(height: 14),
              const Text(
                'RELATION',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: relation,
                isExpanded: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                items: _FamilyMembersScreenState._relations
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setState(() => relation = v ?? 'Spouse'),
              ),
              if (isOther) ...[
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Specify Relation',
                  controller: _relationOther,
                  hint: 'e.g. Father-in-Law',
                ),
              ],
              const SizedBox(height: 14),
              AppTextField(
                label: 'Nakshatra (optional)',
                controller: _nakshatra,
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Add Member',
                onPressed: () {
                  if (_name.text.trim().isEmpty) {
                    showAppToast(
                      context,
                      'Please enter the name.',
                      type: ToastType.warning,
                      title: 'Family',
                    );
                    return;
                  }
                  final resolvedRelation = (relation == 'Other' &&
                          _relationOther.text.trim().isNotEmpty)
                      ? _relationOther.text.trim()
                      : relation;
                  Navigator.of(context).pop(
                    FamilyMember(
                      name: _name.text.trim(),
                      relation: resolvedRelation,
                      nakshatra: _nakshatra.text.trim().isEmpty
                          ? null
                          : _nakshatra.text.trim(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
