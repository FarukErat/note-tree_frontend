import 'package:flutter/material.dart';
import 'package:note_tree/globals.dart';
import 'package:note_tree/models/note_model.dart';
import 'package:note_tree/pages/note_trees.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  localPath = (await getApplicationDocumentsDirectory()).path;
  globalNotes = NoteListLoadFromFile.loadFromFile();
  sessionId = getSessionIdFromFile();
  runApp(notesPage(globalNotes));
}
