# CtrlCash / CashCtrl — Documentação do App

Aplicativo de controle financeiro pessoal e de negócio em Flutter com Firebase, focado em calcular o ticket de produtos (ficha técnica) para mostrar se cada item dá lucro ou prejuízo.

## Visão Geral

O CashCtrl é um app mobile/web de gestão financeira que permite ao usuário:

- Autenticar-se com e-mail/senha, Google ou Facebook (Firebase Auth).
- Gerenciar transações financeiras (receitas e despesas) com categorias, métodos de pagamento e recorrência.
- Criar e acompanhar orçamentos mensais por categoria, com progresso em tempo real.
- Visualizar relatórios com gráficos (pizza, barras) e KPIs (lucro líquido, margem, ROI).
- Cadastrar um parque de insumos (materiais comprados para fabricar produtos), com cálculo automático de preço por unidade.
- Criar fichas técnicas de produtos (ex.: um sanduíche), selecionando insumos, quantidades, mão de obra e embalagem.
- Visualizar o ticket do produto: custo por ingrediente, custo total, ganho/perda e veredito final de lucro ou prejuízo.
- Identificar produtos por código de barras (scanner via câmera) ou foto, com reconhecimento automático de produtos já cadastrados.
- Editar perfil com foto, configurar notificações, segurança e acessar a central de ajuda.

## Stack / Tecnologias

- **Linguagem:** Dart (SDK ^3.11.5)
- **Framework:** Flutter
- **Backend:** Firebase
  - `firebase_core` — inicialização
  - `firebase_auth` — autenticação (e-mail/senha, Google, Facebook)
  - `cloud_firestore` — banco de dados NoSQL (CRUD isolado por UID)
  - `firebase_storage` — upload de fotos (perfil, produto)
- **Login social:** `google_sign_in`, `flutter_facebook_auth`
- **Estado:** `provider` (ChangeNotifierProvider, StreamProvider)
- **Gráficos:** `fl_chart` (pizza, barras, linhas)
- **Câmera/Imagem:** `image_picker` (fotos de perfil e produto), `mobile_scanner` (leitura de código de barras/QR)
- **Ícones:** `font_awesome_flutter`
- **Config:** `flutter_dotenv` (variáveis de ambiente para chaves do Firebase)

## Design System

Paleta de cores centralizada e reutilizada em todas as telas:

- Fundo: `0xFF0D1E16` (verde escuro)
- Verde Primário: `0xFF165A41`
- Dourado: `0xFFB89775`
- Cards: `0xFF142A20`
- Texto Secundário: `0xFF7A8B83`

Logo: `assets/images/logo.png` (camaleão nas cores do app, fundo transparente).

## Estrutura de Pastas

```
lib/
  main.dart                      # Inicializa .env, Firebase, providers e rotas
  firebase_options.dart          # Lê config do Firebase de .env (sem hardcoded keys)
  home_screen.dart               # Dashboard com saldo, gráficos e transações recentes
  budgets_screen.dart            # Orçamentos com progresso calculado em tempo real
  expenses_screen.dart           # Transações com filtros, busca e exclusão
  reports_screen.dart            # Relatórios com KPIs e gráficos (fl_chart)
  settings_screen.dart           # Configurações com perfil do usuário
  models/                        # Models de dados (puros, com fromMap/toMap)
    app_user.dart                # Perfil do usuário + dados do negócio
    transaction.dart             # Transação (receita/despesa, método de pagamento)
    budget.dart                  # Orçamento mensal por categoria
    ingredient.dart              # Insumo (preço de compra → preço por unidade)
    product.dart                 # Produto/ficha técnica (receita + custos + venda)
  providers/                     # Estado global (ChangeNotifier + streams)
    user_provider.dart           # Perfil + negócio (Firestore)
    transaction_provider.dart    # Stream de transações
    budget_provider.dart         # Stream de orçamentos
    ingredient_provider.dart    # Stream de insumos (com mapa id→Ingredient)
    product_provider.dart       # Stream de produtos + findByBarcode
  services/                      # Camada de acesso ao Firebase
    auth_service.dart           # FirebaseAuth (login, cadastro, logout)
    firestore_service.dart       # CRUD no Firestore (isolado por UID)
    storage_service.dart         # Upload de imagens (Storage, isolado por UID)
  screens/                       # Telas
    login_screen.dart           # Login (e-mail, Google, Facebook)
    cadastro_screen.dart        # Cadastro multi-etapa (pessoal + negócio)
    transaction_form_screen.dart # Nova/editar transação
    budget_form_screen.dart     # Novo/editar orçamento
    ingredients_screen.dart     # Lista de insumos (parque de insumos)
    ingredient_form_screen.dart # Cadastrar/editar insumo
    products_screen.dart        # Lista de produtos com veredito de lucro/prejuízo
    product_form_screen.dart    # Ficha técnica (receita + custos + foto + barcode)
    product_detail_screen.dart  # Ticket do produto (custo por ingrediente, veredito)
    product_scanner_screen.dart # Scanner de código de barras + foto
    settings/
      edit_profile_screen.dart  # Editar perfil com foto
      notifications_screen.dart # Preferências de notificações
      security_screen.dart      # Segurança e privacidade
      help_screen.dart          # Central de ajuda
  utils/                         # Utilitários e lógica pura
    categories.dart             # Categorias padrão (despesa/receita) com ícones
    format.dart                 # Formatação de moeda (R$) e datas (pt-BR)
    product_calculator.dart     # Calculadora do ticket (lucro/prejuízo, margem)
  widgets/                       # Widgets reutilizáveis
    app_drawer.dart             # Menu lateral com navegação
    app_branded_header.dart     # AppBar padrão com logo
    category_pie_chart.dart     # Gráfico de pizza de despesas (fl_chart)
android/                          # Configuração Android (google-services.json local)
web/                             # Build web
context/                          # Regras do assistente (erros a evitar)
docs/                            # Esta documentação
firestore.rules                  # Regras de segurança do Firestore (isolamento por UID)
storage.rules                    # Regras de segurança do Storage (isolamento por UID)
```

## Modelo de Dados (Firestore)

Todos os dados ficam sob `users/{uid}/...`, garantindo isolamento total por usuário (RN02):

- `users/{uid}` — perfil do usuário (nome, e-mail, empresa, CNPJ, segmento, telefone, endereço, photoUrl)
- `users/{uid}/transactions/{txId}` — transações (tipo, categoria, valor, data, método de pagamento, recorrência)
- `users/{uid}/budgets/{budgetId}` — orçamentos (categoria, limite mensal)
- `users/{uid}/ingredients/{ingredientId}` — insumos (nome, unidade, preço de compra, quantidade da embalagem)
- `users/{uid}/products/{productId}` — produtos/fichas técnicas (nome, receita[], mão de obra, embalagem, preço de venda, photoUrl, barcode)

## O Ticket do Produto (recurso central)

O coração do app é mostrar ao usuário o ticket de cada produto. O fluxo:

1. Usuário cadastra insumos no parque (ex.: pão R$ 10,00/20un → R$ 0,50/un).
2. Cria uma ficha técnica (ex.: "Sanduíche X") selecionando insumos e quantidades (2 fatias de pão, 100g de queijo, etc.), mão de obra e embalagem.
3. O app calcula: custo por ingrediente (qtd × preço por unidade), subtotal de ingredientes, custo total, preço de venda, lucro/prejuízo e margem.
4. O ticket mostra o veredito: "ESTE PRODUTO DÁ LUCRO" ou "ESTE PRODUTO DÁ PREJUÍZO".
5. O usuário pode identificar produtos por código de barras ou foto; na primeira vez cadastra, nas seguintes o app reconhece automaticamente.

## Segurança

- As credenciais do Firebase NÃO estão no código. São lidas de `.env` via `flutter_dotenv`.
- `.env` e `google-services.json` estão no `.gitignore` (não versionados).
- `firestore.rules` e `storage.rules` garantem isolamento por UID (cada usuário só acessa seus próprios dados).
- Keystores e `local.properties` também estão no `.gitignore`.

## Como rodar localmente

1. Copie `.env.example` para `.env` e preencha os valores do Firebase.
2. Coloque `google-services.json` em `android/app/` (baixe do Firebase Console).
3. `flutter pub get`
4. `flutter run`

## Repositório

- Origin: `https://github.com/JoaoVikthor/ctrlcash.git`