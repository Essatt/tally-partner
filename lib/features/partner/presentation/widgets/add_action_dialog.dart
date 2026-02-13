import 'package:flutter/material.dart';
import '../../../../models/budget.dart';
import '../../../../utils/input_sanitizer.dart';

class AddActionDialog extends StatefulWidget {
  /// New callback that includes budget selection
  final Future<void> Function(
          String name, double value, String type, List<String> budgetIds)?
      onSaveWithBudgets;

  /// Pre-scoped person ID (skips person picker)
  final String? personId;

  /// Available budgets for the selected person
  final List<Budget> budgets;

  const AddActionDialog({
    super.key,
    this.onSaveWithBudgets,
    this.personId,
    this.budgets = const [],
  });

  @override
  State<AddActionDialog> createState() => _AddActionDialogState();
}

class _AddActionDialogState extends State<AddActionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();
  String _selectedType = 'positive';
  final Set<String> _selectedBudgetIds = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-select all budgets if there's only one
    if (widget.budgets.length == 1) {
      _selectedBudgetIds.add(widget.budgets.first.id);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.9,
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
                      'Log Budget Action',
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

                        // Action Name
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Action Name',
                            hintText: 'e.g., Helped with dishes',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          maxLength: 100,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter an action name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Value Input
                        TextFormField(
                          controller: _valueController,
                          decoration: InputDecoration(
                            labelText: 'Value (\$)',
                            hintText: 'e.g., 10.00',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixText: '\$ ',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a value';
                            }
                            final sanitizedValue =
                                InputSanitizer.sanitizeMonetaryValue(value);
                            if (sanitizedValue == null || sanitizedValue <= 0) {
                              return 'Please enter a positive value (max \$10,000)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Action Type
                        Text(
                          'Action Type',
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
                              'Positive',
                              'Adds to balance',
                              Icons.arrow_upward,
                              'positive',
                              Theme.of(context).colorScheme.tertiary,
                            ),
                            const SizedBox(width: 12),
                            _buildTypeCard(
                              context,
                              'Negative',
                              'Subtracts from balance',
                              Icons.arrow_downward,
                              'negative',
                              Theme.of(context).colorScheme.error,
                            ),
                          ],
                        ),

                        // Budget selection
                        if (widget.budgets.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Text(
                            'Apply to Budgets',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 8),
                          ...widget.budgets.map((budget) {
                            final isSelected =
                                _selectedBudgetIds.contains(budget.id);
                            return CheckboxListTile(
                              value: isSelected,
                              onChanged: (checked) {
                                setState(() {
                                  if (checked == true) {
                                    _selectedBudgetIds.add(budget.id);
                                  } else {
                                    _selectedBudgetIds.remove(budget.id);
                                  }
                                });
                              },
                              title: Text(budget.name),
                              subtitle: Text(
                                'Balance: \$${budget.currentBalance.toStringAsFixed(2)} / \$${budget.budgetLimit.toStringAsFixed(2)}',
                              ),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            );
                          }),
                        ],

                        // Quick Value Buttons
                        const SizedBox(height: 20),
                        Text(
                          'Quick Values',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [5, 10, 20, 50, 100].map((value) {
                            return FilledButton.tonal(
                              onPressed: () {
                                _valueController.text = value.toString();
                              },
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                              ),
                              child: Text('\$$value'),
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
                    onPressed: _isLoading ? null : _handleSave,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Log Action',
                            style: TextStyle(
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
    String title,
    String subtitle,
    IconData icon,
    String type,
    Color accentColor,
  ) {
    final isSelected = _selectedType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withValues(alpha: 0.1)
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? accentColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: isSelected
                      ? accentColor
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 28),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: isSelected
                          ? accentColor
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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

    setState(() => _isLoading = true);

    final sanitizedValue =
        InputSanitizer.sanitizeMonetaryValue(_valueController.text);
    if (sanitizedValue == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final navigator = Navigator.of(context);
    final sign = _selectedType == 'positive' ? 1 : -1;

    if (widget.onSaveWithBudgets != null) {
      await widget.onSaveWithBudgets!(
        InputSanitizer.sanitizeName(_nameController.text.trim()),
        sign * sanitizedValue,
        _selectedType,
        _selectedBudgetIds.toList(),
      );
    }

    if (mounted) {
      navigator.pop();
    }
  }
}
