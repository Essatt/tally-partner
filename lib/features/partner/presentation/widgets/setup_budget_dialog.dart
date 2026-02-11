import 'package:flutter/material.dart';
import '../../../../utils/input_sanitizer.dart';

class SetupBudgetDialog extends StatefulWidget {
  final Function(double budget, String name) onSave;

  const SetupBudgetDialog({super.key, required this.onSave});

  @override
  State<SetupBudgetDialog> createState() => _SetupBudgetDialogState();
}

class _SetupBudgetDialogState extends State<SetupBudgetDialog> {
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
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _budgetController,
            decoration: const InputDecoration(
              labelText: 'Budget Limit',
              prefixText: '\$',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            maxLength: 10,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Partner Name',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
            maxLength: 50,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            if (_isLoading) return;
            
            setState(() => _isLoading = true);
            
            final sanitizedBudget = InputSanitizer.sanitizeMonetaryValue(_budgetController.text);
            if (sanitizedBudget != null && sanitizedBudget > 0) {
              await widget.onSave(
                sanitizedBudget,
                InputSanitizer.sanitizeName(_nameController.text.trim()),
              );
              if (mounted) Navigator.of(context).pop();
            }
            
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
