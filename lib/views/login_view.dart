import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Consumer<AuthViewModel>(
            builder: (context, authVM, _) {
              return Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),
                    const Center(
                      child: Column(
                        children: [
                          FinancyLogo(size: 68),
                          SizedBox(height: 10),
                          Text(
                            'Financy App',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),
                    const Text(
                      'Olá!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Text(
                      'Bem-vindo de volta!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Faça login para continuar',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 36),
                    AppTextField(
                      controller: authVM.emailController,
                      hint: 'E-mail',
                      prefixIcon: Icons.person_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 16),
                    AppPasswordField(
                      controller: authVM.passwordController,
                      hint: 'Senha',
                      visible: authVM.passwordVisible,
                      onToggle: authVM.togglePasswordVisibility,
                      validator: Validators.password,
                    ),
                    if (authVM.errorMessage != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        authVM.errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 24),
                    AppPrimaryButton(
                      label: 'Entrar',
                      isLoading: authVM.isLoading,
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) return;
                        final success = await authVM.login();
                        if (success && context.mounted) {
                          Navigator.pushReplacementNamed(context, '/loading');
                        }
                      },
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Não possui conta? ',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/register',
                            ),
                            child: const Text(
                              'Criar Conta',
                              style: TextStyle(
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class Validators {
  Validators._();

  static String? requiredText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obrigatório.';
    }
    return null;
  }

  static String? email(String? value) {
    final required = requiredText(value);
    if (required != null) return required;

    final email = value!.trim();
    final valid = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
    if (!valid) return 'Informe um e-mail válido.';
    return null;
  }

  static String? password(String? value) {
    final required = requiredText(value);
    if (required != null) return required;
    if (value!.trim().length < 6) {
      return 'A senha deve ter pelo menos 6 caracteres.';
    }
    return null;
  }

  static String? money(String? value) {
    final required = requiredText(value);
    if (required != null) return required;

    final amount = parseMoney(value);
    if (amount == null || amount <= 0) return 'Informe um valor válido.';
    return null;
  }

  static double? parseMoney(String? value) {
    if (value == null) return null;

    var normalized = value
        .trim()
        .replaceAll('R\$', '')
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[^\d,.]'), '');

    if (normalized.isEmpty) return null;

    if (normalized.contains(',')) {
      normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
    }

    return double.tryParse(normalized);
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      decoration: _inputDecoration(
        hint: hint,
        prefixIcon: prefixIcon,
      ),
    );
  }
}

class AppPasswordField extends StatelessWidget {
  const AppPasswordField({
    super.key,
    required this.controller,
    required this.hint,
    required this.visible,
    required this.onToggle,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final bool visible;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: !visible,
      validator: validator,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      decoration: _inputDecoration(
        hint: hint,
        prefixIcon: Icons.lock_outline_rounded,
        suffixIcon: IconButton(
          icon: Icon(
            visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: AppColors.textSecondary,
            size: 20,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}

class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

InputDecoration _inputDecoration({
  required String hint,
  required IconData prefixIcon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
    prefixIcon: Icon(prefixIcon, color: AppColors.textSecondary, size: 20),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: AppColors.lightBackground,
    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.borderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.expense),
    ),
  );
}
