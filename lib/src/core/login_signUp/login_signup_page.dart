import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_ui_plugin/web_ui_plugin.dart';

/// Style options for the Login & Signup screen.
enum LoginSignUpStyle {
  /// A classic, centered form card with minimal styling.
  normalForm,

  /// A highly animated card featuring backdrop blur, fading/sliding transitions, and floating background decorative bubbles.
  animated,

  /// A modern responsive split-screen layout with a beautiful gradient banner.
  commonUi,
}

/// Callback type for login form submission.
/// Returns the authenticated [UserIdentity] on success, or throws an error on failure.
typedef LoginCallback =
    Future<UserIdentity> Function(
      String username,
      String password,
    );

/// Callback type for signup form submission.
/// Returns the created [UserIdentity] on success, or throws an error on failure.
typedef SignUpCallback =
    Future<UserIdentity> Function(
      String username,
      String password,
    );

/// A highly aesthetic, responsive, and plug-and-play Login & Signup screen.
///
/// It supports:
/// - Three visual styles: [LoginSignUpStyle.normalForm], [LoginSignUpStyle.animated], and [LoginSignUpStyle.commonUi].
/// - Responsive layout (Split-screen on desktop/tablet for `commonUi`).
/// - Switchable modes (Login / Sign Up) with smooth animated transitions.
/// - Full validation for username/email, password, and confirm password.
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

  /// Path to redirect to on successful authentication. Defaults to `/`.
  final String redirectPath;

  /// The visual style of the login page.
  final LoginSignUpStyle style;

  const LoginSignUpPage({
    super.key,
    required this.onLogin,
    required this.onSignUp,
    this.logo,
    this.brandName = 'SaaS Admin',
    this.brandTagline =
        'The ultimate plug-and-play solution for modern applications.',
    this.redirectPath = '/',
    this.style = LoginSignUpStyle.commonUi,
  });

  @override
  State<LoginSignUpPage> createState() => _LoginSignUpPageState();
}

class _LoginSignUpPageState extends State<LoginSignUpPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSignUpMode = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _bgAnimationController;

  @override
  void initState() {
    super.initState();
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _bgAnimationController.dispose();
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

    if (_isSignUpMode &&
        _passwordController.text != _confirmPasswordController.text) {
      CustomSnackBar.show(
        context,
        'Passwords do not match',
        category: SnackBarCategory.failure,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserIdentity user;
      if (_isSignUpMode) {
        user = await widget.onSignUp(
          _usernameController.text.trim(),
          _passwordController.text,
        );
      } else {
        user = await widget.onLogin(
          _usernameController.text.trim(),
          _passwordController.text,
        );
      }

      // Update the active permission identity
      PermissionMiddleware.instance.setUser(user);

      if (mounted) {
        CustomSnackBar.show(
          context,
          _isSignUpMode
              ? 'Account created successfully!'
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
    switch (widget.style) {
      case LoginSignUpStyle.normalForm:
        return _buildNormalFormStyle(context);
      case LoginSignUpStyle.animated:
        return _buildAnimatedStyle(context);
      case LoginSignUpStyle.commonUi:
        return _buildCommonUiStyle(context);
    }
  }

  // ── 1. Normal Form Style ──────────────────────────────────────────────────
  Widget _buildNormalFormStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121214) : const Color(0xFFF9FAFB),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E24) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isDark
                        ? const Color(0xFF2E2E38)
                        : const Color(0xFFE5E7EB),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child:
                        widget.logo ??
                        Icon(
                          FontAwesomeIcons.cubes,
                          color: Theme.of(context).colorScheme.primary,
                          size: 32,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.brandName,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      textStyle: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _isSignUpMode ? 'Create Account' : 'Sign In',
                    style: GoogleFonts.outfit(
                      textStyle: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFormFields(isDark),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: _isSignUpMode ? 'Register' : 'Sign In',
                    onPressed: _submit,
                    buttonState:
                        _isLoading ? ButtonState.working : ButtonState.enabled,
                    height: 44,
                    borderRadius: 6,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isSignUpMode
                            ? 'Already have an account? '
                            : "Don't have an account? ",
                        style: TextStyle(
                          color:
                              isDark ? Colors.grey[400] : const Color(
                                0xFF64748B,
                              ),
                          fontSize: 13,
                        ),
                      ),
                      TextButton(
                        onPressed: _toggleMode,
                        child: Text(
                          _isSignUpMode ? 'Sign In' : 'Sign Up',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── 2. Animated Style ─────────────────────────────────────────────────────
  Widget _buildAnimatedStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0A0C) : const Color(0xFFF3F4F6),
      body: Stack(
        children: [
          // Background floating bubbles
          _buildAnimatedBackground(isDark),

          // Form card
          Center(
            child: SingleChildScrollView(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: 420,
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(36),
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? Colors.black.withOpacity(0.5)
                              : Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color:
                            isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.white.withOpacity(0.4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.0, 0.1),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutBack,
                                  ),
                                ),
                                child: child,
                              ),
                            );
                          },
                          child: Column(
                            key: ValueKey<bool>(_isSignUpMode),
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child:
                                    widget.logo ??
                                    Icon(
                                      FontAwesomeIcons.cubes,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                      size: 40,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                widget.brandName,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  textStyle: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDark
                                            ? Colors.white
                                            : const Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              Text(
                                _isSignUpMode ? 'Create Account' : 'Sign In',
                                style: GoogleFonts.outfit(
                                  textStyle: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDark
                                            ? Colors.white
                                            : const Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isSignUpMode
                                    ? 'Get started by creating your user profile.'
                                    : 'Welcome back! Please enter your details.',
                                style: TextStyle(
                                  color:
                                      isDark
                                          ? Colors.grey[400]
                                          : const Color(0xFF64748B),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildFormFields(isDark),
                              const SizedBox(height: 28),
                              CustomButton(
                                text: _isSignUpMode ? 'Sign Up' : 'Log In',
                                onPressed: _submit,
                                buttonState:
                                    _isLoading
                                        ? ButtonState.working
                                        : ButtonState.enabled,
                                height: 46,
                                borderRadius: 12,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _isSignUpMode
                                        ? 'Already have an account? '
                                        : "Don't have an account? ",
                                    style: TextStyle(
                                      color:
                                          isDark
                                              ? Colors.grey[400]
                                              : const Color(0xFF64748B),
                                      fontSize: 13,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _toggleMode,
                                    child: Text(
                                      _isSignUpMode ? 'Sign In' : 'Sign Up',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground(bool isDark) {
    return AnimatedBuilder(
      animation: _bgAnimationController,
      builder: (context, child) {
        final val = _bgAnimationController.value;
        return Stack(
          children: [
            // Bubble 1
            Positioned(
              top: 100 + 60 * math.sin(val * math.pi * 2),
              left: 100 + 40 * math.cos(val * math.pi * 2),
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      isDark
                          ? const Color(0xFF6366F1).withOpacity(0.12)
                          : const Color(0xFF6366F1).withOpacity(0.20),
                ),
              ),
            ),
            // Bubble 2
            Positioned(
              bottom: 120 + 70 * math.sin(val * math.pi * 2 + 1),
              right: 80 + 50 * math.cos(val * math.pi * 2 + 1),
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      isDark
                          ? const Color(0xFFEC4899).withOpacity(0.12)
                          : const Color(0xFFEC4899).withOpacity(0.20),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── 3. Common UI (Split Screen) Style ─────────────────────────────────────
  Widget _buildCommonUiStyle(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool useSplitScreen = size.width > AppTheme.breakpointWide;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F12) : const Color(0xFFF3F4F6),
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
            child:
                useSplitScreen
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
          colors:
              isDark
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
                          color:
                              isDark ? Colors.white : const Color(0xFF1E293B),
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

            _buildFormFields(isDark),

            const SizedBox(height: 32),

            // Submit Button
            CustomButton(
              text: _isSignUpMode ? 'Register Account' : 'Sign In',
              onPressed: _submit,
              buttonState:
                  _isLoading ? ButtonState.working : ButtonState.enabled,
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

  // ── 4. Common Form Fields ────────────────────────────────────────────────
  Widget _buildFormFields(bool isDark) {
    return Column(
      children: [
        CustomTextField(
          textController: _usernameController,
          labelText: 'Username or Email',
          icon: FontAwesomeIcons.solidUser,
          mandatory: true,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Please enter your username or email';
            }
            if (val.trim().length < 3) {
              return 'Username or email must be at least 3 characters';
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
        if (_isSignUpMode) ...[
          const SizedBox(height: 16),
          CustomTextField(
            textController: _confirmPasswordController,
            labelText: 'Confirm Password',
            icon: FontAwesomeIcons.lock,
            mandatory: true,
            isPassword: _obscurePassword,
            validator: (val) {
              if (val == null || val.isEmpty) {
                return 'Please confirm your password';
              }
              if (val != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }
}
