import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:note_tree/globals.dart';

class Note {
  String content;
  List<Note> children;

  Note({
    required this.content,
    required this.children,
  });

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      content: map['content'],
      children: (map['children'] as List).map((i) => Note.fromMap(i)).toList(),
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'children': children.map((x) => x.toMap()).toList(),
    };
  }

  String toJson() => json.encode(toMap());
  factory Note.fromJson(String source) => Note.fromMap(json.decode(source));
}

extension NoteListFromJson on List<Note> {
  static List<Note> fromJsonList(String source) {
    List<dynamic> json = jsonDecode(source);
    return json.map((e) => Note.fromMap(e)).toList();
  }
}

extension NoteListToJson on List<Note> {
  String toJsonList() {
    return jsonEncode(map((e) => e.toMap()).toList());
  }
}

extension NoteListSaveToFile on List<Note> {
  void saveToFile({String? fileName}) {
    fileName ??= notesPath;
    try {
      final file = File(fileName);
      file.writeAsStringSync(toJsonList());
    } catch (e) {
      log('Error saving to file: $e');
    }
  }
}

extension NoteListLoadFromFile on List<Note> {
  static List<Note> loadFromFile({String? fileName}) {
    fileName ??= notesPath;
    try {
      final file = File(fileName);
      return NoteListFromJson.fromJsonList(file.readAsStringSync());
    } catch (e) {
      log('Error loading from file: $e');
      return [];
    }
  }
}
