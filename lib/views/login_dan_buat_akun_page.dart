import 'package:flutter/material.dart';

import 'halaman_awal.dart';
import 'project_seleksi.dart';
import '../services/api_client.dart';
import '../services/app_session.dart';

class LoginDanBuatAkunPage extends StatefulWidget {
  const LoginDanBuatAkunPage({super.key});

  static const routeName = '/login';

  @override
  State<LoginDanBuatAkunPage> createState() => _LoginDanBuatAkunPageState();
}

class _LoginDanBuatAkunPageState extends State<LoginDanBuatAkunPage> {
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _registerNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _registerConfirmPasswordController = TextEditingController();
  bool _showRegister = false;
  bool _loading = false;

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _passwordController.dispose();
    _registerConfirmPasswordController.dispose();
    super.dispose();
  }

  void _setMode(bool register) {
    setState(() => _showRegister = register);
  }

  Future<void> _login() async {
    if (!(_loginFormKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _loading = true);
    try {
      final auth = await ApiServices.instance.login(
        email: _loginEmailController.text.trim(),
        password: _loginPasswordController.text,
      );
      AppSession.userName = auth.name.trim().isEmpty
          ? 'User'
          : auth.name.trim();
      AppSession.userEmail = auth.email.trim().isEmpty
          ? '-'
          : auth.email.trim();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacementNamed(ProjectSeleksiPage.routeName);
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Tidak bisa terhubung ke Django API.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _register() async {
    if (!(_registerFormKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _loading = true);
    try {
      await ApiServices.instance.register(
        name: _registerNameController.text.trim(),
        email: _registerEmailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) {
        return;
      }
      _showMessage('Registrasi berhasil! Silakan login.');
      _setMode(false);
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Tidak bisa terhubung ke Django API.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF172554), Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const _AuthHeader(),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 390),
                      child: _AuthCard(
                        showRegister: _showRegister,
                        loginFormKey: _loginFormKey,
                        registerFormKey: _registerFormKey,
                        loginEmailController: _loginEmailController,
                        loginPasswordController: _loginPasswordController,
                        registerNameController: _registerNameController,
                        registerEmailController: _registerEmailController,
                        passwordController: _passwordController,
                        registerConfirmPasswordController:
                            _registerConfirmPasswordController,
                        loading: _loading,
                        onSelectLogin: () => _setMode(false),
                        onSelectRegister: () => _setMode(true),
                        onLogin: _login,
                        onRegister: _register,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthHeader extends StatelessWidget {
  const _AuthHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0x73172554),
        border: Border(bottom: BorderSide(color: Color(0x1AFFFFFF))),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(HalamanAwal.routeName, (route) => false);
          },
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFDBEAFE),
            padding: EdgeInsets.zero,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
          icon: const Icon(Icons.arrow_back, size: 20),
          label: const Text('Kembali ke Beranda'),
        ),
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required this.showRegister,
    required this.loginFormKey,
    required this.registerFormKey,
    required this.loginEmailController,
    required this.loginPasswordController,
    required this.registerNameController,
    required this.registerEmailController,
    required this.passwordController,
    required this.registerConfirmPasswordController,
    required this.loading,
    required this.onSelectLogin,
    required this.onSelectRegister,
    required this.onLogin,
    required this.onRegister,
  });

  final bool showRegister;
  final GlobalKey<FormState> loginFormKey;
  final GlobalKey<FormState> registerFormKey;
  final TextEditingController loginEmailController;
  final TextEditingController loginPasswordController;
  final TextEditingController registerNameController;
  final TextEditingController registerEmailController;
  final TextEditingController passwordController;
  final TextEditingController registerConfirmPasswordController;
  final bool loading;
  final VoidCallback onSelectLogin;
  final VoidCallback onSelectRegister;
  final VoidCallback onLogin;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2E1E293B),
            blurRadius: 28,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AuthTabs(
            showRegister: showRegister,
            onSelectLogin: onSelectLogin,
            onSelectRegister: onSelectRegister,
          ),
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: showRegister
                ? _RegisterForm(
                    key: const ValueKey('registerForm'),
                    formKey: registerFormKey,
                    nameController: registerNameController,
                    emailController: registerEmailController,
                    passwordController: passwordController,
                    confirmPasswordController:
                        registerConfirmPasswordController,
                    loading: loading,
                    onLoginTap: onSelectLogin,
                    onSubmit: onRegister,
                  )
                : _LoginForm(
                    key: const ValueKey('loginForm'),
                    formKey: loginFormKey,
                    emailController: loginEmailController,
                    passwordController: loginPasswordController,
                    loading: loading,
                    onRegisterTap: onSelectRegister,
                    onSubmit: onLogin,
                  ),
          ),
        ],
      ),
    );
  }
}

class _AuthTabs extends StatelessWidget {
  const _AuthTabs({
    required this.showRegister,
    required this.onSelectLogin,
    required this.onSelectRegister,
  });

  final bool showRegister;
  final VoidCallback onSelectLogin;
  final VoidCallback onSelectRegister;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: 'Login',
              active: !showRegister,
              onTap: onSelectLogin,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _TabButton(
              label: 'Buat Akun',
              active: showRegister,
              onTap: onSelectRegister,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: active ? const Color(0xFF2563EB) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: active
            ? const [
                BoxShadow(
                  color: Color(0x402563EB),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: active ? Colors.white : const Color(0xFF1D4ED8),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        child: Text(label),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.loading,
    required this.onRegisterTap,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool loading;
  final VoidCallback onRegisterTap;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FormTitle(
            title: 'Login',
            subtitle: 'Masuk ke akun Anda untuk melanjutkan monitoring.',
          ),
          const SizedBox(height: 16),
          _AuthTextField(
            label: 'Email',
            hint: 'Masukkan email',
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          _AuthTextField(
            label: 'Password',
            hint: 'Masukkan password',
            controller: passwordController,
            obscureText: true,
          ),
          const SizedBox(height: 12),
          _PrimaryButton(
            label: 'Masuk',
            loading: loading,
            onPressed: loading ? null : onSubmit,
          ),
          const SizedBox(height: 12),
          _SwitchText(
            text: 'Belum punya akun?',
            action: 'Buat akun di sini',
            onTap: onRegisterTap,
          ),
        ],
      ),
    );
  }
}

class _RegisterForm extends StatelessWidget {
  const _RegisterForm({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.loading,
    required this.onLoginTap,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool loading;
  final VoidCallback onLoginTap;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FormTitle(
            title: 'Buat Akun',
            subtitle: 'Daftarkan akun baru untuk mulai menggunakan platform.',
          ),
          const SizedBox(height: 16),
          _AuthTextField(
            label: 'Nama Lengkap',
            hint: 'Masukkan nama lengkap',
            controller: nameController,
          ),
          const SizedBox(height: 12),
          _AuthTextField(
            label: 'Email',
            hint: 'Masukkan email',
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          _AuthTextField(
            label: 'Password',
            hint: 'Buat password',
            obscureText: true,
            controller: passwordController,
          ),
          const SizedBox(height: 12),
          _AuthTextField(
            label: 'Konfirmasi Password',
            hint: 'Ulangi password',
            obscureText: true,
            controller: confirmPasswordController,
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) {
                return 'Kolom ini wajib diisi';
              }
              if (text != passwordController.text.trim()) {
                return 'Password tidak cocok';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          _PrimaryButton(
            label: 'Buat Akun',
            loading: loading,
            onPressed: loading ? null : onSubmit,
          ),
          const SizedBox(height: 12),
          _SwitchText(
            text: 'Sudah punya akun?',
            action: 'Login di sini',
            onTap: onLoginTap,
          ),
        ],
      ),
    );
  }
}

class _FormTitle extends StatelessWidget {
  const _FormTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF172554),
            fontSize: 23,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF1E40AF),
            fontSize: 13,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.label,
    required this.hint,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
  });

  final String label;
  final String hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF172554),
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator ?? _defaultValidator,
          style: const TextStyle(color: Color(0xFF1E293B)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF2563EB),
                width: 1.4,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
          ),
        ),
      ],
    );
  }

  String? _defaultValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Kolom ini wajib diisi';
    }
    if (keyboardType == TextInputType.emailAddress && !text.contains('@')) {
      return 'Email tidak valid';
    }
    return null;
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}

class _SwitchText extends StatelessWidget {
  const _SwitchText({
    required this.text,
    required this.action,
    required this.onTap,
  });

  final String text;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 5,
      children: [
        Text(
          text,
          style: const TextStyle(color: Color(0xFF1E40AF), fontSize: 13),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF2563EB),
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 34),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
          child: Text(action),
        ),
      ],
    );
  }
}
