import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:note_tree/globals.dart';
import 'package:note_tree/models/note_model.dart';
import 'package:note_tree/pages/note_trees.dart';
import 'package:note_tree/utils/requests.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auth Page',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Auth(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Auth extends StatefulWidget {
  const Auth({super.key});

  @override
  AuthState createState() => AuthState();
}

class AuthState extends State<Auth> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    sessionId = getSessionIdFromFile();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auth Page'),
        backgroundColor: Colors.brown[200],
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (context) => notesPage(globalNotes),
              ));
            },
            child: const Icon(Icons.arrow_back),
          ),
        ],
      ),
      backgroundColor: Colors.brown[200],
      body: FutureBuilder(
        future: isSessionIdValid(sessionId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              log(snapshot.error.toString());
              return const Center(
                child: Text(
                  "An error occurred",
                  style: TextStyle(fontSize: 18),
                ),
              );
            } else if (snapshot.hasData) {
              // if session id is valid
              if (snapshot.data == 200) {
                return authSuccess(context);
              } else {
                // if session id is not valid
                return authFail();
              }
            }
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Future<void> _handleRegister() async {
    final String username = usernameController.text;
    final String password = passwordController.text;

    final result = await register(username, password);

    String message = "";
    switch (result.$1) {
      case 200:
        // get session id
        sessionId = result.$2;
        if (sessionId == null) {
          return;
        }
        // save session id to file
        saveSessionIdToFile(sessionId!);
        // get notes
        _loadNotePage();
        break;
      case 400:
        message = "Invalid username or password";
        break;
      case 409:
        message = "Username already taken";
        break;
      default:
        message = "Unexpected error";
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
      ));
    }
  }

  Future<void> _handleLogin() async {
    final String username = usernameController.text;
    final String password = passwordController.text;

    final result = await login(username, password);

    String message = "";
    switch (result.$1) {
      case 200:
        sessionId = result.$2;
        if (sessionId == null) {
          return;
        }
        // save session id to file
        saveSessionIdToFile(sessionId!);
        // get notes
        await _loadNotePage();
        break;
      case 400:
        message = "Invalid username or password";
        break;
      case 401:
        message = "Incorrect password";
        break;
      case 404:
        message = "Username not found";
        break;
      default:
        message = "Unexpected error";
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
      ));
    }
  }

  Future<void> _loadNotePage() async {
    final result = await getNotesFromDb(sessionId);
    globalNotes = result.$2;
    globalNotes.saveToFile();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => notesPage(globalNotes),
        ),
      );
    }
  }

  Padding authFail() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: usernameController,
            decoration: const InputDecoration(labelText: 'Username'),
            maxLength: 20,
          ),
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
            maxLength: 20,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _handleRegister,
            child: const Text('Register'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _handleLogin,
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  Center authSuccess(BuildContext context) {
    return Center(
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              saveNotesToDb(sessionId, globalNotes);
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => notesPage(globalNotes),
                  ),
                );
              }
            },
            child: const Text('Save Notes'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () async {
              await _loadNotePage();
            },
            child: const Text('Retrieve Saved Notes'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () async {
              await logout(sessionId);
              sessionId = null;
              final file = File(sessionIdPath);
              if (file.existsSync()) {
                try {
                  file.deleteSync();
                } on FileSystemException catch (e) {
                  log('Failed to delete session ID: $e');
                }
              }
              if (mounted) {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (context) => const AuthPage(),
                ));
              }
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}
