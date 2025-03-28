import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class QuizDetailsPage extends StatefulWidget {
  final String quizId;
  const QuizDetailsPage({super.key, required this.quizId});

  @override
  _QuizDetailsPageState createState() => _QuizDetailsPageState();
}

class _QuizDetailsPageState extends State<QuizDetailsPage> {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final String backendUrl = 'http://10.0.2.2:8000';
  Map<String, dynamic>? quizDetails;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchQuizDetails();
  }

  Future<void> fetchQuizDetails() async {
    String? token = await storage.read(key: 'access_token');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('$backendUrl/api/quizzes/${widget.quizId}/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          quizDetails = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        print("❌ Failed to fetch quiz details");
      }
    } catch (e) {
      print("❌ Error fetching quiz details: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quiz Details")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              quizDetails?["title"] ?? "Untitled Quiz",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Number of Questions: ${quizDetails?["questions_count"] ?? "N/A"}",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to quiz attempt page (if exists)
              },
              child: const Text("Start Quiz"),
            ),
          ],
        ),
      ),
    );
  }
}
