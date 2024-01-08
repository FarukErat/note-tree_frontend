import 'package:flutter/material.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:note_tree/globals.dart';
import 'package:note_tree/models/note_model.dart';
import 'package:note_tree/pages/auth.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';

MaterialApp notesPage(List<Note> notes) => MaterialApp(
      home: Scaffold(
        body: MyTreeView(notes: notes, path: 'Root'),
      ),
      debugShowCheckedModeBanner: false,
    );

class MyTreeView extends StatefulWidget {
  final List<Note> notes;
  final String path;

  const MyTreeView({
    super.key,
    required this.notes,
    required this.path,
  });

  @override
  State<MyTreeView> createState() => _MyTreeViewState();
}

class _MyTreeViewState extends State<MyTreeView> {
  late TreeController<Note> treeController;

  @override
  void initState() {
    super.initState();
    treeController = TreeController<Note>(
      roots: widget.notes,
      childrenProvider: (Note node) => node.children,
    );
  }

  @override
  void dispose() {
    treeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.path),
        backgroundColor: Colors.brown[200],
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const AuthPage()));
            },
            child: const Icon(Icons.account_box),
          ),
        ],
      ),
      floatingActionButton: Row(
        textDirection: TextDirection.rtl,
        children: [
          FloatingActionButton(
            onPressed: () => treeController.expandAll(),
            heroTag: const Uuid().v4(),
            child: const Icon(Icons.expand),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            onPressed: () => treeController.collapseAll(),
            heroTag: const Uuid().v4(),
            child: const Icon(Icons.compress),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: globalNotes.toJsonList()),
              ).then((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Notes copied to clipboard as JSON"),
                    duration: Duration(seconds: 1),
                  ),
                );
              });
            },
            heroTag: const Uuid().v4(),
            child: const Icon(Icons.copy),
          ),
        ],
      ),
      backgroundColor: Colors.brown[200],
      body: widget.notes.isNotEmpty
          ? notesWidget()
          : TextButton(
              onPressed: () {
                widget.notes.add(
                  Note(
                    content: '',
                    children: [],
                  ),
                );
                setState(() {});
                globalNotes.saveToFile();
              },
              child: const Icon(Icons.add),
            ),
    );
  }

  TreeView<Note> notesWidget() {
    return TreeView<Note>(
      treeController: treeController,
      nodeBuilder: (BuildContext context, TreeEntry<Note> entry) {
        List<Note> siblings = entry.parent?.node.children ?? widget.notes;
        TextEditingController textEditingController =
            TextEditingController(text: entry.node.content);

        void addSiblingNote(String content) {
          siblings.insert(
            siblings.indexOf(entry.node) + 1,
            Note(
              content: content,
              children: [],
            ),
          );
          treeController.rebuild();
          globalNotes.saveToFile();
        }

        void addChildNote(String content) {
          entry.node.children.insert(
            0,
            Note(
              content: content,
              children: [],
            ),
          );
          treeController.rebuild();
          globalNotes.saveToFile();
        }

        void deleteNote(Note note) {
          if (note.children.isNotEmpty) {
            for (var subNote in note.children) {
              deleteNote(subNote);
            }
          }
          note.children.clear();
          siblings.remove(note);
          treeController.rebuild();
          if (siblings == widget.notes && siblings.isEmpty) {
            setState(() {});
          }
          globalNotes.saveToFile();
        }

        String getPath() {
          const maxPathLength = 10;
          String path = entry.node.content;
          if (path.length > maxPathLength) {
            path = '${path.substring(0, maxPathLength)}...';
          }
          TreeEntry<Note> temp = entry;
          Note? parent = temp.parent?.node;
          while (parent != null) {
            // construct path
            if (parent.content.length > maxPathLength) {
              path = '${parent.content.substring(0, maxPathLength)}.../$path';
            } else {
              path = '${parent.content}/$path';
            }
            // move up
            if (temp.parent != null) {
              temp = temp.parent!;
            }
            parent = temp.parent?.node;
          }
          return path;
        }

        void openChildrenNotes() {
          Navigator.of(context)
              .push(MaterialPageRoute(
                builder: (context) => MyTreeView(
                    notes: entry.node.children,
                    path: '${widget.path}/${getPath()}'),
              ))
              .then((_) => treeController.rebuild());
        }

        return TreeIndentation(
          entry: entry,
          guide: const IndentGuide.connectingLines(
            indent: 40,
            color: Colors.brown,
          ),
          child: Row(
            children: [
              GestureDetector(
                onLongPressStart: (details) async {
                  final offset = details.globalPosition;
                  showMenu(
                    context: context,
                    position: RelativeRect.fromLTRB(
                      offset.dx,
                      offset.dy,
                      MediaQuery.of(context).size.width - offset.dx,
                      MediaQuery.of(context).size.height - offset.dy,
                    ),
                    items: [
                      PopupMenuItem<String>(
                        onTap: () => addSiblingNote(''),
                        child: const Text('Add Sibling'),
                      ),
                      PopupMenuItem<String>(
                        onTap: () {
                          addChildNote('');
                          treeController.expand(entry.node);
                        },
                        child: const Text('Add Child'),
                      ),
                      PopupMenuItem<String>(
                        onTap: () => openChildrenNotes(),
                        child: const Text('Zoom In'),
                      ),
                      PopupMenuItem<String>(
                        onTap: () => deleteNote(entry.node),
                        child: const Text('Delete'),
                      ),
                    ],
                  );
                },
                child: IconButton(
                  onPressed: entry.hasChildren
                      ? () => treeController.toggleExpansion(entry.node)
                      : () {},
                  icon: entry.hasChildren
                      ? Icon(
                          entry.isExpanded
                              ? Icons.arrow_drop_down
                              : Icons.arrow_right,
                        )
                      : const Icon(
                          Icons.circle,
                          size: 12,
                        ),
                ),
              ),
              Expanded(
                child: TextField(
                  maxLines: null,
                  controller: textEditingController,
                  onChanged: (newValue) {
                    entry.node.content = newValue;
                    globalNotes.saveToFile();
                  },
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
