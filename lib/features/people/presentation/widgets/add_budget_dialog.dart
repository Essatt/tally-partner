import 'package:flutter/material.dart';
import '../../../../models/budget.dart';
import '../../../../utils/input_sanitizer.dart';

class AddBudgetDialog extends StatefulWidget {
  final Future<void> Function(String name, double limit) onSave;
  final Budget? existingBudget;

  const AddBudgetDialog({super.key, required this.onSave, this.existingBudget});

  @override
  State<AddBudgetDialog> createState() => _AddBudgetDialogState();
}

class _AddBudgetDialogState extends State<AddBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _limitController;
  bool _isLoading = false;

  bool get isEditing => widget.existingBudget != null;

  final List<String> _quickNames = [
    'General',
    'Birthday',
    'Anniversary',
    'Holiday'
  ];

  @override
  void initState() {
    super.initState();
    final existing = widget.existingBudget;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _limitController = TextEditingController(
      text: existing != null ? existing.budgetLimit.toStringAsFixed(2) : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _limitController.dispose();
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
                Icons.add_card_rounded,
                size: 40,
                color: Theme.of(context).colorScheme.tertiary,
              ),
              const SizedBox(height: 12),
              Text(
                isEditing ? 'Edit Budget' : 'Add Budget',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                isEditing
                    ? 'Update budget name or limit'
                    : 'Create a new budget category',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 20),

              // Quick name picks
              Text(
                'Quick Pick',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickNames.map((name) {
                  return FilledButton.tonal(
                    onPressed: () {
                      _nameController.text = name;
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                    child: Text(name),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Budget Name',
                        hintText: 'e.g., Birthday',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: 50,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a budget name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _limitController,
                      decoration: InputDecoration(
                        labelText: 'Budget Limit',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      maxLength: 10,
                      validator: (value) {
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
                      : Text(
                          isEditing ? 'Save Changes' : 'Create Budget',
                          style: const TextStyle(
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
    final limit = InputSanitizer.sanitizeMonetaryValue(_limitController.text);

    if (limit != null && limit > 0) {
      await widget.onSave(name, limit);
      if (mounted) navigator.pop();
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
