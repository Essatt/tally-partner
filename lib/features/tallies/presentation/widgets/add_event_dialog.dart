import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/tally_event.dart';
import '../../../../utils/input_sanitizer.dart';
import '../../../../utils/color_extensions.dart';
import '../providers/tally_provider.dart';

class AddEventDialog extends ConsumerStatefulWidget {
  final Function(
      String name, String icon, String color, TallyType type, double value,
      {String? personId,
      List<String>? assignedBudgetIds,
      List<String>? additionalPersonIds}) onSave;
  final TallyEvent? existingEvent;

  const AddEventDialog({super.key, required this.onSave, this.existingEvent});

  @override
  ConsumerState<AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends ConsumerState<AddEventDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _valueController;

  late String _selectedIcon;
  late String _selectedColor;
  late TallyType _selectedType;
  String? _selectedPersonId;
  final Set<String> _selectedBudgetIds = {};
  final Set<String> _additionalPersonIds = {};

  bool get isEditing => widget.existingEvent != null;

  final Map<String, String> _colorNames = {
    '#FF3B30': 'Red',
    '#FF9500': 'Orange',
    '#FFCC00': 'Yellow',
    '#4CD964': 'Green',
    '#5AC8FA': 'Teal Blue',
    '#007AFF': 'Blue',
    '#5856D6': 'Purple',
    '#FF2D55': 'Pink',
  };

  final Map<String, IconData> _icons = {
    'star': Icons.star,
    'favorite': Icons.favorite,
    'thumb_up': Icons.thumb_up,
    'water_drop': Icons.water_drop,
    'coffee': Icons.coffee,
    'fitness': Icons.fitness_center,
    'book': Icons.book,
    'work': Icons.work,
    'check': Icons.check_circle,
    'close': Icons.cancel,
  };

  @override
  void initState() {
    super.initState();
    final existing = widget.existingEvent;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _valueController = TextEditingController(
      text: existing != null && existing.value != 1.0
          ? existing.value.toStringAsFixed(0)
          : '',
    );
    _selectedIcon = existing?.icon ?? 'star';
    _selectedColor = existing?.color ?? '#007AFF';
    _selectedType = existing?.type ?? TallyType.standard;
    _selectedPersonId = existing?.personId;
    if (existing != null) {
      _selectedBudgetIds.addAll(existing.assignedBudgetIds);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  bool get _isPartnerType => _selectedType != TallyType.standard;

  @override
  Widget build(BuildContext context) {
    final peopleAsync = ref.watch(peopleProvider);
    final people = peopleAsync.valueOrNull ?? [];

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 8, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Edit Tally' : 'New Tally',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // Name Input
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Name',
                            hintText: 'e.g., Drank Water',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          maxLength: 100,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Type Selection
                        Text(
                          'Type',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildTypeCard(
                              context,
                              'Standard',
                              Icons.tag,
                              TallyType.standard,
                              Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            _buildTypeCard(
                              context,
                              'Partner +',
                              Icons.arrow_upward,
                              TallyType.partnerPositive,
                              Colors.green,
                            ),
                            const SizedBox(width: 8),
                            _buildTypeCard(
                              context,
                              'Partner -',
                              Icons.arrow_downward,
                              TallyType.partnerNegative,
                              Colors.red,
                            ),
                          ],
                        ),

                        // Value input for partner types
                        if (_isPartnerType) ...[
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _valueController,
                            decoration: InputDecoration(
                              labelText: 'Dollar Value',
                              hintText: 'e.g., 10',
                              prefixText: '\$ ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            validator: (value) {
                              if (!_isPartnerType) return null;
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a value';
                              }
                              final parsed = double.tryParse(value.trim());
                              if (parsed == null || parsed <= 0) {
                                return 'Please enter a positive value';
                              }
                              return null;
                            },
                          ),

                          // Person picker
                          if (people.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            Text(
                              'Person',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: people.map((person) {
                                final isSelected =
                                    _selectedPersonId == person.id;
                                return ChoiceChip(
                                  label: Text(person.name),
                                  selected: isSelected,
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedPersonId = person.id;
                                      _selectedBudgetIds.clear();
                                    });
                                  },
                                );
                              }).toList(),
                            ),

                            // Budget multi-select
                            if (_selectedPersonId != null) ...[
                              const SizedBox(height: 16),
                              _BudgetSelector(
                                personId: _selectedPersonId!,
                                selectedBudgetIds: _selectedBudgetIds,
                                onChanged: (budgetId, selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedBudgetIds.add(budgetId);
                                    } else {
                                      _selectedBudgetIds.remove(budgetId);
                                    }
                                  });
                                },
                              ),

                              // "Also create for other people" — only when creating, not editing
                              if (!isEditing &&
                                  people.length > 1 &&
                                  _selectedPersonId != null) ...[
                                const SizedBox(height: 20),
                                Text(
                                  'Also create for other people',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                ...people
                                    .where((p) => p.id != _selectedPersonId)
                                    .map((person) {
                                  final isChecked =
                                      _additionalPersonIds.contains(person.id);
                                  return CheckboxListTile(
                                    value: isChecked,
                                    onChanged: (checked) {
                                      setState(() {
                                        if (checked == true) {
                                          _additionalPersonIds.add(person.id);
                                        } else {
                                          _additionalPersonIds
                                              .remove(person.id);
                                        }
                                      });
                                    },
                                    title: Text(person.name),
                                    subtitle: Text(person.label),
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                  );
                                }),
                              ],
                            ],
                          ],
                        ],
                        const SizedBox(height: 20),

                        // Color Picker
                        Text(
                          'Color',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _colorNames.entries.map((entry) {
                            final colorHex = entry.key;
                            final colorName = entry.value;
                            final isSelected = _selectedColor == colorHex;
                            final color = parseHexColor(colorHex,
                                Theme.of(context).colorScheme.primary);
                            return Semantics(
                              label:
                                  '$colorName color${isSelected ? ', selected' : ''}',
                              button: true,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedColor = colorHex),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: isSelected
                                        ? Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                            width: 3)
                                        : null,
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color:
                                                  color.withValues(alpha: 0.4),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check,
                                          color: Colors.white, size: 22)
                                      : null,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),

                        // Icon Picker
                        Text(
                          'Icon',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _icons.entries.map((entry) {
                            final isSelected = _selectedIcon == entry.key;
                            final color = parseHexColor(_selectedColor,
                                Theme.of(context).colorScheme.primary);
                            return Semantics(
                              label:
                                  '${entry.key} icon${isSelected ? ', selected' : ''}',
                              button: true,
                              child: GestureDetector(
                                excludeFromSemantics: true,
                                onTap: () =>
                                    setState(() => _selectedIcon = entry.key),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? color.withValues(alpha: 0.15)
                                        : Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                    border: isSelected
                                        ? Border.all(color: color, width: 2)
                                        : Border.all(color: Colors.transparent),
                                  ),
                                  child: Icon(
                                    entry.value,
                                    color: isSelected
                                        ? color
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                    size: 28,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),

              // CTA pinned at bottom
              Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  12,
                  24,
                  12 + MediaQuery.of(context).padding.bottom,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _handleSave,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      isEditing ? 'Save Changes' : 'Create Tally',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTypeCard(
    BuildContext context,
    String label,
    IconData icon,
    TallyType type,
    Color accentColor,
  ) {
    final isSelected = _selectedType == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipColor = isDark ? accentColor.withValues(alpha: 0.7) : accentColor;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedType = type;
          if (type == TallyType.standard) {
            _selectedPersonId = null;
            _selectedBudgetIds.clear();
          }
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? chipColor.withValues(alpha: 0.1)
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? chipColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: isSelected
                      ? chipColor
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isSelected
                          ? chipColor
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final double value;
    if (_isPartnerType && _valueController.text.trim().isNotEmpty) {
      value = double.tryParse(_valueController.text.trim()) ?? 1.0;
    } else {
      value = 1.0;
    }

    final navigator = Navigator.of(context);
    await widget.onSave(
      InputSanitizer.sanitizeName(_nameController.text.trim()),
      _selectedIcon,
      _selectedColor,
      _selectedType,
      value,
      personId: _selectedPersonId,
      assignedBudgetIds: _selectedBudgetIds.toList(),
      additionalPersonIds: _additionalPersonIds.toList(),
    );
    if (mounted) {
      navigator.pop();
    }
  }
}

class _BudgetSelector extends ConsumerWidget {
  final String personId;
  final Set<String> selectedBudgetIds;
  final Function(String budgetId, bool selected) onChanged;

  const _BudgetSelector({
    required this.personId,
    required this.selectedBudgetIds,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsForPersonProvider(personId));

    return budgetsAsync.when(
      data: (budgets) {
        if (budgets.isEmpty) {
          return Text(
            'No budgets for this person',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Budgets',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            ...budgets.map((budget) {
              final isSelected = selectedBudgetIds.contains(budget.id);
              return CheckboxListTile(
                value: isSelected,
                onChanged: (checked) => onChanged(budget.id, checked ?? false),
                title: Text(budget.name),
                subtitle:
                    Text('Limit: \$${budget.budgetLimit.toStringAsFixed(2)}'),
                dense: true,
                contentPadding: EdgeInsets.zero,
              );
            }),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 32,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const Text('Error loading budgets'),
    );
  }
}
