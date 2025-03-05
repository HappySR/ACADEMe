import 'package:ACADEMe/started/pages/login_view.dart';
import '../../academe_theme.dart';
import 'package:flutter/material.dart';
import '../../home/auth/auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ACADEMe/localization/l10n.dart';

import '../../home/auth/role.dart';
import '../../home/pages/bottomNav.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _agreeToTerms = false;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isGoogleLoading = false;

  /// Handles user signup
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(L10n.getTranslatedText(
                context, 'I agree to terms and conditions'))),
      );
      return;
    }

    setState(() => _isLoading = true);

    final (_, errorMessage) = await AuthService().signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _usernameController.text.trim(),
        "SELECT",
        "https://www.w3schools.com/w3images/avatar2.png");

    setState(() => _isLoading = false);

    // Fetch stored token
    String? token = await _secureStorage.read(key: "access_token");

    if (token != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            L10n.getTranslatedText(context, 'Account created successfully!')),
      ));
      await UserRoleManager().fetchUserRole(); // ✅ Fetch user role before navigating
      bool isAdmin = UserRoleManager().isAdmin;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BottomNav(isAdmin: isAdmin),
        ),
      ); // Redirect to courses
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errorMessage ??
            L10n.getTranslatedText(context, 'Signup failed. Please try again')),
      ));
    }
  }

  /// Handles Google Sign-Up
  Future<void> _signUpWithGoogle() async {
    setState(() => _isGoogleLoading = true);

    final (user, errorMessage) = await AuthService().signInWithGoogle();
    setState(() => _isGoogleLoading = false);

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(errorMessage ??
                L10n.getTranslatedText(
                    context, '❌ Google Sign-Up failed. Please try again'))),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(L10n.getTranslatedText(
              context, '✅ Signed up successfully with Google!'))),
    );
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 100, top: 80),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 250, maxHeight: 300),
                    child: Image.asset(
                      'assets/academe/study_image.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 30, right: 30),
                            child: Text(
                              '${L10n.getTranslatedText(context, 'Create Your ')} '
                              '${L10n.getTranslatedText(context, 'Account')}',
                              style: TextStyle(
                                fontSize: 39.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 30, right: 30),
                      child: TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                            filled: true,
                            fillColor: AcademeTheme.notWhite,
                            labelText:
                                L10n.getTranslatedText(context, 'Username'),
                            hintText: L10n.getTranslatedText(
                                context, 'Enter a username'),
                            prefixIcon: Icon(Icons.person)),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return L10n.getTranslatedText(
                                context, 'Please enter a username');
                          }
                          return null;
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 30, right: 30, top: 16),
                      child: TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                            filled: true,
                            fillColor: AcademeTheme.notWhite,
                            labelText: L10n.getTranslatedText(context, 'Email'),
                            hintText: L10n.getTranslatedText(
                                context, 'Enter your email'),
                            prefixIcon: Icon(Icons.email)),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return L10n.getTranslatedText(
                                context, 'Please enter an email');
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value)) {
                            return L10n.getTranslatedText(
                                context, 'Enter a valid email');
                          }
                          return null;
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 30, right: 30, top: 16),
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AcademeTheme.notWhite,
                          labelText:
                              L10n.getTranslatedText(context, 'Password'),
                          hintText: L10n.getTranslatedText(
                              context, 'Enter your password'),
                          prefixIcon: Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(_isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return L10n.getTranslatedText(
                                context, 'Please enter a password');
                          }
                          if (value.length < 6) {
                            return L10n.getTranslatedText(
                                context, 'Password must be at least 6 characters');
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(
                      height: 4,
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 20, right: 40),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _agreeToTerms,
                            onChanged: (value) {
                              setState(() {
                                _agreeToTerms = value ?? false;
                              });
                            },
                          ),
                          Text(
                            L10n.getTranslatedText(
                                context, 'I agree to terms and conditions'),
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 4,
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 35),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.yellow[600], // Change button color
                            minimumSize:
                                Size(double.infinity, 50), // Adjust button size
                          ),
                          child: _isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment
                                      .center, // Center the content
                                  children: [
                                    Image.asset(
                                      'assets/icons/house_door.png', // Replace with your image path
                                      height: 24, // Adjust size
                                      width: 24,
                                    ),
                                    SizedBox(
                                        width:
                                            10), // Space between icon and text
                                    Text(
                                      L10n.getTranslatedText(context, 'Signup'),
                                      style: TextStyle(
                                        fontSize: 18, // Adjust font size
                                        fontWeight: FontWeight
                                            .w500, // Change font weight
                                        color: Colors.black, // Text color
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      L10n.getTranslatedText(context, 'OR'),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    //
                    // SizedBox(height: 2),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 35),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              _isGoogleLoading ? null : _signUpWithGoogle,
                          icon: _isGoogleLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Padding(
                                  padding: EdgeInsets.only(
                                      right: 7), // Adjust spacing
                                  child: Image.asset(
                                      'assets/icons/google_icon.png',
                                      height: 22),
                                ),
                          label: Text(
                            L10n.getTranslatedText(
                                context, 'Continue with Google'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(
                      height: 30,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          L10n.getTranslatedText(
                              context, 'Already have an account?'),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => LogInView()),
                            );
                          },
                          child: Text(
                            L10n.getTranslatedText(context, 'login'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AcademeTheme
                                  .appColor, // Change color for emphasis
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                        height: 16), // Adds spacing before the "Sign Up" button
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
