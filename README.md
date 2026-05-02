# FinançasApp - Controle Financeiro Personalizado

Aplicativo de controle financeiro pessoal desenvolvido com Flutter, utilizando o padrão arquitetural MVVM.

## Estrutura do Projeto (MVVM)

```
lib/
├── main.dart                    # Ponto de entrada, rotas e providers
├── models/
│   ├── transaction_model.dart   # Modelo de transação financeira
│   └── user_model.dart          # Modelo de usuário
├── viewmodels/
│   ├── auth_viewmodel.dart      # Lógica de autenticação
│   └── finance_viewmodel.dart   # Lógica financeira e cálculos
└── views/
    ├── auth_view.dart           # Tela de Login/Cadastro
    ├── dashboard_view.dart      # Tela Principal (Dashboard)
    └── analysis_view.dart       # Tela de Análise Financeira
```

## Como Executar

```bash
flutter pub get
flutter run -d chrome
```

## Tecnologias

- Flutter 3.x
- Dart
- Provider (gerenciamento de estado)
- Padrão MVVM
