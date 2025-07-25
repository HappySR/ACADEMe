import 'package:ACADEMe/api_endpoints.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../localization/l10n.dart';

class ClassSelectionBottomSheet extends StatefulWidget {
  final VoidCallback onClassSelected;

  const ClassSelectionBottomSheet({super.key, required this.onClassSelected});

  @override
  ClassSelectionBottomSheetState createState() =>
      ClassSelectionBottomSheetState();
}

class ClassSelectionBottomSheetState extends State<ClassSelectionBottomSheet> {
  String? selectedClass;
  final List<String> classes = ['5'];
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  String? _storedClass;
  bool _isClassChanged = false;

  @override
  void initState() {
    super.initState();
    _loadStoredClass();
  }

  Future<void> _loadStoredClass() async {
    final storedClass = await _secureStorage.read(key: 'student_class');
    if (mounted) {
      setState(() {
        _storedClass = storedClass;
        selectedClass = storedClass;
        _isClassChanged = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              L10n.getTranslatedText(context, 'What class are you in?'),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              hint: Text(L10n.getTranslatedText(context, 'Select class')),
              value: selectedClass?.isNotEmpty == true ? selectedClass : null,
              items: classes
                  .map((className) => DropdownMenuItem(
                value: className,
                child: Text(className),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedClass = value;
                  _isClassChanged = value != _storedClass;
                });
              },
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isClassChanged ? _handleConfirmPressed : null,
                  child: Text(
                    L10n.getTranslatedText(context, 'Confirm'),
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _handleConfirmPressed() async {
    if (selectedClass == null) {
      _showSnackBar(L10n.getTranslatedText(context, 'Please select a valid class'));
      return;
    }

    final confirmed = await _showConfirmationDialog();
    if (!confirmed) return;

    final success = await _updateClassInBackend(selectedClass!);
    if (!success) return;

    widget.onClassSelected();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<bool> _showConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text(
            L10n.getTranslatedText(context, 'Are you sure you want to change your class?'),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Text(
            L10n.getTranslatedText(context, 'All your progress data will be erased for this class.'),
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                L10n.getTranslatedText(context, 'Cancel'),
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(L10n.getTranslatedText(context, 'Yes')),
            ),
          ],
        );
      },
    ) ??
        false;
  }

  Future<bool> _updateClassInBackend(String selectedClass) async {
    final String? token = await _secureStorage.read(key: 'access_token');

    if (token == null) {
      _showSnackBar(L10n.getTranslatedText(context, 'No access token found'));
      return false;
    }

    try {
      final response = await http.patch(
        ApiEndpoints.getUri(ApiEndpoints.updateClass),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'new_class': selectedClass}),
      );

      if (response.statusCode == 200) {
        return await _reloginUser();
      }

      _showSnackBar('${L10n.getTranslatedText(context, 'Failed to update class')}: ${response.body}');
      return false;
    } catch (e) {
      _showSnackBar(L10n.getTranslatedText(context, 'An error occurred. Please try again.'));
      return false;
    }
  }

  Future<bool> _reloginUser() async {
    final String? email = await _secureStorage.read(key: 'email');
    final String? password = await _secureStorage.read(key: 'password');

    if (email == null || password == null) {
      _showSnackBar(L10n.getTranslatedText(context, 'Session expired. Please login again.'));
      return false;
    }

    try {
      final response = await http.post(
        ApiEndpoints.getUri(ApiEndpoints.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        await _secureStorage.write(
            key: 'access_token', value: responseData['access_token']);
        await _secureStorage.write(key: 'student_class', value: selectedClass);
        return true;
      }

      _showSnackBar('${L10n.getTranslatedText(context, 'Login failed')}: ${response.statusCode}');
      return false;
    } catch (e) {
      _showSnackBar(L10n.getTranslatedText(context, 'Network error during login'));
      return false;
    }
  }

  void _showSnackBar(String message) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}