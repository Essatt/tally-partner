import 'package:flutter/material.dart';
import '../../../../utils/input_sanitizer.dart';

class SetupBudgetDialog extends StatefulWidget {
  final Function(double budget, String name) onSave;

  const SetupBudgetDialog({super.key, required this.onSave});

  @override
  State<SetupBudgetDialog> createState() => _SetupBudgetDialogState();
}

class _SetupBudgetDialogState extends State<SetupBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _budgetController = TextEditingController();
  final _nameController = TextEditingController(text: 'Partner');
  bool _isLoading = false;

  @override
  void dispose() {
    _budgetController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Setup Partner Budget'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _budgetController,
              decoration: const InputDecoration(
                labelText: 'Budget Limit',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              maxLength: 10,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a budget amount';
                }
                final sanitized = InputSanitizer.sanitizeMonetaryValue(value);
                if (sanitized == null || sanitized <= 0) {
                  return 'Please enter a valid positive amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Partner Name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              maxLength: 50,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a partner name';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            if (_isLoading) return;
            if (!_formKey.currentState!.validate()) return;

            setState(() => _isLoading = true);

            final navigator = Navigator.of(context);
            final sanitizedBudget = InputSanitizer.sanitizeMonetaryValue(_budgetController.text);
            if (sanitizedBudget != null && sanitizedBudget > 0) {
              await widget.onSave(
                sanitizedBudget,
                InputSanitizer.sanitizeName(_nameController.text.trim()),
              );
              if (mounted) navigator.pop();
            }

            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
          child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary),
                    ),
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
