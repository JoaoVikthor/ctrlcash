# CashCtrl

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-^3.11.5-0175C2?logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Auth%20%2B%20Firestore%20%2B%20Storage-FFCA28?logo=firebase&logoColor=black)
![Plataformas](https://img.shields.io/badge/Plataformas-Android%20%7C%20Web-green)

O **CashCtrl** é um aplicativo de controle financeiro para pequenos negócios, desenvolvido em Flutter com backend Firebase. Além do gerenciamento financeiro completo (transações, orçamentos e relatórios), seu diferencial é a **Ficha Técnica de Produto com Ticket**: cadastre insumos, monte receitas e descubra automaticamente se cada produto dá lucro ou prejuízo, com custo detalhado por ingrediente, margem e markup.

## Screenshots

Capturas de tela disponíveis na raiz do projeto: `Banner ctrlCash.jpeg` e `flutter_01.png`. O app usa um design system dark com verde primário e acentos dourados.

## Funcionalidades

- Autenticação com e-mail/senha e login social via Google (Firebase Auth)
- Dashboard com saldo, gráfico de pizza e transações recentes
- Transações (receitas e despesas) com CRUD, filtros, busca e métodos de pagamento
- Orçamentos mensais por categoria com barra de progresso em tempo real
- Parque de Insumos com cálculo automático de preço por unidade
- Ficha Técnica de Produto: ingredientes, mão de obra e embalagem
- Ticket do Produto com veredito "DÁ LUCRO" ou "DÁ PREJUÍZO", margem e markup
- Scanner de código de barras/QR via câmera (mobile_scanner)
- Relatórios com KPIs (lucro líquido, margem, ROI), gráfico de barras dos últimos 6 meses, pizza por categoria e top 5 categorias
- Perfil com foto (Firebase Storage), recuperação de senha, alteração de senha e exclusão de conta
- Design system dark: fundo `0xFF0D1E16`, verde primário `0xFF165A41`, dourado `0xFFB89775`

## Tecnologias

| Área | Tecnologia |
| --- | --- |
| Framework | Flutter (Dart SDK ^3.11.5) |
| Autenticação | firebase_auth, google_sign_in |
| Banco de dados | cloud_firestore |
| Armazenamento | firebase_storage |
| Estado | provider |
| Gráficos | fl_chart |
| Câmera / imagem | mobile_scanner, image_picker |
| Config | flutter_dotenv |
| Ícones | font_awesome_flutter |

## Como rodar

### Pré-requisitos

- Flutter SDK (Dart ^3.11.5)
- Projeto Firebase configurado (Auth, Firestore e Storage)
- Android SDK (para build Android) e/ou Chrome (para web)

### Passos

1. Clone o repositório:

   ```bash
   git clone https://github.com/JoaoVikthor/ctrlcash.git
   cd ctrlcash
   ```

2. Configure o ambiente:

   ```bash
   cp .env.example .env
   ```

   Preencha o `.env` com as chaves do Firebase (project ID, API keys, app IDs) e o Client ID do Google Sign-In. Consulte `documentacao/ctrlcash_documentacao.txt` para a descrição de cada variável.

3. Configure o Firebase:

   ```bash
   flutterfire configure
   ```

   Para Android, coloque também o `google-services.json` (baixado do Firebase Console) em `android/app/`. Publique as regras de segurança em `firestore.rules` e `storage.rules` (via `firebase deploy --only firestore:rules,storage` ou o console).

4. Instale as dependências e rode o app:

   ```bash
   flutter pub get
   flutter run
   ```

## Estrutura de pastas

```
lib/
  main.dart                  # Inicializa .env, Firebase, providers e rotas
  firebase_options.dart      # Config do Firebase lida de .env
  home_screen.dart           # Dashboard (saldo, gráficos, transações recentes)
  budgets_screen.dart        # Orçamentos com progresso
  expenses_screen.dart       # Transações com filtros e busca
  reports_screen.dart        # Relatórios (KPIs e gráficos)
  settings_screen.dart       # Configurações e perfil
  models/                    # Modelos de dados (AppUser, Transaction, Budget, Ingredient, Product)
  providers/                 # Estado global (ChangeNotifier + streams do Firestore)
  services/                  # Auth, Firestore e Storage (isolados por UID)
  screens/                   # Telas (login, cadastro, formulários, insumos, produtos, ticket, scanner)
  screens/settings/          # Perfil, notificações, segurança e ajuda
  utils/                     # Categorias, formatação (R$, pt-BR) e product_calculator
  widgets/                   # Drawer, AppBar e gráfico de pizza reutilizáveis
```

Documentação detalhada em `docs/overview.md` e `documentacao/ctrlcash_documentacao.txt`.

## Regras de negócio

- **RN01** — Valores de transação devem ser maiores que zero.
- **RN02** — Isolamento total por UID: todos os dados ficam sob `users/{uid}/...` no Firestore e Storage.
- **RN03** — Preço por unidade do insumo = preço de compra / quantidade do pacote.

## Segurança

- As credenciais do Firebase não estão no código: são lidas de `.env` via `flutter_dotenv`.
- `.env`, `google-services.json`, keystores e `local.properties` estão no `.gitignore` (não versionados).
- `firestore.rules` e `storage.rules` garantem que cada usuário acesse apenas seus próprios dados (RN02).
