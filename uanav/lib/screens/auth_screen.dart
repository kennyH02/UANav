import 'package:flutter/material.dart';

enum _AuthMode { signIn, createAccount }

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    required this.onSignIn,
    required this.onCreateAccount,
    required this.onContinueAsGuest,
    super.key,
  });

  final Future<void> Function(String email, String password) onSignIn;
  final Future<void> Function(String displayName, String email, String password)
  onCreateAccount;
  final Future<void> Function() onContinueAsGuest;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static const _purple = Color(0xFF46166B);
  static const _gold = Color(0xFFEAAA00);

  final _formKey = GlobalKey<FormState>();

  // Controllers to read the text typed into the text fields.
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  _AuthMode _mode = _AuthMode.signIn;
  String? _errorMessage;
  String? _successMessage;
  bool _busy = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // ALWAYS dispose controllers to prevent memory leaks when the widget is destroyed.
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCreating = (_mode == _AuthMode.createAccount) ? true : false;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F1E8),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(18),
                color: Colors.white,
                shadowColor: Colors.black26,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(isCreating),
                        const SizedBox(height: 18),
                        // Toggle switch
                        SegmentedButton<_AuthMode>(
                          segments: const [
                            ButtonSegment(
                              value: _AuthMode.signIn,
                              label: Text('Sign in'),
                              icon: Icon(Icons.login),
                            ),
                            ButtonSegment(
                              value: _AuthMode.createAccount,
                              label: Text('Create'),
                              icon: Icon(Icons.person_add),
                            ),
                          ],
                          selected: {_mode},
                          onSelectionChanged: _busy
                              ? null
                              : (selection) {
                                  setState(() {
                                    _mode = selection.first;
                                    _errorMessage = null;
                                    _successMessage = null;
                                  });
                                },
                        ),
                        const SizedBox(height: 18),

                        // --- Form Fields ---
                        // - Name field (only for account creation) -
                        if (isCreating) ...[
                          TextFormField(
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Display name',
                              prefixIcon: Icon(Icons.badge_outlined),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (!isCreating) {
                                return null;
                              }
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter a display name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                        // - Email field - Shown on both modes
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.mail_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 12),
                        // - Password field - Shown on both modes
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: isCreating
                              ? TextInputAction.next
                              : TextInputAction.done,
                          onFieldSubmitted: (_) =>
                              isCreating ? null : _submit(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? 'Show password'
                                  : 'Hide password',
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: _validatePassword,
                        ),
                        // - Confirm password field (only for account creation) -
                        if (isCreating) ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: 'Confirm password',
                              prefixIcon: const Icon(Icons.lock_reset),
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                tooltip: _obscureConfirmPassword
                                    ? 'Show password'
                                    : 'Hide password',
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            ),
                            validator: _validateConfirmPassword,
                          ),
                        ],
                        // - Conditionally render error or success banners -
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          _MessageBanner(
                            icon: Icons.error_outline,
                            message: _errorMessage!,
                            color: Colors.red.shade700,
                          ),
                        ],
                        if (_successMessage != null) ...[
                          const SizedBox(height: 12),
                          _MessageBanner(
                            icon: Icons.mark_email_read_outlined,
                            message: _successMessage!,
                            color: Colors.green.shade700,
                          ),
                        ],
                        const SizedBox(height: 18),
                        // --- Action Buttons ---
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: _purple,
                            minimumSize: const Size.fromHeight(50),
                          ),
                          icon: _busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  isCreating ? Icons.person_add : Icons.login,
                                ),
                          label: Text(
                            isCreating ? 'Create account' : 'Sign in',
                          ),
                          onPressed: _busy ? null : _submit,
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _purple,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('Continue as guest'),
                          onPressed: _busy ? null : _continueAsGuest,
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
    );
  }

  // Helper widget to build the Logo and Title at the top of the card
  Widget _buildHeader(bool isCreating) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: _purple,
            shape: BoxShape.circle,
          ),
          child: const Text(
            'UA',
            style: TextStyle(
              color: _gold,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'UANav',
                style: TextStyle(
                  color: _purple,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                isCreating ? 'Create your account' : 'Welcome back',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Logic Methods ---

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      return;
    }

    setState(() {
      _busy = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      if (_mode == _AuthMode.signIn) {
        await widget.onSignIn(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        await widget.onCreateAccount(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
        );

        // If account creation succeeds, gracefully switch back to Sign In mode
        if (mounted) {
          setState(() {
            _mode = _AuthMode.signIn;
            _passwordController.clear();
            _confirmPasswordController.clear();
            _successMessage =
                'Check your email to verify the account, then sign in.';
          });
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = _friendlyError(error));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _continueAsGuest() async {
    setState(() {
      _busy = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await widget.onContinueAsGuest();
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = _friendlyError(error));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  // --- Validators ---

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    // Basic regex to ensure the email is in a valid format (contains '@' and a domain)
    final valid = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
    if (!valid) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.length < 6) {
      return 'Use at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (_mode != _AuthMode.createAccount) {
      return null;
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  String _friendlyError(Object error) {
    final message = error.toString().replaceFirst(
      'AuthException(message: ',
      '',
    );
    if (message.contains('Invalid login credentials')) {
      return 'Invalid email or password';
    }
    if (message.contains('User already registered')) {
      return 'An account already exists for this email';
    }
    if (message.contains('AuthRetryableFetchException') ||
        message.contains('SocketException') ||
        message.contains('Failed host lookup')) {
      return 'Can\'t reach the login server. Check your internet connection and try again.';
    }
    if (message.length > 120) {
      return 'Something went wrong. Please try again.';
    }
    return message.replaceAll(RegExp(r', statusCode:.*\)$'), '');
  }
}

// A stateless widget for rendering consistent error and success boxes
class _MessageBanner extends StatelessWidget {
  const _MessageBanner({
    required this.icon,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
