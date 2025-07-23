import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart';
import '../entryPoint/entry_point.dart';
import '../../services/user_service.dart';
import '../../services/supabase_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  
  bool isShowLoading = false;
  bool isShowConfetti = false;
  late SMITrigger error;
  late SMITrigger success;
  late SMITrigger reset;
  late SMITrigger confetti;

  void _onCheckRiveInit(Artboard artboard) {
    StateMachineController? controller =
        StateMachineController.fromArtboard(artboard, 'State Machine 1');

    artboard.addController(controller!);
    error = controller.findInput<bool>('Error') as SMITrigger;
    success = controller.findInput<bool>('Check') as SMITrigger;
    reset = controller.findInput<bool>('Reset') as SMITrigger;
  }

  void _onConfettiRiveInit(Artboard artboard) {
    StateMachineController? controller =
        StateMachineController.fromArtboard(artboard, "State Machine 1");
    artboard.addController(controller!);

    confetti = controller.findInput<bool>("Trigger explosion") as SMITrigger;
  }

  void signIn(BuildContext context) {
    setState(() {
      isShowConfetti = true;
      isShowLoading = true;
    });
    
    Future.delayed(
      const Duration(seconds: 1),
      () async {
        if (_formKey.currentState!.validate()) {
          try {
            // Sign in with Supabase
            final supabaseService = SupabaseService.instance;
            final response = await supabaseService.signIn(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );

            if (response.user != null) {
              // Get user profile from database
              final userProfile = await supabaseService.getUserProfile(response.user!.id);
              
              if (userProfile != null) {
                // Save user data to local state
                final userService = Provider.of<UserService>(context, listen: false);
                userService.setUser(
                  fullName: userProfile['full_name'],
                  grade: userProfile['grade'] ?? 'N/A',
                  email: userProfile['email'],
                  role: userProfile['role'] ?? 'student',
                  subjectSpecialization: userProfile['subject_specialization'],
                );

                success.fire();
                Future.delayed(
                  const Duration(seconds: 2),
                  () {
                    setState(() {
                      isShowLoading = false;
                    });
                    confetti.fire();
                    // Navigate & hide confetti
                    Future.delayed(const Duration(seconds: 1), () {
                      if (!context.mounted) return;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EntryPoint(),
                        ),
                      );
                    });
                  },
                );
              } else {
                throw Exception('User profile not found');
              }
            } else {
              throw Exception('Login failed');
            }
          } catch (e) {
            // Handle login error
            error.fire();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Login failed: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            setState(() {
              isShowLoading = false;
            });
            reset.fire();
          }
        } else {
          error.fire();
          Future.delayed(
            const Duration(seconds: 2),
            () {
              setState(() {
                isShowLoading = false;
              });
              reset.fire();
            },
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF1F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Login to Emcie',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7553F6).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.login,
                            size: 48,
                            color: Color(0xFF7553F6),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Welcome Back!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Sign in to continue your math learning journey',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    "Email",
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    child: TextFormField(
                      controller: _emailController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "";
                        }
                        if (!value.contains('@')) {
                          return "";
                        }
                        return null;
                      },
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        prefixIcon: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: SvgPicture.asset("assets/icons/email.svg"),
                        ),
                        hintText: "Enter your email address",
                      ),
                    ),
                  ),
                  const Text(
                    "Password",
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "";
                        }
                        return null;
                      },
                      keyboardType: TextInputType.visiblePassword,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        prefixIcon: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.lock, color: Colors.black54),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            color: Colors.black54,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        hintText: "Enter your password",
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        signIn(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7553F6),
                        minimumSize: const Size(double.infinity, 56),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(25),
                            bottomRight: Radius.circular(25),
                            bottomLeft: Radius.circular(25),
                          ),
                        ),
                      ),
                      icon: const Icon(
                        CupertinoIcons.arrow_right,
                        color: Colors.white,
                      ),
                      label: const Text(
                        "Sign In",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(color: Colors.black54),
                          children: [
                            TextSpan(text: "Don't have an account? "),
                            TextSpan(
                              text: "Create Account",
                              style: TextStyle(
                                color: Color(0xFF7553F6),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          isShowLoading
              ? CustomPositioned(
                  child: RiveAnimation.asset(
                    'assets/RiveAssets/check.riv',
                    fit: BoxFit.cover,
                    onInit: _onCheckRiveInit,
                  ),
                )
              : const SizedBox(),
          isShowConfetti
              ? CustomPositioned(
                  scale: 6,
                  child: RiveAnimation.asset(
                    "assets/RiveAssets/confetti.riv",
                    onInit: _onConfettiRiveInit,
                    fit: BoxFit.cover,
                  ),
                )
              : const SizedBox(),
        ],
      ),
    );
  }
}

class CustomPositioned extends StatelessWidget {
  const CustomPositioned({super.key, this.scale = 1, required this.child});

  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Column(
        children: [
          const Spacer(),
          SizedBox(
            height: 100,
            width: 100,
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}