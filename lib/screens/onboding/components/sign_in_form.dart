import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart';
import 'package:rive_animation/screens/entryPoint/entry_point.dart';
import 'package:rive_animation/services/user_service.dart';
import 'package:rive_animation/services/supabase_service.dart';

class SignInForm extends StatefulWidget {
  const SignInForm({
    super.key,
  });

  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  String? _selectedGrade;
  String _selectedRole = 'student';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
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

  void singIn(BuildContext context) {
    setState(() {
      isShowConfetti = true;
      isShowLoading = true;
    });
    Future.delayed(
      const Duration(seconds: 1),
      () async {
        if (_formKey.currentState!.validate() && (_selectedRole == 'teacher' || _selectedGrade != null)) {
          try {
            // Create account with Supabase
            final supabaseService = SupabaseService.instance;
            await supabaseService.signUp(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              fullName: _nameController.text.trim(),
              grade: _selectedRole == 'student' ? _selectedGrade! : 'N/A',
              role: _selectedRole,
              subjectSpecialization: _selectedRole == 'teacher' ? _subjectController.text.trim() : null,
            );
            
            // Save user data to local state
            if (context.mounted) {
              final userService = Provider.of<UserService>(context, listen: false);
            // Save user data to local state
              userService.setUser(
                fullName: _nameController.text.trim(),
                grade: _selectedRole == 'student' ? _selectedGrade! : 'N/A',
                email: _emailController.text.trim(),
                role: _selectedRole,
                subjectSpecialization: _selectedRole == 'teacher' ? _subjectController.text.trim() : null,
              );
            }

            success.fire();
            Future.delayed(
              const Duration(seconds: 2),
              () {
                if (mounted) {
                  setState(() {
                    isShowLoading = false;
                  });
                }
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
          } catch (e) {
            // Handle signup error
            error.fire();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Account creation failed: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            if (mounted) {
              setState(() {
                isShowLoading = false;
              });
            }
            reset.fire();
          }
        } else {
          error.fire();
          Future.delayed(
            const Duration(seconds: 2),
            () {
              if (mounted) {
                setState(() {
                  isShowLoading = false;
                });
              }
              reset.fire();
            },
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Full Name",
                style: TextStyle(
                  color: Colors.black54,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                child: TextFormField(
                  controller: _nameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "";
                    }
                    return null;
                  },
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: SvgPicture.asset("assets/icons/User.svg"),
                    ),
                    hintText: "Enter your full name",
                  ),
                ),
              ),
              const Text(
                "Role",
                style: TextStyle(
                  color: Colors.black54,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                child: DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    prefixIcon: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.person, color: Colors.black54),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: "student", child: Text("Student")),
                    DropdownMenuItem(value: "teacher", child: Text("Teacher")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value!;
                      if (_selectedRole == 'teacher') {
                        _selectedGrade = null;
                      }
                    });
                  },
                ),
              ),
              if (_selectedRole == 'student') ...[
                const Text(
                  "Grade",
                  style: TextStyle(
                    color: Colors.black54,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  child: DropdownButtonFormField<String>(
                    value: _selectedGrade,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "";
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      prefixIcon: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.school, color: Colors.black54),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: "10", child: Text("Grade 10")),
                      DropdownMenuItem(value: "11", child: Text("Grade 11")),
                      DropdownMenuItem(value: "12", child: Text("Grade 12")),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedGrade = value;
                      });
                    },
                    hint: const Text("Select your grade"),
                  ),
                ),
              ],
              if (_selectedRole == 'teacher') ...[
                const Text(
                  "Subject Specialization",
                  style: TextStyle(
                    color: Colors.black54,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  child: TextFormField(
                    controller: _subjectController,
                    validator: (value) {
                      if (_selectedRole == 'teacher' && (value == null || value.trim().isEmpty)) {
                        return "";
                      }
                      return null;
                    },
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      prefixIcon: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: SvgPicture.asset("assets/icons/User.svg"),
                      ),
                      hintText: "e.g., Mathematics, Physics",
                    ),
                  ),
                ),
              ],
              const Text(
                "Password",
                style: TextStyle(
                  color: Colors.black54,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return "";
                    }
                    return null;
                  },
                  keyboardType: TextInputType.visiblePassword,
                  textInputAction: TextInputAction.next,
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
                    hintText: "Enter your password (min 6 characters)",
                  ),
                ),
              ),
              const Text(
                "Confirm Password",
                style: TextStyle(
                  color: Colors.black54,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                child: TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return "";
                    }
                    return null;
                  },
                  keyboardType: TextInputType.visiblePassword,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    prefixIcon: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.lock_outline, color: Colors.black54),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.black54,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    hintText: "Confirm your password",
                  ),
                ),
              ),
              const Text(
                "Email",
                style: TextStyle(
                  color: Colors.black54,
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
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: SvgPicture.asset("assets/icons/email.svg"),
                    ),
                    hintText: "Enter your email address",
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 24),
                child: ElevatedButton.icon(
                  onPressed: () {
                    singIn(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF77D8E),
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
                    color: Color(0xFFFE0037),
                  ),
                  label: const Text("Create Account"),
                ),
              ),
            ],
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
