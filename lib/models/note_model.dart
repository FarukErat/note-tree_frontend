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
    String? content;
    List<Note>? children;
    if (map.containsKey('content') && map['content'] is String) {
      content = map['content'];
    }
    if (map.containsKey('children') && map['children'] is List) {
      children = (map['children'] as List).map((i) => Note.fromMap(i)).toList();
    }
    return Note(
      content: content ?? '',
      children: children ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'children': children.map((x) => x.toMap()).toList(),
    };
  }

  factory Note.fromJson(String source) {
    final Map<String, dynamic> map = json.decode(source);
    if (!isMapValidNote(map)) {
      return Note(
        content: '',
        children: [],
      );
    }
    return Note.fromMap(map);
  }

  String toJson() => json.encode(toMap());
}

bool isMapValidNote(Map<String, dynamic> map) {
  // Check if map contains all required keys
  if(!map.containsKey('content') || !map.containsKey('children')) {
    return false;
  }
  // Check if map values are of correct type
  if ((map['content'] is! String) || (map['children'] is! List)) {
    return false;
  }
  // Check if children are valid recursively
  if ((map['children'] as List).isNotEmpty) {
    if (!(map['children'] as List).every((e) => isMapValidNote(e))) {
      return false;
    }
  }
  return true;
}

extension NoteListFromJson on List<Note> {
  static List<Note> fromJson(String source) {
    List<dynamic> json = jsonDecode(source);
    return json.map((e) => Note.fromMap(e)).toList();
  }
}

extension NoteListToJson on List<Note> {
  String toJson() {
    return jsonEncode(map((e) => e.toMap()).toList());
  }
}

extension NoteListSaveToFile on List<Note> {
  void saveToFile({String? fileName}) {
    fileName ??= notesPath;
    try {
      final file = File(fileName);
      file.writeAsStringSync(toJson());
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
      return NoteListFromJson.fromJson(file.readAsStringSync());
    } catch (e) {
      log('Error loading from file: $e');
      return [];
    }
  }
}
