import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/user_repository.dart';
import '../models/user_model.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel({UserRepository? repository})
      : _repository = repository ?? UserRepository();

  final UserRepository _repository;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool _passwordVisible = false;
  bool get passwordVisible => _passwordVisible;

  bool _confirmPasswordVisible = false;
  bool get confirmPasswordVisible => _confirmPasswordVisible;

  bool _acceptTerms = false;
  bool get acceptTerms => _acceptTerms;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  int? get currentUserId => _currentUser?.id;

  Uint8List? _profileImageBytes;
  Uint8List? get profileImageBytes => _profileImageBytes;

  Future<void> setProfileImage(Uint8List bytes) async {
    _profileImageBytes = bytes;
    await _saveProfileImage(bytes);
    notifyListeners();
  }

  void togglePasswordVisibility() {
    _passwordVisible = !_passwordVisible;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    _confirmPasswordVisible = !_confirmPasswordVisible;
    notifyListeners();
  }

  void toggleAcceptTerms() {
    _acceptTerms = !_acceptTerms;
    notifyListeners();
  }

  Future<bool> login() async {
    _setLoading(true);
    _errorMessage = null;
    _successMessage = null;

    try {
      final user = await _repository.authenticate(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (user == null) {
        _errorMessage = 'E-mail ou senha incorretos.';
        return false;
      }

      _currentUser = user;
      await _loadProfileImageForCurrentUser();
      return true;
    } catch (error) {
      _errorMessage = _friendlyAuthError(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register() async {
    _setLoading(true);
    _errorMessage = null;
    _successMessage = null;

    try {
      final result = await _repository.register(
        UserModel(
          name: nameController.text.trim(),
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        ),
      );

      if (result.requiresEmailConfirmation) {
        _errorMessage =
            'A confirmação por e-mail ainda está ativa no Supabase. Desative Confirm email em Authentication > Providers > Email.';
        return false;
      }

      _currentUser = result.user;
      await _loadProfileImageForCurrentUser();
      return true;
    } catch (error) {
      _errorMessage = _friendlyAuthError(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> restoreCurrentSession() async {
    try {
      final user = await _repository.restoreAuthenticatedUser();
      if (user == null) return false;

      _currentUser = user;
      await _loadProfileImageForCurrentUser();
      _errorMessage = null;
      _successMessage = null;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  void logout() {
    _repository.signOut();
    _currentUser = null;
    emailController.clear();
    passwordController.clear();
    nameController.clear();
    confirmPasswordController.clear();
    _errorMessage = null;
    _successMessage = null;
    _passwordVisible = false;
    _confirmPasswordVisible = false;
    _acceptTerms = false;
    _profileImageBytes = null;
    notifyListeners();
  }

  String get userName {
    final name = _currentUser?.name ?? '';
    if (name.isEmpty) return 'Usuário';
    return name.split(' ').first;
  }

  String get userFullName => _currentUser?.name ?? 'Usuário';

  String get userEmail => _currentUser?.email ?? emailController.text.trim();

  Future<bool> updateProfileName(String name) async {
    final user = _currentUser;
    final cleanName = name.trim();
    if (user == null || cleanName.isEmpty) {
      _errorMessage = 'Informe um nome válido.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;
    _successMessage = null;

    try {
      _currentUser = await _repository.updateProfileName(
        user: user,
        name: cleanName,
      );
      _successMessage = 'Perfil atualizado com sucesso.';
      return true;
    } catch (_) {
      _errorMessage = 'Não foi possível atualizar o perfil agora.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  String? get _profileImageKey {
    final user = _currentUser;
    if (user == null) return null;
    final source = (user.supabaseId?.isNotEmpty ?? false)
        ? user.supabaseId!
        : user.email.toLowerCase();
    return 'profile_image_$source';
  }

  Future<void> _saveProfileImage(Uint8List bytes) async {
    final key = _profileImageKey;
    if (key == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, base64Encode(bytes));
  }

  Future<void> _loadProfileImageForCurrentUser() async {
    final key = _profileImageKey;
    if (key == null) {
      _profileImageBytes = null;
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(key);
    if (encoded == null || encoded.isEmpty) {
      _profileImageBytes = null;
      return;
    }

    try {
      _profileImageBytes = base64Decode(encoded);
    } catch (_) {
      _profileImageBytes = null;
      await prefs.remove(key);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _friendlyAuthMessage(String message) {
    final decodedMessage = _decodeAuthMessage(message);
    final normalized = decodedMessage.toLowerCase();
    if (normalized.contains('email not confirmed')) {
      return 'A confirmação por e-mail ainda está ativa no Supabase. Desative Confirm email em Authentication > Providers > Email.';
    }
    if (normalized.contains('email signups are disabled') ||
        normalized.contains('signup disabled') ||
        normalized.contains('signups are disabled')) {
      return 'Cadastros por e-mail estão desativados no Supabase. Ative o provider Email em Authentication > Providers > Email.';
    }
    if (normalized.contains('invalid login credentials')) {
      return 'E-mail ou senha incorretos.';
    }
    if (normalized.contains('senha informada') ||
        normalized.contains('não confere') ||
        normalized.contains('nao confere')) {
      return 'Este e-mail já está cadastrado, mas a senha informada não confere.';
    }
    if (normalized.contains('already registered') ||
        normalized.contains('already been registered') ||
        normalized.contains('user already registered') ||
        normalized.contains('user already exists') ||
        normalized.contains('user_already_exists')) {
      return 'Este e-mail já está cadastrado.';
    }
    if (normalized.contains('password') && normalized.contains('6')) {
      return 'A senha deve ter pelo menos 6 caracteres.';
    }
    if (normalized.contains('supabase') && normalized.contains('config')) {
      return 'Supabase não configurado. Verifique o arquivo .env.';
    }
    if (normalized.contains('webassembly') ||
        normalized.contains('sqflite') ||
        normalized.contains('sqlite') ||
        normalized.contains('databaseexception')) {
      return 'Banco local do navegador indisponivel. Reinicie o app e tente novamente.';
    }
    return decodedMessage;
  }

  String _friendlyAuthError(Object error) {
    if (error is AuthException) {
      return _friendlyAuthMessage(
        [
          error.message,
          if (error.code != null) error.code,
          if (error.statusCode != null) error.statusCode,
        ].join(' '),
      );
    }
    return _friendlyAuthMessage(error.toString());
  }

  String _decodeAuthMessage(String message) {
    try {
      final decoded = jsonDecode(message);
      if (decoded is Map<String, dynamic>) {
        final nested = decoded['message'] ?? decoded['msg'] ?? decoded['error'];
        if (nested is String && nested.trim().isNotEmpty) {
          return nested;
        }
      }
    } catch (_) {}
    return message;
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
