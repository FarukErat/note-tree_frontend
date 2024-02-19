import 'dart:developer';
import 'dart:io';

import 'package:note_tree/models/note_model.dart';

late String localPath;
final String notesPath = "$localPath/notes.json";
final String sessionIdPath = "$localPath/sessionId.txt";

List<Note> globalNotes = [];
String? sessionId;

String? getSessionIdFromFile() {
  final file = File(sessionIdPath);
  String? sessionId;
  if (file.existsSync()) {
    try {
      sessionId = file.readAsStringSync();
    } on FileSystemException catch (e) {
      log("Error reading session id from file: $e");
    }
  }
  return sessionId;
}

void saveSessionIdToFile(String sessionId) {
  final file = File(sessionIdPath);
  try {
    file.writeAsStringSync(sessionId);
  } catch (e) {
    log('Failed to write session ID: $e');
  }
}
