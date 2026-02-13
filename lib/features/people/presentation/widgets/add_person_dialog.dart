import 'package:flutter/material.dart';
import '../../../../utils/input_sanitizer.dart';

class AddPersonDialog extends StatefulWidget {
  final Future<void> Function(
          String name, String label, String? budgetName, double? budgetLimit)
      onSave;

  const AddPersonDialog({super.key, required this.onSave});

  @override
  State<AddPersonDialog> createState() => _AddPersonDialogState();
}

class _AddPersonDialogState extends State<AddPersonDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _budgetNameController = TextEditingController();
  final _budgetLimitController = TextEditingController();
  String _selectedLabel = 'partner';
  bool _addBudget = true;
  bool _isLoading = false;

  final List<String> _labels = ['partner', 'friend', 'colleague', 'family'];

  @override
  void dispose() {
    _nameController.dispose();
    _budgetNameController.dispose();
    _budgetLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Icon(
                Icons.person_add_rounded,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                'Add a Person',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Track budgets and actions for someone',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        hintText: 'e.g., Alex',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      textCapitalization: TextCapitalization.words,
                      maxLength: 50,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Label picker
                    Text(
                      'Relationship',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _labels.map((label) {
                        final isSelected = _selectedLabel == label;
                        return ChoiceChip(
                          label:
                              Text(label[0].toUpperCase() + label.substring(1)),
                          selected: isSelected,
                          onSelected: (_) =>
                              setState(() => _selectedLabel = label),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Optional first budget
                    Row(
                      children: [
                        Checkbox(
                          value: _addBudget,
                          onChanged: (v) =>
                              setState(() => _addBudget = v ?? false),
                        ),
                        Expanded(
                          child: Text(
                            'Create a budget right away',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),

                    if (_addBudget) ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _budgetNameController,
                        decoration: InputDecoration(
                          labelText: 'Budget Name',
                          hintText: 'e.g., General',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        maxLength: 50,
                        validator: (value) {
                          if (!_addBudget) return null;
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a budget name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _budgetLimitController,
                        decoration: InputDecoration(
                          labelText: 'Budget Limit',
                          prefixText: '\$ ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        maxLength: 10,
                        validator: (value) {
                          if (!_addBudget) return null;
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a budget limit';
                          }
                          final sanitized =
                              InputSanitizer.sanitizeMonetaryValue(value);
                          if (sanitized == null || sanitized <= 0) {
                            return 'Please enter a valid positive amount';
                          }
                          return null;
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
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
                          'Add Person',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              SizedBox(height: 12 + MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final navigator = Navigator.of(context);
    final name = InputSanitizer.sanitizeName(_nameController.text.trim());

    String? budgetName;
    double? budgetLimit;
    if (_addBudget) {
      budgetName =
          InputSanitizer.sanitizeName(_budgetNameController.text.trim());
      budgetLimit =
          InputSanitizer.sanitizeMonetaryValue(_budgetLimitController.text);
    }

    await widget.onSave(name, _selectedLabel, budgetName, budgetLimit);

    if (mounted) {
      navigator.pop();
    }
  }
}
