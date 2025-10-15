import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'note_page.dart';

class HomePage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const HomePage({super.key, required this.isDarkMode, required this.onToggleTheme});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Box notesBox = Hive.box('notesBox');
  String searchQuery = '';

  String formatTimestamp(int? millis) {
    if (millis == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(millis);
    return DateFormat('MMM d, h:mm a').format(dt);
  }

  // Build a sorted & filtered list of notes (maps) from the box
  List<Map> getNotesList() {
    final raw = notesBox.values.cast<dynamic>().toList();
    // Convert each item to Map
    final maps = raw.map((e) {
      try {
        return Map<String, dynamic>.from(e as Map);
      } catch (_) {
        return <String, dynamic>{};
      }
    }).toList();

    // Filter by search query
    final filtered = maps.where((m) {
      final t = (m['title'] ?? '').toString().toLowerCase();
      final c = (m['content'] ?? '').toString().toLowerCase();
      final q = searchQuery.toLowerCase();
      return q.isEmpty || t.contains(q) || c.contains(q);
    }).toList();

    // Sort: pinned first, then by lastEdited desc
    filtered.sort((a, b) {
      final ap = (a['pinned'] == true) ? 0 : 1;
      final bp = (b['pinned'] == true) ? 0 : 1;
      if (ap != bp) return ap.compareTo(bp);
      final at = (a['lastEdited'] ?? 0) as int;
      final bt = (b['lastEdited'] ?? 0) as int;
      return bt.compareTo(at);
    });

    return filtered;
  }

  Future<void> _clearAll() async {
    if (notesBox.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Clear all notes?'),
        content: const Text('This will delete all saved notes.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Yes')),
        ],
      ),
    );
    if (confirm == true) {
      await notesBox.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600);
    final contentStyle = GoogleFonts.poppins(fontSize: 14);
    final tsStyle = GoogleFonts.poppins(fontSize: 12, color: Theme.of(context).hintColor);

    return Scaffold(
      appBar: AppBar(
        title: const Text('📝 My Notes'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: widget.isDarkMode ? 'Light mode' : 'Dark mode',
            icon: Icon(widget.isDarkMode ? Icons.dark_mode : Icons.light_mode),
            onPressed: widget.onToggleTheme,
          ),
          IconButton(
            tooltip: 'Clear all notes',
            icon: const Icon(Icons.delete_sweep),
            onPressed: _clearAll,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              onChanged: (v) => setState(() => searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search notes...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.light
                    ? Colors.grey[100]
                    : Colors.grey[800],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: notesBox.listenable(),
        builder: (context, Box box, _) {
          final list = getNotesList();
          if (list.isEmpty) {
            return Center(
              child: Text(
                'No notes yet!\nTap + to add one.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final note = list[index];
              final title = (note['title'] ?? '').toString();
              final content = (note['content'] ?? '').toString();
              final int ts = (note['lastEdited'] ?? 0) as int;
              final int colorValue = (note['color'] ?? Colors.white.value) as int;
              final pinned = (note['pinned'] == true);

              // To enable delete by index in box we must find actual index in box
              final actualIndex = notesBox.values.toList().indexWhere((e) {
                final m = Map<String, dynamic>.from(e as Map);
                // compare by lastEdited + title to find unique item (ok for this simple app)
                return (m['lastEdited'] == note['lastEdited'] && (m['title'] ?? '') == note['title']);
              });

              return Dismissible(
                key: Key('note_index_${note['lastEdited'] ?? index}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) {
                  // store for undo
                  final removed = notesBox.getAt(actualIndex);
                  final removedIndex = actualIndex;
                  notesBox.deleteAt(actualIndex);
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Note deleted'),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () {
                          if (removed != null) {
                            notesBox.putAt(removedIndex, removed);
                          }
                        },
                      ),
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: Container(
                      width: 10,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Color(colorValue),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(child: Text(title.isEmpty ? '(No title)' : title, style: titleStyle)),
                        if (pinned) const Icon(Icons.push_pin, size: 18, color: Colors.amber),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(content, maxLines: 3, overflow: TextOverflow.ellipsis, style: contentStyle),
                        const SizedBox(height: 8),
                        Text('Edited: ${formatTimestamp(ts)}', style: tsStyle),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NotePage(
                                  isEditing: true,
                                  initialTitle: title,
                                  initialContent: content,
                                  initialColor: Color(colorValue),
                                  initialPinned: pinned,
                                  onSave: (t, c, color, pin) {
                                    final map = {
                                      'title': t,
                                      'content': c,
                                      'lastEdited': DateTime.now().millisecondsSinceEpoch,
                                      'color': color.value,
                                      'pinned': pin,
                                    };
                                    // update actual index
                                    if (actualIndex >= 0) {
                                      notesBox.putAt(actualIndex, map);
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            if (actualIndex >= 0) {
                              final removed = notesBox.getAt(actualIndex);
                              final removedIndex = actualIndex;
                              notesBox.deleteAt(actualIndex);
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Note deleted'),
                                  action: SnackBarAction(
                                    label: 'Undo',
                                    onPressed: () {
                                      if (removed != null) {
                                        notesBox.putAt(removedIndex, removed);
                                      }
                                    },
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add note',
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NotePage(
                isEditing: false,
                onSave: (t, c, color, pin) {
                  final map = {
                    'title': t,
                    'content': c,
                    'lastEdited': DateTime.now().millisecondsSinceEpoch,
                    'color': color.value,
                    'pinned': pin,
                  };
                  notesBox.add(map);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
