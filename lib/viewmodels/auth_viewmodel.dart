import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AuthViewModel extends ChangeNotifier {
  // Controla se está na tela de Login ou Cadastro
  bool _isLogin = true;
  bool get isLogin => _isLogin;

  // Controllers dos campos de texto
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Estado de carregamento e mensagens
  final bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Usuário "cadastrado" em memória (simulação)
  UserModel? _registeredUser;

  // Alterna entre Login e Cadastro
  void toggleAuthMode() {
    _isLogin = !_isLogin;
    _errorMessage = null;
    notifyListeners();
  }

  // Lógica de autenticação
  bool authenticate() {
    _errorMessage = null;

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _errorMessage = 'Preencha todos os campos.';
      notifyListeners();
      return false;
    }

    if (_isLogin) {
      // Verifica se o usuário existe
      if (_registeredUser == null) {
        _errorMessage = 'Nenhum usuário cadastrado. Crie uma conta primeiro.';
        notifyListeners();
        return false;
      }
      if (_registeredUser!.email != email ||
          _registeredUser!.password != password) {
        _errorMessage = 'E-mail ou senha incorretos.';
        notifyListeners();
        return false;
      }
      return true;
    } else {
      // Cadastro
      final name = nameController.text.trim();
      if (name.isEmpty) {
        _errorMessage = 'Preencha o nome.';
        notifyListeners();
        return false;
      }
      _registeredUser = UserModel(
        name: name,
        email: email,
        password: password,
      );
      _isLogin = true;
      _errorMessage = null;
      notifyListeners();
      return false; // Retorna false pois redireciona para login após cadastro
    }
  }

  String get userName => _registeredUser?.name ?? 'Usuário';

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
