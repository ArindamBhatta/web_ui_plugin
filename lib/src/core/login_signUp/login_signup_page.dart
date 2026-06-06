import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_ui_plugin/web_ui_plugin.dart';

/// Callback type for login form submission.
/// Returns the authenticated [UserIdentity] on success, or throws an error on failure.
typedef LoginCallback =
    Future<UserIdentity> Function(String email, String password);

/// Callback type for signup form submission.
/// Returns the created [UserIdentity] on success, or throws an error on failure.
typedef SignUpCallback =
    Future<UserIdentity> Function(
      String email,
      String password,
      String name,
      String mobile,
      String persona,
    );

/// A highly aesthetic, responsive, and plug-and-play Login & Signup screen.
///
/// It supports:
/// - Responsive layout (Split-screen on desktop/tablet, elegant card on mobile).
/// - Modern gradient background and glassmorphism styling.
/// - Switchable modes (Login / Sign Up) with smooth animated transitions.
/// - Full validation for email, password, name, and phone.
/// - Dropdown role selection for signup.
/// - Customizable branding (Logo, Title, Tagline).
class LoginSignUpPage extends StatefulWidget {
  /// Callback executed when the login button is pressed.
  final LoginCallback onLogin;

  /// Callback executed when the signup button is pressed.
  final SignUpCallback onSignUp;

  /// Optional custom logo widget. If not provided, a default logo is rendered.
  final Widget? logo;

  /// The name of your application/brand.
  final String brandName;

  /// A catchy tagline shown in the split-screen banner.
  final String brandTagline;

  /// List of roles/personas selectable during signup.
  final List<String> availableRoles;

  /// Path to redirect to on successful authentication. Defaults to `/`.
  final String redirectPath;

  const LoginSignUpPage({
    super.key,
    required this.onLogin,
    required this.onSignUp,
    this.logo,
    this.brandName = 'SaaS Admin',
    this.brandTagline =
        'The ultimate plug-and-play solution for modern applications.',
    this.availableRoles = const ['admin', 'operator', 'manager'],
    this.redirectPath = '/',
  });

  @override
  State<LoginSignUpPage> createState() => _LoginSignUpPageState();
}

class _LoginSignUpPageState extends State<LoginSignUpPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();

  String? _selectedRole;
  bool _isSignUpMode = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    if (widget.availableRoles.isNotEmpty) {
      _selectedRole = widget.availableRoles.first;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isSignUpMode = !_isSignUpMode;
      _formKey.currentState?.reset();
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      UserIdentity user;
      if (_isSignUpMode) {
        user = await widget.onSignUp(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
          _mobileController.text.trim(),
          _selectedRole ?? 'operator',
        );
      } else {
        user = await widget.onLogin(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }

      // Update the active permission identity
      PermissionMiddleware.instance.setUser(user);

      if (mounted) {
        CustomSnackBar.show(
          context,
          _isSignUpMode
              ? 'Account created successfully! Welcoming ${user.persona} role.'
              : 'Logged in successfully! Welcome back.',
          category: SnackBarCategory.success,
        );
        // Navigate to the target page
        context.go(widget.redirectPath);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          e.toString().replaceAll('Exception: ', ''),
          category: SnackBarCategory.failure,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool useSplitScreen = size.width > AppTheme.breakpointWide;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F0F12)
          : const Color(0xFFF3F4F6),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(24),
            constraints: BoxConstraints(
              maxWidth: useSplitScreen ? 1000 : 460,
              minHeight: useSplitScreen ? 600 : 0,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E24) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.heavyShadow,
            ),
            clipBehavior: Clip.antiAlias,
            child: useSplitScreen
                ? Row(
                    children: [
                      // Left Banner Column
                      Expanded(child: _buildBannerSection(isDark)),
                      // Right Form Column
                      Expanded(child: _buildFormSection(context, isDark)),
                    ],
                  )
                : _buildFormSection(context, isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildBannerSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1F2937), const Color(0xFF111827)]
              : [const Color(0xFF4F46E5), const Color(0xFF3730A3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          widget.logo ??
              const Icon(FontAwesomeIcons.cubes, color: Colors.white, size: 48),
          const SizedBox(height: 32),
          Text(
            widget.brandName,
            style: GoogleFonts.outfit(
              textStyle: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.brandTagline,
            style: GoogleFonts.outfit(
              textStyle: const TextStyle(
                fontSize: 18,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 40),
          // Subtle indicator showing which step they are on
          Row(
            children: [
              _buildIndicatorDot(!_isSignUpMode),
              const SizedBox(width: 8),
              _buildIndicatorDot(_isSignUpMode),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorDot(bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white30,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildFormSection(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Mobile Branding header
            if (MediaQuery.of(context).size.width <=
                AppTheme.breakpointWide) ...[
              Center(
                child: Column(
                  children: [
                    widget.logo ??
                        Icon(
                          FontAwesomeIcons.cubes,
                          color: Theme.of(context).colorScheme.primary,
                          size: 36,
                        ),
                    const SizedBox(height: 12),
                    Text(
                      widget.brandName,
                      style: GoogleFonts.outfit(
                        textStyle: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],

            Text(
              _isSignUpMode ? 'Create Account' : 'Welcome Back',
              style: GoogleFonts.outfit(
                textStyle: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isSignUpMode
                  ? 'Sign up to register a new user administrative persona.'
                  : 'Sign in to access your dashboard and section plugins.',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),

            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: Column(
                children: [
                  if (_isSignUpMode) ...[
                    CustomTextField(
                      textController: _nameController,
                      labelText: 'Full Name',
                      icon: FontAwesomeIcons.solidUser,
                      mandatory: true,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      textController: _mobileController,
                      labelText: 'Mobile Number',
                      icon: FontAwesomeIcons.phone,
                      mandatory: true,
                      keyboardType: TextInputType.phone,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter your mobile number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Dropdown for Roles
                    DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
                      value: _selectedRole,
                      dropdownColor: isDark
                          ? const Color(0xFF1E1E24)
                          : Colors.white,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                      items: widget.availableRoles.map((role) {
                        return DropdownMenuItem<String>(
                          value: role,
                          child: Text(
                            role[0].toUpperCase() + role.substring(1),
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedRole = val);
                      },
                      decoration: InputDecoration(
                        labelText: 'Select Persona',
                        prefixIcon: const Icon(
                          FontAwesomeIcons.idCardClip,
                          size: 18,
                        ),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        border: const OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  CustomTextField(
                    textController: _emailController,
                    labelText: 'Email Address',
                    icon: FontAwesomeIcons.solidEnvelope,
                    mandatory: true,
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(val.trim())) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    textController: _passwordController,
                    labelText: 'Password',
                    icon: FontAwesomeIcons.lock,
                    mandatory: true,
                    isPassword: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? FontAwesomeIcons.solidEye
                            : FontAwesomeIcons.solidEyeSlash,
                        size: 16,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (val.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Submit Button
            CustomButton(
              text: _isSignUpMode ? 'Register Account' : 'Sign In',
              onPressed: _submit,
              buttonState: _isLoading
                  ? ButtonState.working
                  : ButtonState.enabled,
              height: 48,
              borderRadius: 8,
            ),

            const SizedBox(height: 24),

            // Toggle Mode Link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isSignUpMode
                      ? 'Already have an account? '
                      : "Don't have an account? ",
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                    fontSize: 14,
                  ),
                ),
                TextButton(
                  onPressed: _toggleMode,
                  child: Text(
                    _isSignUpMode ? 'Sign In' : 'Sign Up',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
