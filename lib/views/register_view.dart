import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'login_view.dart'
    show AppPasswordField, AppPrimaryButton, AppTextField, Validators;

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Consumer<AuthViewModel>(
                  builder: (context, authVM, _) {
                    return Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          const Text(
                            'Criar sua conta',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Preencha os dados abaixo para criar sua conta',
                            style: TextStyle(
                              fontSize: 15,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 32),
                          AppTextField(
                            controller: authVM.nameController,
                            hint: 'Nome completo',
                            prefixIcon: Icons.person_outline_rounded,
                            validator: Validators.requiredText,
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: authVM.emailController,
                            hint: 'E-mail',
                            prefixIcon: Icons.email_outlined,
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
                          const SizedBox(height: 16),
                          AppPasswordField(
                            controller: authVM.confirmPasswordController,
                            hint: 'Confirmar senha',
                            visible: authVM.confirmPasswordVisible,
                            onToggle: authVM.toggleConfirmPasswordVisibility,
                            validator: (value) {
                              final error = Validators.password(value);
                              if (error != null) return error;
                              if (value!.trim() !=
                                  authVM.passwordController.text.trim()) {
                                return 'As senhas não conferem.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: authVM.acceptTerms,
                                  onChanged: (_) => authVM.toggleAcceptTerms(),
                                  activeColor: AppColors.primaryGreen,
                                  side: const BorderSide(
                                    color: AppColors.borderColor,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Aceito os termos de uso e a política de privacidade',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (authVM.errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              authVM.errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                              ),
                            ),
                          ],
                          const SizedBox(height: 28),
                          AppPrimaryButton(
                            label: 'Criar Conta',
                            isLoading: authVM.isLoading,
                            onPressed: () async {
                              if (!_formKey.currentState!.validate()) return;
                              if (!authVM.acceptTerms) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Aceite os termos para continuar.',
                                    ),
                                  ),
                                );
                                return;
                              }

                              final success = await authVM.register();
                              if (!context.mounted) return;

                              if (success) {
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/loading',
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 28),
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Já possui conta? ',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: const Text(
                                    'Entrar',
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
                          const SizedBox(height: 32),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
