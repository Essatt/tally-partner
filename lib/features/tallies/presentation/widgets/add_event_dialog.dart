import 'package:flutter/material.dart';
import '../../../../models/tally_event.dart';
import '../../../../utils/input_sanitizer.dart';
import '../../../../utils/color_extensions.dart';

class AddEventDialog extends StatefulWidget {
  final Function(String name, String icon, String color, TallyType type) onSave;

  const AddEventDialog({super.key, required this.onSave});

  @override
  State<AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<AddEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  // Default values
  String _selectedIcon = 'star';
  String _selectedColor = '#007AFF'; // Blue
  TallyType _selectedType = TallyType.standard;

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
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Tally Event'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name Input
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Event Name',
                  hintText: 'e.g., Drank Water',
                  border: OutlineInputBorder(),
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
              const SizedBox(height: 24),

              // Type Dropdown
              const Text('Type', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<TallyType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(
                    value: TallyType.standard,
                    child: Text('Standard Counter'),
                  ),
                  DropdownMenuItem(
                    value: TallyType.partnerPositive,
                    child: Text('Partner Budget (+)'),
                  ),
                  DropdownMenuItem(
                    value: TallyType.partnerNegative,
                    child: Text('Partner Budget (-)'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _selectedType = value);
                },
              ),
              const SizedBox(height: 24),

              // Color Picker
              const Text('Color', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _colorNames.entries.map((entry) {
                  final colorHex = entry.key;
                  final colorName = entry.value;
                  final isSelected = _selectedColor == colorHex;
                  final color = parseHexColor(colorHex, Theme.of(context).colorScheme.primary);
                  return Semantics(
                    label: '$colorName color${isSelected ? ', selected' : ''}',
                    button: true,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedColor = colorHex),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3)
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha:0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 24)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Icon Picker
              const Text('Icon', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _icons.entries.map((entry) {
                  final isSelected = _selectedIcon == entry.key;
                  final color = parseHexColor(_selectedColor, Theme.of(context).colorScheme.primary);
                  return Semantics(
                    label: '${entry.key} icon${isSelected ? ', selected' : ''}',
                    button: true,
                    child: GestureDetector(
                      excludeFromSemantics: true,
                      onTap: () => setState(() => _selectedIcon = entry.key),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected ? color.withValues(alpha:0.2) : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(color: color, width: 2)
                              : Border.all(color: Colors.transparent),
                        ),
                        child: Icon(
                          entry.value,
                          color: isSelected ? color : Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 28,
                        ),
                      ),
                    ),
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
            if (_formKey.currentState!.validate()) {
              final navigator = Navigator.of(context);
              await widget.onSave(
                InputSanitizer.sanitizeName(_nameController.text.trim()),
                _selectedIcon,
                _selectedColor,
                _selectedType,
              );
              if (mounted) {
                navigator.pop();
              }
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
