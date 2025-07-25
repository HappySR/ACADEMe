import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../academe_theme.dart';
import 'package:ACADEMe/app/admin_panel/subtopic.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ACADEMe/localization/language_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api_endpoints.dart';
import '../../localization/l10n.dart';

class TopicScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;

  const TopicScreen(
      {super.key, required this.courseId, required this.courseTitle});

  @override
  TopicScreenState createState() => TopicScreenState();
}

class TopicScreenState extends State<TopicScreen> {
  List<Map<String, dynamic>> topics = [];
  bool isMenuOpen = false;
  final _storage = FlutterSecureStorage();
  String? _targetLanguage;

  @override
  void initState() {
    super.initState();
    _loadLanguageAndTopics();
  }

  Future<void> _loadLanguageAndTopics() async {
    // Fetch the app's language from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    _targetLanguage =
        prefs.getString('language') ?? 'en'; // Default to 'en' if not set

    // Load topics after fetching the language
    _loadTopics();
  }

  void _toggleMenu() {
    setState(() {
      isMenuOpen = !isMenuOpen;
    });
  }

  void _loadTopics() async {
    String? token = await _storage.read(key: "access_token");
    if (!mounted) {
      return; // Ensure widget is still active before using context
    }

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Authentication failed: No token found")));
      return;
    }

    try {
      final response = await http.get(
        ApiEndpoints.getUri(ApiEndpoints.courseTopics(widget.courseId, _targetLanguage!)),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type":
              "application/json; charset=UTF-8", // Ensure UTF-8 encoding
        },
      );
      if (!mounted) {
        return; // Ensure widget is still active before using context
      }

      if (response.statusCode == 200) {
        List<dynamic> data =
            json.decode(utf8.decode(response.bodyBytes)); // Decode with UTF-8
        setState(() {
          topics = data
              .map((item) => {
                    "id": item["id"].toString(),
                    "title": item["title"],
                    "description": item["description"],
                  })
              .toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Failed to load topics: ${response.statusCode}")));
      }
    } catch (e) {
      if (!mounted) {
        return; // Ensure widget is still active before using context
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error fetching topics: $e")));
    }
  }

  void _addTopic() async {
    String? token = await _storage.read(key: "access_token");
    if (token == null) {
      debugPrint("No access token found");
      return;
    }
    if (!mounted) {
      return; // Ensure widget is still active before using context
    }

    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController titleController = TextEditingController();
        final TextEditingController descriptionController =
            TextEditingController();

        return AlertDialog(
          title: Text(L10n.getTranslatedText(context, 'Add Topic')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                    labelText: L10n.getTranslatedText(context, 'Topic Name')),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                    labelText: L10n.getTranslatedText(context, 'Description')),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(L10n.getTranslatedText(context, 'Cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                final response = await http.post(
                  ApiEndpoints.getUri(ApiEndpoints.courseTopicsNoLang(widget.courseId)),
                  headers: {
                    "Authorization": "Bearer $token",
                    "Content-Type": "application/json; charset=UTF-8",
                  },
                  body: json.encode({
                    "title": titleController.text,
                    "description": descriptionController.text,
                  }),
                );

                if (!context.mounted) {
                  return; // Ensure BuildContext is still valid
                }
                if (response.statusCode == 200 || response.statusCode == 201) {
                  Navigator.pop(
                      context); // Safe because we checked `context.mounted`
                  if (mounted) {
                    setState(() {
                      _loadTopics(); // Refresh topics
                    });
                  }
                } else {
                  debugPrint("Failed to add topic: ${response.body}");
                }
              },
              child: Text(L10n.getTranslatedText(context, 'Add')),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AcademeTheme.appColor,
        title: Text(
          "${widget.courseTitle} >",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  L10n.getTranslatedText(context, 'Topic List'),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Expanded(
              child: topics.isEmpty
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AcademeTheme.appColor, // Custom color
                      ),
                    )
                  : ListView(
                      children: topics
                          .map((topic) => Card(
                                margin: EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  title: Text(topic["title"]!),
                                  subtitle: Text(topic["description"]!),
                                  onTap: () {
                                    final targetLanguage =
                                        Provider.of<LanguageProvider>(context,
                                                listen: false)
                                            .locale
                                            .languageCode;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SubtopicScreen(
                                          courseId: widget.courseId,
                                          topicId: topic["id"]!,
                                          courseTitle: widget.courseTitle,
                                          topicTitle: topic["title"]!,
                                          targetLanguage:
                                              targetLanguage, // Pass the app's language
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ))
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isMenuOpen) ...[
            _buildMenuItem(L10n.getTranslatedText(context, 'Add Topic'),
                Icons.note_add, _addTopic),
            SizedBox(height: 10),
          ],
          FloatingActionButton(
            onPressed: _toggleMenu,
            backgroundColor: AcademeTheme.appColor,
            child:
                Icon(isMenuOpen ? Icons.close : Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(String label, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: GestureDetector(
        onTap: () {
          onTap();
          _toggleMenu();
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          decoration: BoxDecoration(
            color: AcademeTheme.appColor,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 8,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white),
              SizedBox(width: 10),
              Text(label, style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
