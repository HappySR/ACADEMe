import 'package:ACADEMe/academe_theme.dart';
import 'package:ACADEMe/localization/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class QuizPage extends StatefulWidget {
  final List<Map<String, dynamic>> quizzes;
  final Function()? onQuizComplete;
  final Function()? onSwipeToNext; // Add this callback
  final String courseId;
  final String topicId;
  final String subtopicId;
  final String subtopicTitle;
  final bool hasNextMaterial; // Add this to know if there's a next material

  const QuizPage({
    super.key,
    required this.quizzes,
    this.onQuizComplete,
    this.onSwipeToNext, // Add this parameter
    required this.courseId,
    required this.topicId,
    required this.subtopicId,
    required this.subtopicTitle,
    this.hasNextMaterial = false, // Add this parameter with default value
  });

  @override
  QuizPageState createState() => QuizPageState();
}

class QuizPageState extends State<QuizPage> {
  int _currentQuestionIndex = 0;
  int? _selectedAnswer;
  bool isSubmitting = false;
  final String _baseUrl = dotenv.env['BACKEND_URL'] ??
      'http://10.0.2.2:8000'; // Replace with your API endpoint
  List<dynamic> _progressList = [];
  final FlutterSecureStorage _storage =
      const FlutterSecureStorage(); // Add FlutterSecureStorage

  @override
  void initState() {
    super.initState();
    _fetchProgress();
  }

  Future<void> _fetchProgress() async {
    String? token =
        await _storage.read(key: 'access_token'); // Retrieve the access token
    if (!mounted) {
      return; // Ensure widget is still active before using context
    }
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                L10n.getTranslatedText(context, 'Access token not found'))),
      );
      return;
    }

    final response = await http.get(
      Uri.parse(
          "$_baseUrl/api/progress/?target_language=en"), // Hardcoded "en" for English
      headers: {
        'Authorization':
            'Bearer $token', // Include the access token in the headers
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _progressList = data["progress"];
      });
    } else if (response.statusCode == 404) {
      // Handle 404 Not Found error (no progress records)
      final responseBody = json.decode(response.body);
      if (responseBody["detail"] == "No progress records found") {
        setState(() {
          _progressList = []; // Treat as an empty progress list
        });
      } else {
        if (!mounted) {
          return; // Ensure widget is still active before using context
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(L10n.getTranslatedText(
                  context, 'No progress records found'))),
        );
      }
    } else {
      if (!mounted) {
        return; // Ensure widget is still active before using context
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                L10n.getTranslatedText(context, 'Failed to fetch progress'))),
      );
    }
  }

  Future<void> _sendProgress(
      bool isCorrect, String quizId, String questionId) async {
    String? token = await _storage.read(key: 'access_token');
    if (!mounted) {
      return;
    }
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                L10n.getTranslatedText(context, 'Access token not found'))),
      );
      return;
    }

    // Calculate score per question
    final totalQuestions = widget.quizzes.length;
    final scorePerQuestion = totalQuestions > 0 ? (100 / totalQuestions) : 0;
    final score = isCorrect ? scorePerQuestion : 0;

    final existingProgress = _progressList.firstWhere(
      (progress) =>
          progress["quiz_id"] == quizId &&
          progress["question_id"] == questionId,
      orElse: () => null,
    );

    if (existingProgress == null) {
      // Create new progress
      final response = await http.post(
        Uri.parse("$_baseUrl/api/progress/"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode({
          "course_id": widget.courseId,
          "topic_id": widget.topicId,
          "subtopic_id": widget.subtopicId,
          "material_id": null,
          "quiz_id": quizId,
          "question_id": questionId, // Add question_id
          "score": score,
          "status": "completed",
          "activity_type": "quiz",
          "metadata": {
            "time_spent": "5 minutes",
          },
          "timestamp": DateTime.now().toIso8601String(),
        }),
      );
      if (!mounted) {
        return;
      }
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(L10n.getTranslatedText(
                  context, 'Progress saved successfully'))),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  L10n.getTranslatedText(context, 'Failed to save progress'))),
        );
      }
    } else {
      // Update existing progress
      final progressId = existingProgress["progress_id"];
      final response = await http.put(
        Uri.parse("$_baseUrl/api/progress/$progressId"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode({
          "status": "completed",
          "score": score,
          "metadata": {
            "time_spent": "5 minutes",
          },
        }),
      );
      if (!mounted) {
        return;
      }

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(L10n.getTranslatedText(
                  context, 'Progress updated successfully'))),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(L10n.getTranslatedText(
                  context, 'Failed to update progress'))),
        );
      }
    }
  }

  // Store result in Shared Preferences
  Future<void> _storeQuizResult(bool isCorrect) async {
  final String storageKey = 'quiz_results_${widget.courseId}_${widget.topicId}';
  String? existingResults = await _storage.read(key: storageKey);

  Map<String, dynamic> results = existingResults != null
      ? json.decode(existingResults)
      : {
          'totalQuestions': 0,
          'correctAnswers': 0,
          'quizData': [],
          'lastUpdated': DateTime.now().toIso8601String(),
        };

  results['totalQuestions'] = (results['totalQuestions'] as int) + 1;
  if (isCorrect) {
    results['correctAnswers'] = (results['correctAnswers'] as int) + 1;
  }
  
  // Add current quiz data
  final currentQuiz = widget.quizzes[_currentQuestionIndex];
  results['quizData'].add({
    'title': widget.subtopicTitle,

    'isCorrect': isCorrect,
    'timestamp': DateTime.now().toIso8601String(),
  });
  
  results['lastUpdated'] = DateTime.now().toIso8601String();

  await _storage.write(
    key: storageKey,
    value: json.encode(results),
  );
}
  void _showResultPopup(
      bool isCorrect, String submittedQuizId, String questionId) {
    // Show a dialog with the result and an icon
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isCorrect ? Colors.green : Colors.red,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isCorrect ? Icons.check : Icons.close,
                color: Colors.white,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                isCorrect
                    ? L10n.getTranslatedText(context, 'Correct Answer!')
                    : L10n.getTranslatedText(context, 'Wrong Answer!'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (isCorrect) ...[
                const SizedBox(height: 8),
                const Text(
                  "+1 🔥",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );

    // Navigate after 2 seconds
    Future.delayed(const Duration(milliseconds: 200), () async {
      if (!mounted) return;

      Navigator.pop(context); // Close result dialog

      await _storeQuizResult(isCorrect);

      // FIXED: Send progress BEFORE any state changes or callbacks
      await _sendProgress(isCorrect, submittedQuizId, questionId);

      // Reset quiz state
      setState(() {
        isSubmitting = false;
        _currentQuestionIndex = 0;
        _selectedAnswer = null;
      });

      // Trigger next material if exists, else complete quiz
      if (widget.hasNextMaterial && widget.onSwipeToNext != null) {
        widget.onSwipeToNext!(); // Trigger swipe to next material
      } else {
        if (widget.onQuizComplete != null) {
          widget.onQuizComplete!();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.quizzes.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text(
            L10n.getTranslatedText(context, 'No quizzes available'),
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    final currentQuiz = widget.quizzes[_currentQuestionIndex];
    final questionText =
        currentQuiz["question_text"] ?? "No question text available";
    final options =
        (currentQuiz["options"] as List<dynamic>?)?.cast<String>() ??
            ["No options available"];
    final correctOption = currentQuiz["correct_option"] as int? ?? 0;
    final quizId = currentQuiz["id"] as String? ?? "";

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question Box with Increased Minimum Height
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(
                      minHeight: 155, // Set minimum height here
                    ),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AcademeTheme.appColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        questionText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Answer Options
                  Expanded(
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // Two options per row
                        crossAxisSpacing: 12, // Horizontal spacing
                        mainAxisSpacing: 12, // Vertical spacing
                        childAspectRatio: 1.5, // Adjust aspect ratio
                      ),
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            if (!isSubmitting) {
                              setState(() {
                                _selectedAnswer = index;
                              });
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: _selectedAnswer == index
                                  ? AcademeTheme.appColor
                                  : Colors.white,
                              border: Border.all(
                                color: AcademeTheme.appColor,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: Text(
                                options[index],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedAnswer == index
                                      ? Colors.white
                                      : AcademeTheme.appColor,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.visible,
                                maxLines: 2,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Submit Button Fixed at Bottom
          SafeArea(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () {
                        if (_selectedAnswer != null) {
                          setState(() {
                            isSubmitting = true;
                          });

                          final submittedQuizId = quizId;
                          final currentQuiz =
                              widget.quizzes[_currentQuestionIndex];
                          final questionId =
                              currentQuiz["question_id"]?.toString() ??
                                  currentQuiz["id"]?.toString() ??
                                  "";
                          final submittedQuestionIndex = _currentQuestionIndex;
                          bool isCorrect = _selectedAnswer == correctOption;

                          _showResultPopup(
                              isCorrect, submittedQuizId, questionId);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(L10n.getTranslatedText(
                                    context, 'Please select an answer!'))),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.yellow, // Fixed color (won't change when disabled)
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  // Ensures no overlay effect on disabled state
                  disabledBackgroundColor:
                      Colors.yellow, // Keep the same as enabled state
                  disabledForegroundColor: Colors.black, // Keep text color same
                ),
                child: Text(
                  L10n.getTranslatedText(
                      context, 'Submit'), // Keep the text fixed
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
