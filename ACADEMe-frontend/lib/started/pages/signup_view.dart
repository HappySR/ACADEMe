import 'package:ACADEMe/started/pages/login_view.dart';
import '../../academe_theme.dart';
import 'package:flutter/material.dart';
import '../../home/auth/auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ACADEMe/localization/l10n.dart';
import '../../home/auth/role.dart';
import '../../home/pages/bottom_nav.dart';

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
  final _otpController = TextEditingController();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _agreeToTerms = false;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isGoogleLoading = false;
  bool _otpSent = false;
  bool _isOtpLoading = false;
  bool _isVerifyingOtp = false;

  /// Send OTP to email
  Future<void> _sendOtp() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L10n.getTranslatedText(context, 'Please enter an email')),
        ),
      );
      return;
    }

    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L10n.getTranslatedText(context, 'Enter a valid email')),
        ),
      );
      return;
    }

    setState(() => _isOtpLoading = true);

    final (success, message) = await AuthService().sendOTP(_emailController.text.trim());

    if (!mounted) return;
    setState(() => _isOtpLoading = false);

    if (success) {
      setState(() => _otpSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message ?? L10n.getTranslatedText(context, 'OTP sent successfully')),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message ?? L10n.getTranslatedText(context, 'Failed to send OTP')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Handles user signup with OTP verification
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L10n.getTranslatedText(context, 'I agree to terms and conditions')),
        ),
      );
      return;
    }

    if (!_otpSent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L10n.getTranslatedText(context, 'Please verify your email with OTP first')),
        ),
      );
      return;
    }

    if (_otpController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L10n.getTranslatedText(context, 'Please enter the OTP')),
        ),
      );
      return;
    }

    setState(() => _isVerifyingOtp = true);

    final (user, errorMessage) = await AuthService().signUp(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _usernameController.text.trim(),
      "SELECT",
      "https://www.w3schools.com/w3images/avatar2.png",
      _otpController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isVerifyingOtp = false);

    if (user != null) {
      // Store email and password in secure storage
      await _secureStorage.write(key: 'email', value: _emailController.text.trim());
      await _secureStorage.write(key: 'password', value: _passwordController.text.trim());

      await UserRoleManager().fetchUserRole(_emailController.text.trim());
      if (!mounted) return;
      bool isAdmin = UserRoleManager().isAdmin;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L10n.getTranslatedText(context, 'Account created successfully!')),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BottomNav(isAdmin: isAdmin),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage ?? L10n.getTranslatedText(context, 'Signup failed. Please try again')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Handles Google Sign-Up
  Future<void> _signUpWithGoogle() async {
    setState(() => _isGoogleLoading = true);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(L10n.getTranslatedText(context,
            'Google Sign-Up is turned off for now. Please sign up manually.')),
      ),
    );

    setState(() => _isGoogleLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
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
                    constraints: BoxConstraints(
                        maxWidth: width * 0.6, maxHeight: height * 0.5),
                    child: Image.asset(
                      'assets/images/signUp_logo.png',
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
                            padding: EdgeInsets.only(
                                left: width * 0.09, right: width * 0.09),
                            child: Text(
                              '${L10n.getTranslatedText(context, 'Create Your ')} '
                                  '${L10n.getTranslatedText(context, 'Account')}',
                              style: TextStyle(
                                fontSize: width * 0.1,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: height * 0.025),
                    Padding(
                      padding: EdgeInsets.only(
                          left: width * 0.08, right: width * 0.08),
                      child: TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AcademeTheme.notWhite,
                          labelText: L10n.getTranslatedText(context, 'Username'),
                          hintText: L10n.getTranslatedText(context, 'Enter a username'),
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7),
                            borderSide: const BorderSide(
                              color: Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return L10n.getTranslatedText(context, 'Please enter a username');
                          }
                          return null;
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                          left: width * 0.08,
                          right: width * 0.08,
                          top: height * 0.015),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _emailController,
                              enabled: !_otpSent, // Disable email field after OTP is sent
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: _otpSent ? Colors.grey[200] : AcademeTheme.notWhite,
                                labelText: L10n.getTranslatedText(context, 'Email'),
                                hintText: L10n.getTranslatedText(context, 'Enter your email'),
                                prefixIcon: const Icon(Icons.email),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(7),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(7),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(7),
                                  borderSide: const BorderSide(
                                    color: Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return L10n.getTranslatedText(context, 'Please enter an email');
                                }
                                if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                  return L10n.getTranslatedText(context, 'Enter a valid email');
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(width: width * 0.02),
                          ElevatedButton(
                            onPressed: _otpSent ? null : (_isOtpLoading ? null : _sendOtp),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _otpSent ? Colors.green : Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(7),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: width * 0.03,
                                vertical: height * 0.02,
                              ),
                            ),
                            child: _isOtpLoading
                                ? SizedBox(
                              width: width * 0.04,
                              height: width * 0.04,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : Text(
                              _otpSent
                                  ? L10n.getTranslatedText(context, 'Sent')
                                  : L10n.getTranslatedText(context, 'Send OTP'),
                              style: TextStyle(fontSize: width * 0.03),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // OTP Input Field (only show if OTP is sent)
                    if (_otpSent)
                      Padding(
                        padding: EdgeInsets.only(
                            left: width * 0.08,
                            right: width * 0.08,
                            top: height * 0.015),
                        child: TextFormField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AcademeTheme.notWhite,
                            labelText: L10n.getTranslatedText(context, 'OTP'),
                            hintText: L10n.getTranslatedText(context, 'Enter 6-digit OTP'),
                            prefixIcon: const Icon(Icons.security),
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(7),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(7),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(7),
                              borderSide: const BorderSide(
                                color: Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (_otpSent && (value == null || value.isEmpty)) {
                              return L10n.getTranslatedText(context, 'Please enter the OTP');
                            }
                            if (_otpSent && value!.length != 6) {
                              return L10n.getTranslatedText(context, 'OTP must be 6 digits');
                            }
                            return null;
                          },
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.only(
                          left: width * 0.08,
                          right: width * 0.08,
                          top: height * 0.015),
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AcademeTheme.notWhite,
                          labelText: L10n.getTranslatedText(context, 'Password'),
                          hintText: L10n.getTranslatedText(context, 'Enter your password'),
                          prefixIcon: const Icon(Icons.lock),
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
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7),
                            borderSide: const BorderSide(
                              color: Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return L10n.getTranslatedText(context, 'Please enter a password');
                          }
                          if (value.length < 6) {
                            return L10n.getTranslatedText(context, 'Password must be at least 6 characters');
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(height: height * 0.006),
                    Padding(
                      padding: EdgeInsets.only(
                          left: width * 0.06, right: width * 0.06),
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
                          Expanded(
                            child: Text(
                              L10n.getTranslatedText(context, 'I agree to terms and conditions'),
                              style: TextStyle(fontSize: width * 0.037),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: height * 0.005),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: width * 0.07),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isVerifyingOtp ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellow[600],
                            minimumSize: Size(double.infinity, width * 0.11),
                          ),
                          child: _isVerifyingOtp
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/icons/house_door.png',
                                height: height * 0.05,
                                width: width * 0.06,
                              ),
                              SizedBox(width: width * 0.025),
                              Text(
                                L10n.getTranslatedText(context, 'Signup'),
                                style: TextStyle(
                                  fontSize: width * 0.045,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: height * 0.01),
                    Text(
                      L10n.getTranslatedText(context, 'OR'),
                      style: TextStyle(
                        fontSize: width * 0.04,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: width * 0.07),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isGoogleLoading ? null : _signUpWithGoogle,
                          icon: _isGoogleLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Padding(
                            padding: EdgeInsets.only(right: width * 0.02),
                            child: Image.asset(
                                'assets/icons/google_icon.png',
                                height: height * 0.025),
                          ),
                          label: Text(
                            L10n.getTranslatedText(context, 'Continue with Google'),
                            style: TextStyle(
                              fontSize: width * 0.045,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[100],
                            foregroundColor: Colors.black,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            minimumSize: Size(double.infinity, width * 0.11),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: height * 0.03),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          L10n.getTranslatedText(context, 'Already have an account?'),
                          style: TextStyle(
                            fontSize: width * 0.04,
                            color: Colors.black54,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const LogInView()),
                            );
                          },
                          child: Text(
                            L10n.getTranslatedText(context, 'login'),
                            style: TextStyle(
                              fontSize: width * 0.04,
                              fontWeight: FontWeight.w500,
                              color: AcademeTheme.appColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }
}
