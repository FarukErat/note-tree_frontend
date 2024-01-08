import 'dart:io';

import 'package:note_tree/models/note_model.dart';

late String localPath;

List<Note> globalNotes = NoteListLoadFromFile.loadFromFile();
final String notesPath = "$localPath/notes.json";

String? sessionId = getSessionIdFromFile();
final String sessionIdPath = "$localPath/sessionId.txt";

String? getSessionIdFromFile() {
  final file = File(sessionIdPath);
  String? sessionId;
  if (file.existsSync()) {
    sessionId = file.readAsStringSync();
  }
  return sessionId;
}
