import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:note_tree/models/note_model.dart';

const String host = "10.0.2.2";
const String apiUrl = "http://$host:8085/api";

/// 200: session is valid
///
/// 401: session is NOT valid
Future<int> isSessionIdValid(String? sessionId) async {
  if (sessionId == null) {
    return 401;
  }
  final Uri uri = Uri.parse("$apiUrl/authentication/secret");
  final Map<String, String> headers = {
    'Cookie': 'SID=$sessionId',
  };
  var response = await http.get(
    uri,
    headers: headers,
  );
  return response.statusCode;
}

/// 200: successful
///
/// 400: bad credentials
///
/// 409: username is already taken
Future<(int, String?, String?)> register(
    String username, String password) async {
  final Uri uri = Uri.parse("$apiUrl/authentication/signup");

  final Map<String, String> headers = {
    'Content-Type': 'application/json',
  };

  final Map<String, String> body = {
    'username': username,
    'password': password,
  };

  final String jsonBody = json.encode(body);

  var response = await http.post(
    uri,
    headers: headers,
    body: jsonBody,
  );

  String? sessionId =
      response.headers['set-cookie']?.split(";")[0].substring('SID='.length);

  return (
    response.statusCode,
    sessionId,
    json.decode(response.body)["title"] as String?
  );
}

/// 200: successful
///
/// 400: bad credentials
///
/// 401: incorrect password
///
/// 404: username not found
Future<(int, String?, String?)> login(String username, String password) async {
  final Uri uri = Uri.parse("$apiUrl/authentication/login");

  final Map<String, String> headers = {
    'Content-Type': 'application/json',
  };

  final Map<String, String> body = {
    'username': username,
    'password': password,
  };

  final String jsonBody = json.encode(body);

  var response = await http.post(
    uri,
    headers: headers,
    body: jsonBody,
  );

  String? sessionId =
      response.headers['set-cookie']?.split(";")[0].substring('SID='.length);

  return (
    response.statusCode,
    sessionId,
    json.decode(response.body)["title"] as String?
  );
}

/// 200: success
///
/// 401: session id is NOT valid
Future<int> logout(String? sessionId) async {
  if (sessionId == null) {
    return 401;
  }

  final Uri uri = Uri.parse("$apiUrl/authentication/logout");

  final Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Cookie': 'SID=$sessionId',
  };

  var response = await http.get(
    uri,
    headers: headers,
  );

  return response.statusCode;
}

/// 200: success
///
/// 401: session id is NOT valid
Future<(int, List<Note>)> getNotesFromDb(String? sessionId) async {
  if (sessionId == null) {
    return (401, <Note>[]);
  }

  final Uri uri = Uri.parse("$apiUrl/note/get-notes");

  final Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Cookie': 'SID=$sessionId',
  };

  var response = await http.get(
    uri,
    headers: headers,
  );

  if (response.statusCode == 200) {
    return (response.statusCode, NoteListFromJson.fromJson(response.body));
  } else {
    return (response.statusCode, <Note>[]);
  }
}

/// 200: success
///
/// 401: session id is NOT valid
Future<int> saveNotesToDb(String? sessionId, List<Note> note) async {
  if (sessionId == null) {
    return 401;
  }

  final Uri uri = Uri.parse("$apiUrl/note/save-notes");

  final Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Cookie': 'SID=$sessionId',
  };

  final String jsonBody = note.toJson();

  var response = await http.post(
    uri,
    headers: headers,
    body: jsonBody,
  );

  return response.statusCode;
}
