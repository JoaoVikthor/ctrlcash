# CtrlCash / CashCtrl — Documentação do App

Aplicativo de controle financeiro pessoal em Flutter com autenticação Firebase.

## Visão Geral

O **CashCtrl** é um app mobile/web de gestão financeira pessoal que permite ao usuário:
- Autenticar-se com e-mail/senha, Google ou Facebook (Firebase Auth).
- Gerenciar despesas (`lib/expenses_screen.dart`).
- Gerenciar orçamentos (`lib/budgets_screen.dart`).
- Visualizar relatórios (`lib/reports_screen.dart`).
- Configurar preferências (`lib/settings_screen.dart`).

## Stack

- **Linguagem:** Dart (SDK ^3.11.5)
- **Framework:** Flutter
- **Backend:** Firebase
  - `firebase_core` — inicialização
  - `firebase_auth` — autenticação
  - `google_sign_in` — login Google
  - `flutter_facebook_auth` — login Facebook
  - `cloud_firestore` — banco de dados (atualmente em `dev_dependencies`)
- **Ícones:** `font_awesome_flutter`

## Estrutura de Pastas

```
lib/
  main.dart                 # Inicializa .env (dotenv) e Firebase, roda o app
  firebase_options.dart      # Lê config do Firebase de .env (NÃO hardcoded)
  login_screen.dart          # Tela de login (e-mail, Google, Facebook)
  home_screen.dart           # Home pós-login
  expenses_screen.dart       # Despesas
  budgets_screen.dart        # Orçamentos
  reports_screen.dart        # Relatórios
  settings_screen.dart       # Configurações
  widgets/                   # Widgets reutilizáveis
  assets/                    # Assets locais
android/                     # Configuração Android (google-services.json local, NÃO subir)
web/                         # Build web
context/                     # Arquivos de contexto do assistente (erros a evitar)
docs/                        # Esta documentação
```

## Segurança

As credenciais do Firebase NÃO estão no código. São lidas de um arquivo `.env` via `flutter_dotenv`:

```
FIREBASE_PROJECT_ID, FIREBASE_MESSAGING_SENDER_ID,
FIREBASE_WEB_API_KEY, FIREBASE_WEB_APP_ID, FIREBASE_WEB_MEASUREMENT_ID,
FIREBASE_ANDROID_API_KEY, FIREBASE_ANDROID_APP_ID,
FIREBASE_AUTH_DOMAIN, FIREBASE_STORAGE_BUCKET,
GOOGLE_SIGN_IN_CLIENT_ID, FACEBOOK_APP_ID, FACEBOOK_CLIENT_TOKEN
```

- `.env` é **ignorado pelo git** (ver `.gitignore`).
- Use `.env.example` como modelo vazio ao versionar.
- `android/app/google-services.json` também é ignorado (obtido localmente do Firebase Console).
- Para mais regras, veja `context/erros-a-evitar.md`.

## Como rodar localmente

1. Copie `.env.example` para `.env` e preencha os valores do Firebase.
2. Coloque `google-services.json` em `android/app/` (baixe do Firebase Console).
3. `flutter pub get`
4. `flutter run`

## Repro/Remote Git

- Origin: `https://github.com/JoaoVikthor/ctrlcash.git`