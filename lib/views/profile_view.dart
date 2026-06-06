import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/finance_viewmodel.dart';
import '../viewmodels/theme_viewmodel.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  void _showEditProfileSheet(AuthViewModel authVM) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: authVM.userFullName);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: AppColors.surface(sheetContext),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border(sheetContext),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Editar perfil',
                    style: TextStyle(
                      color: AppColors.primaryText(sheetContext),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe seu nome.';
                      }
                      if (value.trim().length < 3) {
                        return 'Informe pelo menos 3 caracteres.';
                      }
                      return null;
                    },
                    style:
                        TextStyle(color: AppColors.primaryText(sheetContext)),
                    decoration: _profileInputDecoration(
                      sheetContext,
                      hint: 'Nome completo',
                      icon: Icons.person_outline_rounded,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: authVM.userEmail,
                    readOnly: true,
                    style:
                        TextStyle(color: AppColors.secondaryText(sheetContext)),
                    decoration: _profileInputDecoration(
                      sheetContext,
                      hint: 'E-mail',
                      icon: Icons.email_outlined,
                    ).copyWith(
                      helperText:
                          'O e-mail de login é gerenciado pelo Supabase.',
                      helperStyle: TextStyle(
                        color: AppColors.secondaryText(sheetContext),
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(sheetContext);
                        final saved = await context
                            .read<AuthViewModel>()
                            .updateProfileName(nameController.text);
                        if (saved && sheetContext.mounted) {
                          navigator.pop();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Perfil atualizado.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Salvar alterações',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).whenComplete(nameController.dispose);
  }

  InputDecoration _profileInputDecoration(
    BuildContext context, {
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.secondaryText(context)),
      prefixIcon: Icon(icon, color: AppColors.mutedIcon(context), size: 20),
      filled: true,
      fillColor: AppColors.field(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.border(context)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.border(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authVM, _) {
        return Column(
          children: [
            _ProfileHeader(
              authVM: authVM,
              onEdit: () => _showEditProfileSheet(authVM),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _ProfileAvatar(authVM: authVM),
                    const SizedBox(height: 16),
                    Text(
                      authVM.userFullName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      authVM.userEmail,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.secondaryText(context),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _InfoCard(),
                    const SizedBox(height: 16),
                    _ThemeToggleCard(),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () => _showEditProfileSheet(authVM),
                        icon: const Icon(Icons.edit_outlined,
                            color: AppColors.primaryGreen, size: 18),
                        label: const Text(
                          'Editar Perfil',
                          style: TextStyle(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: AppColors.primaryGreen, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: TextButton.icon(
                        onPressed: () {
                          context.read<FinanceViewModel>().clear();
                          authVM.logout();
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        icon: const Icon(Icons.logout_rounded,
                            color: AppColors.expense, size: 18),
                        label: const Text(
                          'Sair da conta',
                          style: TextStyle(
                            color: AppColors.expense,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final AuthViewModel authVM;
  final VoidCallback onEdit;

  const _ProfileHeader({required this.authVM, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface(context),
      child: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Meu Perfil',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit_outlined,
                      color: AppColors.mutedIcon(context)),
                  onPressed: onEdit,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.border(context)),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final AuthViewModel authVM;

  const _ProfileAvatar({required this.authVM});

  @override
  Widget build(BuildContext context) {
    final bytes = authVM.profileImageBytes;

    return GestureDetector(
      onTap: () async {
        final picker = ImagePicker();
        final xfile = await picker.pickImage(source: ImageSource.gallery);
        if (xfile != null) {
          final imageBytes = await xfile.readAsBytes();
          await authVM.setProfileImage(imageBytes);
        }
      },
      child: Stack(
        children: [
          bytes != null
              ? ClipOval(
                  child: Image.memory(
                    bytes,
                    width: 104,
                    height: 104,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                  ),
                )
              : CircleAvatar(
                  radius: 52,
                  backgroundColor:
                      AppColors.primaryGreen.withValues(alpha: 0.15),
                  child: Text(
                    authVM.userFullName.isNotEmpty
                        ? authVM.userFullName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.camera_alt_rounded,
                  color: Colors.white, size: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeToggleCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeViewModel>(
      builder: (context, themeVM, _) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.elevatedSurface(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.field(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    themeVM.isDark
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                    color: AppColors.mutedIcon(context),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tema Escuro',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primaryText(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Switch(
                  value: themeVM.isDark,
                  activeThumbColor: AppColors.primaryGreen,
                  onChanged: (_) => context.read<ThemeViewModel>().toggle(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.elevatedSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: const Column(
        children: [
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Conta criada em',
            value: '15 de Janeiro de 2024',
          ),
          Divider(height: 1, indent: 52, color: AppColors.borderColor),
          _InfoRow(
            icon: Icons.workspace_premium_outlined,
            label: 'Plano atual',
            value: 'Premium',
            valueColor: AppColors.primaryGreen,
          ),
          Divider(height: 1, indent: 52, color: AppColors.borderColor),
          _InfoRow(
            icon: Icons.flag_outlined,
            label: 'Objetivo financeiro',
            value: 'Comprar minha casa',
          ),
          Divider(height: 1, indent: 52, color: AppColors.borderColor),
          _InfoRow(
            icon: Icons.savings_outlined,
            label: 'Total economizado',
            value: 'R\$ 8.790,00',
            valueColor: AppColors.income,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.field(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.mutedIcon(context), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.secondaryText(context),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.primaryText(context),
            ),
          ),
        ],
      ),
    );
  }
}
