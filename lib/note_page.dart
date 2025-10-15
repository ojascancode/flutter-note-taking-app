import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';

typedef SaveCallback = void Function(String title, String content, Color color, bool pinned);

class NotePage extends StatefulWidget {
  final SaveCallback onSave;
  final bool isEditing;
  final String? initialTitle;
  final String? initialContent;
  final Color? initialColor;
  final bool? initialPinned;

  const NotePage({
    super.key,
    required this.onSave,
    this.isEditing = false,
    this.initialTitle,
    this.initialContent,
    this.initialColor,
    this.initialPinned,
  });

  @override
  State<NotePage> createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  late final TextEditingController titleController;
  late final TextEditingController contentController;
  late Color pickedColor;
  bool isPinned = false;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.initialTitle ?? '');
    contentController = TextEditingController(text: widget.initialContent ?? '');
    pickedColor = widget.initialColor ?? Colors.white;
    isPinned = widget.initialPinned ?? false;
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  void saveNote() {
    final t = titleController.text.trim();
    final c = contentController.text.trim();
    if (t.isEmpty && c.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note cannot be empty')));
      return;
    }
    widget.onSave(t, c, pickedColor, isPinned);
    Navigator.pop(context);
  }

  void openColorPicker() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Pick a color for the note'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickedColor,
            onColorChanged: (col) => setState(() => pickedColor = col),
            showLabel: false,
            pickerAreaHeightPercent: 0.7,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Done')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.isEditing;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Note' : 'Add Note')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: contentController,
                decoration: InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: openColorPicker,
                  icon: const Icon(Icons.color_lens),
                  label: const Text('Color'),
                ),
                const SizedBox(width: 12),
                Row(
                  children: [
                    const Text('Pin'),
                    Switch(
                      value: isPinned,
                      onChanged: (v) => setState(() => isPinned = v),
                    )
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: saveNote,
                  icon: const Icon(Icons.save),
                  label: Text(isEditing ? 'Save' : 'Add', style: GoogleFonts.poppins()),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
