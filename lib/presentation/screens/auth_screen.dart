import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/language_provider.dart';
import '../../logic/providers/auth_provider.dart';
import 'privacy_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  bool isLogin = true;
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _obscurePassword = true;
  bool _acceptedTerms = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      isLogin = !isLogin;
      _acceptedTerms = false;
    });
    _animationController.reset();
    _animationController.forward();
  }

  String _getErrorMessage(String message, String? code, bool isArabic) {
    if (message.contains('Invalid login credentials') || code == '400') {
      return isArabic
          ? 'رقم الجوال أو كلمة المرور غير صحيحة'
          : 'Invalid phone or password';
    } else if (message.contains('User already registered')) {
      return isArabic
          ? 'هذا الرقم مسجل بالفعل'
          : 'This phone is already registered';
    } else if (message.contains('Password should be at least')) {
      return isArabic
          ? 'كلمة المرور يجب أن تكون 6 أحرف على الأقل'
          : 'Password must be at least 6 characters';
    }
    return isArabic ? 'حدث خطأ غير متوقع' : 'An unexpected error occurred';
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final isArabic = Provider.of<LanguageProvider>(
      context,
      listen: false,
    ).isArabic;

    if (!isLogin && !_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'يجب الموافقة على الشروط وسياسة الخصوصية أولاً'
                : 'You must agree to the terms and privacy policy first',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    Map<String, dynamic> result;
    if (isLogin) {
      result = await authProvider.login(
        _phoneController.text,
        _passwordController.text,
      );
    } else {
      result = await authProvider.register(
        _nameController.text,
        _phoneController.text,
        _passwordController.text,
      );
    }

    if (mounted) {
      if (result['success'] == true) {
        context.go('/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _getErrorMessage(
                result['message'] ?? '',
                result['code'],
                isArabic,
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LanguageProvider, AuthProvider>(
      builder: (context, languageProvider, authProvider, child) {
        final isArabic = languageProvider.isArabic;
        final isLoading = authProvider.isLoading;

        return Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 40,
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),

                        // Logo or Brand
                        Center(
                          child: Image.asset(
                            'assets/images/logo.jpeg',
                            width: 160,
                            height: 160,
                            fit: BoxFit.contain,
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Welcome Text
                        Text(
                          isLogin
                              ? (isArabic ? 'مرحباً بعودتك!' : 'Welcome Back!')
                              : (isArabic
                                    ? 'إنشاء حساب جديد'
                                    : 'Create Account'),
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isLogin
                              ? (isArabic
                                    ? 'قم بتسجيل الدخول للمتابعة'
                                    : 'Sign in to your account to continue')
                              : (isArabic
                                    ? 'سجل الآن وابدأ التسوق من متجر لحومي'
                                    : 'Sign up to get started with Meatly Store'),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),

                        const SizedBox(height: 40),

                        // Form
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              if (!isLogin) ...[
                                TextFormField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: isArabic
                                        ? 'الاسم الكامل'
                                        : 'Full Name',
                                    prefixIcon: const Icon(
                                      Iconsax.user,
                                      size: 20,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (!isLogin &&
                                        (value == null || value.isEmpty)) {
                                      return isArabic
                                          ? 'يرجى إدخال اسمك الكامل'
                                          : 'Please enter your full name';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                              ],

                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  labelText: isArabic
                                      ? 'رقم الهاتف'
                                      : 'Phone Number',
                                  prefixIcon: const Icon(
                                    Iconsax.call,
                                    size: 20,
                                  ),
                                  hintText: '05xxxxxxxx',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return isArabic
                                        ? 'يرجى إدخال رقم الهاتف'
                                        : 'Please enter your phone number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Password field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: isArabic
                                      ? 'كلمة المرور'
                                      : 'Password',
                                  prefixIcon: const Icon(
                                    Iconsax.lock_1,
                                    size: 20,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Iconsax.eye_slash
                                          : Iconsax.eye,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return isArabic
                                        ? 'يرجى إدخال كلمة المرور'
                                        : 'Please enter your password';
                                  }
                                  if (value.length < 6) {
                                    return isArabic
                                        ? 'يجب أن تكون كلمة المرور 6 أحرف على الأقل'
                                        : 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              if (!isLogin)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Checkbox(
                                      value: _acceptedTerms,
                                      onChanged: (value) {
                                        setState(() {
                                          _acceptedTerms = value ?? false;
                                        });
                                      },
                                    ),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const PrivacyScreen(),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          isArabic
                                              ? 'أوافق على الشروط والأحكام وسياسة الخصوصية'
                                              : 'I agree to the terms and privacy policy',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                              const SizedBox(height: 24),

                              // Submit Button
                              SizedBox(
                                width: double.infinity,
                                height: 60,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : _submitForm,
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : Text(
                                          isLogin
                                              ? (isArabic
                                                    ? 'تسجيل الدخول'
                                                    : 'Sign In')
                                              : (isArabic
                                                    ? 'إنشاء حساب'
                                                    : 'Sign Up'),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 40),

                              // Toggle Auth Mode
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    isLogin
                                        ? (isArabic
                                              ? 'ليس لديك حساب؟ '
                                              : "Don't have an account? ")
                                        : (isArabic
                                              ? 'لديك حساب بالفعل؟ '
                                              : "Already have an account? "),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                  TextButton(
                                    onPressed: _toggleAuthMode,
                                    child: Text(
                                      isLogin
                                          ? (isArabic ? 'سجل الآن' : 'Sign Up')
                                          : (isArabic
                                                ? 'سجل دخولك'
                                                : 'Sign In'),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
