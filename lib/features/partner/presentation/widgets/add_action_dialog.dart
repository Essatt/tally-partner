import 'package:flutter/material.dart';
import '../../../../utils/input_sanitizer.dart';

class AddActionDialog extends StatefulWidget {
  final Function(String name, double value, String type) onSave;

  const AddActionDialog({super.key, required this.onSave});

  @override
  State<AddActionDialog> createState() => _AddActionDialogState();
}

class _AddActionDialogState extends State<AddActionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();
  String _selectedType = 'positive';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Log Budget Action'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Action Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Action Name',
                  hintText: 'e.g., Helped with dishes',
                  border: OutlineInputBorder(),
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
                decoration: const InputDecoration(
                  labelText: 'Value (\$)',
                  hintText: 'e.g., 10.00',
                  border: OutlineInputBorder(),
                  prefixText: '\$',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a value';
                  }
                  final sanitizedValue = InputSanitizer.sanitizeMonetaryValue(value);
                  if (sanitizedValue == null || sanitizedValue <= 0) {
                    return 'Please enter a positive value (max \$10,000)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Action Type
              const Text('Action Type', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Positive'),
                      subtitle: const Text('Adds to balance'),
                      value: 'positive',
                      groupValue: _selectedType,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedType = value);
                        }
                      },
                      activeColor: Colors.green,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Negative'),
                      subtitle: const Text('Subtracts from balance'),
                      value: 'negative',
                      groupValue: _selectedType,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedType = value);
                        }
                      },
                      activeColor: Colors.red,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),

              // Quick Value Buttons
              const SizedBox(height: 16),
              const Text('Quick Values', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [5, 10, 20, 50, 100].map((value) {
                  return OutlinedButton(
                    onPressed: () {
                      _valueController.text = value.toString();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      side: BorderSide(color: Theme.of(context).colorScheme.primary),
                    ),
                    child: Text('\$$value'),
                  );
                }).toList(),
              ),
            ],
          ),
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
            
            final sanitizedValue = InputSanitizer.sanitizeMonetaryValue(_valueController.text);
            if (sanitizedValue == null) {
              setState(() => _isLoading = false);
              return;
            }
            
            final value = sanitizedValue;
            final sign = _selectedType == 'positive' ? 1 : -1;
            await widget.onSave(
              InputSanitizer.sanitizeName(_nameController.text.trim()),
              sign * value,
              _selectedType,
            );
            
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
                : const Text('Log Action'),
          ),
      ],
    );
  }
}
