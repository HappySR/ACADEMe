import 'dart:convert';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ACADEMe/academe_theme.dart';
import 'package:ACADEMe/home/pages/ask_me.dart';
import 'package:ACADEMe/home/components/askme_button.dart';
import 'package:ACADEMe/localization/l10n.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:ACADEMe/localization/language_provider.dart';
import 'topic_view.dart';

class CourseListScreen extends StatefulWidget {
  const CourseListScreen({super.key});

  @override
  CourseListScreenState createState() => CourseListScreenState();
}

class CourseListScreenState extends State<CourseListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = true;
  List<Map<String, dynamic>> courses = [];
  String backendUrl = dotenv.env['BACKEND_URL'] ?? '';
  final storage = FlutterSecureStorage();

  final AutoSizeGroup _tabTextGroup = AutoSizeGroup();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchCourses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchCourses() async {
    if (!mounted) return; // ✅ Ensure widget is still active

    setState(() {
      isLoading = true; // Show loading indicator
    });

    String? token = await storage.read(key: 'access_token');
    if (token == null) {
      debugPrint("No access token found");

      if (mounted) {
        setState(() {
          isLoading = false; // Hide loading indicator
        });
      }
      return;
    }

    try {
      if (!mounted) return; // ✅ Ensure widget is still active

      String targetLanguage =
          Provider.of<LanguageProvider>(context, listen: false)
              .locale
              .languageCode;

      final response = await http.get(
        Uri.parse('$backendUrl/api/courses/?target_language=$targetLanguage'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (mounted) {
        if (response.statusCode == 200) {
          List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));

          setState(() {
            courses = data
                .map((course) => {
                      "id": course["id"],
                      "title": course["title"],
                      "progress": 0.0,
                    })
                .toList();
          });
        } else {
          debugPrint("Failed to fetch courses: ${response.statusCode}");
        }
      }
    } catch (e) {
      debugPrint("Error fetching courses: $e");
    } finally {
      // ✅ Only call setState() if mounted
      if (mounted) {
        setState(() {
          isLoading = false; // Hide loading indicator
        });
      }
    }
  }

  Future<double> getCourseProgress(String courseId) async {
    String userId = "user_id"; // Replace with actual user ID
    QuerySnapshot progressSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('progress')
        .where('course_id', isEqualTo: courseId)
        .get();

    int completedActivities = progressSnapshot.docs
        .where((doc) => doc['status'] == 'completed')
        .length;

    DocumentSnapshot courseDoc = await FirebaseFirestore.instance
        .collection('courses')
        .doc(courseId)
        .get();

    int totalQuizzes = courseDoc['total_quizzes'] ?? 0;
    int totalMaterials = courseDoc['total_materials'] ?? 0;
    int totalActivities = totalQuizzes + totalMaterials;

    if (totalActivities == 0) return 0.0;
    return (completedActivities / totalActivities);
  }

  @override
  Widget build(BuildContext context) {
    return ASKMeButton(
      onFABPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AskMe()),
        );
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: AcademeTheme.appColor,
          automaticallyImplyLeading: false,
          elevation: 0,
          title: Text(
            L10n.getTranslatedText(context, 'My Courses'),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        body: Column(
          children: [
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.black54,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(width: 2, color: Colors.blue),
                ),
                tabs: [
                  _buildSynchronizedTab(context, 'ALL'),
                  _buildSynchronizedTab(context, 'ON GOING'),
                  _buildSynchronizedTab(context, 'COMPLETED'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCourseList(),
                  _buildFilteredCourses(ongoing: true),
                  _buildFilteredCourses(ongoing: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSynchronizedTab(BuildContext context, String labelKey) {
    return Tab(
      child: AutoSizeText(
        L10n.getTranslatedText(context, labelKey),
        maxLines: 1,
        group: _tabTextGroup, // Ensures all tabs scale together
        style: TextStyle(fontSize: 16),
        minFontSize: 12, // Prevents text from becoming unreadable
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCourseList() {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AcademeTheme.appColor,
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        return _buildCourseCard(courses[index]);
      },
    );
  }

  Widget _buildFilteredCourses({required bool ongoing}) {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AcademeTheme.appColor,
        ),
      );
    }

    List<Map<String, dynamic>> filteredCourses = courses.where((course) {
      return ongoing ? course["progress"] < 1.0 : course["progress"] >= 1.0;
    }).toList();

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: filteredCourses.length,
      itemBuilder: (context, index) {
        return _buildCourseCard(filteredCourses[index]);
      },
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    return GestureDetector(
      onTap: () async {
        String selectedCourseId = course["id"];
        debugPrint("Selected Course ID: $selectedCourseId");

        try {
          await storage.write(key: 'course_id', value: selectedCourseId);

          if (!mounted) {
            return; // ✅ Ensure widget is still mounted before using context
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TopicViewScreen(courseId: selectedCourseId),
            ),
          );
        } catch (error) {
          debugPrint("Error storing course ID: $error");
        }
      },
      child: Container(
        height: 120,
        margin: EdgeInsets.only(bottom: 15),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 5,
              spreadRadius: 2,
            )
          ],
        ),
        child: Row(
          children: [
            SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    course["title"],
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Stack(
                    children: [
                      Container(
                        height: 5,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      Container(
                        height: 5,
                        width: MediaQuery.of(context).size.width *
                            (course["progress"] * 0.6),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                              "0/12 ${L10n.getTranslatedText(context, 'Modules')}")),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "${(course["progress"].clamp(0.0, 1.0) * 100).toInt()}% ",
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
