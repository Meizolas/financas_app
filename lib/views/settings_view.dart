import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../viewmodels/theme_viewmodel.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _biometria = true;
  bool _autenticacaoDuasEtapas = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context),
        foregroundColor: AppColors.primaryText(context),
        elevation: 0,
        surfaceTintColor: AppColors.surface(context),
        title: Text(
          'Configurações',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText(context),
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primaryText(context),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border(context)),
        ),
      ),
      body: ListView(
        children: [
          const _SectionHeader(label: 'CONTA'),
          _SettingsTile(
            icon: Icons.email_outlined,
            label: 'Alterar e-mail',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.lock_outline_rounded,
            label: 'Alterar senha',
            onTap: () {},
          ),
          const _SectionHeader(label: 'SEGURANÇA'),
          _SettingsTileSwitch(
            icon: Icons.fingerprint_rounded,
            label: 'Biometria',
            value: _biometria,
            onChanged: (value) => setState(() => _biometria = value),
          ),
          _SettingsTile(
            icon: Icons.grid_view_rounded,
            label: 'PIN de acesso',
            onTap: () {},
          ),
          _SettingsTileSwitch(
            icon: Icons.verified_user_outlined,
            label: 'Autenticação em duas etapas',
            value: _autenticacaoDuasEtapas,
            onChanged: (value) =>
                setState(() => _autenticacaoDuasEtapas = value),
          ),
          const _SectionHeader(label: 'APARÊNCIA'),
          Consumer<ThemeViewModel>(
            builder: (context, themeVM, _) {
              return _SettingsTileSwitch(
                icon: themeVM.isDark
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
                label: 'Tema escuro',
                value: themeVM.isDark,
                onChanged: (_) => context.read<ThemeViewModel>().toggle(),
              );
            },
          ),
          const _SectionHeader(label: 'DADOS'),
          _SettingsTile(
            icon: Icons.cloud_upload_outlined,
            label: 'Backup e restauração',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.table_chart_outlined,
            label: 'Exportar dados (Excel)',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.picture_as_pdf_outlined,
            label: 'Exportar dados (PDF)',
            onTap: () {},
          ),
          const _SectionHeader(label: 'SOBRE'),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            label: 'Política de Privacidade',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.gavel_outlined,
            label: 'Termos de Uso',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            label: 'Sobre o Financy App',
            trailing: const Text(
              'v1.0.0',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            onTap: () {},
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.secondaryText(context),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface(context),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.mutedIcon(context), size: 22),
        title: Text(
          label,
          style: TextStyle(fontSize: 14, color: AppColors.primaryText(context)),
        ),
        trailing: trailing ??
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.mutedIcon(context),
              size: 20,
            ),
      ),
    );
  }
}

class _SettingsTileSwitch extends StatelessWidget {
  const _SettingsTileSwitch({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface(context),
      child: ListTile(
        leading: Icon(icon, color: AppColors.mutedIcon(context), size: 22),
        title: Text(
          label,
          style: TextStyle(fontSize: 14, color: AppColors.primaryText(context)),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primaryGreen,
          activeTrackColor: AppColors.primaryGreen.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}
