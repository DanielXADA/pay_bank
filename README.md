# 🏦 Pay Bank — Simulador de Banco Digital

O **Pay Bank** é um aplicativo mobile desenvolvido em Flutter que simula as operações essenciais de uma conta bancária digital moderna, contemplando onboarding com validação de CEP, autenticação biométrica, movimentações via PIX, depósitos virtuais e cotações de moedas em tempo real.

* **Projeto Acadêmico:** Desenvolvido para a disciplina de Desenvolvimento para Dispositivos Móveis do curso de Ciência da Computação / Sistemas de Informação (Turma B - Manhã) — UNAMA.
* **Equipe / Desenvolvedor:** Daniel Lucas Lisboa Cardoso

---

## 📋 Pré-requisitos de Ambiente

Antes de iniciar, certifique-se de possuir instalado em sua estação de trabalho:

1. **Flutter SDK**: Versão 3.12.0 ou superior (Canal `stable`).
   * Verifique com: `flutter --version`
2. **Dart SDK**: Versão 3.0 ou superior (incluso com o Flutter).
3. **Java Development Kit (JDK)**: JDK 17 (obrigatório para compatibilidade com o Gradle do projeto).
4. **Android Studio** ou **VS Code**: Com os plugins oficiais do Flutter e Dart devidamente instalados.
5. **Dispositivo de Execução**: 
   * Emulador Android (API 28+) com suporte a biometria/bloqueio ativado; ou
   * Aparelho físico com Depuração USB ativada.

---

## 🚀 Passo a Passo para Execução Local

### 1. Clonar o Repositório
```bash
git clone https://github.com/DanielXADA/pay_bank.git
cd pay_bank
```

### 2. Baixar as Dependências
Instale todos os pacotes declarados no `pubspec.yaml`:
```bash
flutter pub get
```

### 3. Verificar Dispositivos Disponíveis
```bash
flutter devices
```

### 4. Iniciar o Aplicativo
Execute no dispositivo ou emulador conectado:
```bash
flutter run
```

---

## 🛠️ Tecnologias e Bibliotecas Utilizadas

- **Framework Principal**: Flutter (Dart) — SDK `^3.12.0`
- **Banco de Dados Local**: `sqflite` (^2.3.0) e `path` (^1.9.0) — Persistência relacional local (SQLite)
- **Persistência de Sessão**: `shared_preferences` (^2.5.5) — Armazenamento chave-valor para retenção do último usuário logado
- **Comunicação de Rede**: `http` (^1.2.1) e cliente nativo `HttpClient` (`dart:io`)
- **Segurança e Hardware**:
  - `local_auth` (^3.0.1) — Autenticação biométrica nativa (impressão digital / reconhecimento facial)
  - `image_picker` (^1.2.2) — Acesso à câmera e galeria do dispositivo para foto de perfil
- **Compartilhamento**: `share_plus` (^13.1.0) — Compartilhamento nativo de comprovantes de transferência
- **Interface e Máscaras**: `mask_text_input_formatter` (^2.9.0) e `cupertino_icons` (^1.0.8)
- **Geração de Ícones**: `flutter_launcher_icons` (^0.14.4)
- **APIs Externas Integradas**:
  - **AwesomeAPI** (`https://economia.awesomeapi.com.br/json/last/USD-BRL,EUR-BRL,BTC-BRL`): Consulta de taxas cambiais (USD, EUR, BTC) e variação percentual em tempo real.
  - **ViaCEP** (`https://viacep.com.br/ws/{cep}/json/`): Preenchimento automático de logradouro, bairro, cidade e UF com base no CEP digitado.

---

## 🏗️ Arquitetura e Organização do Sistema

O projeto adota uma estrutura modular organizada por funcionalidades (**Feature-Driven Layout**), segregando regras de tela, acesso a dados e serviços auxiliares:

```text
lib/
├── database/
│   └── db_helper.dart            # Gerenciador SQLite (Singleton) e migrações de schema
├── features/
│   ├── cotacao/
│   │   └── cotacao_page.dart     # Cotações em tempo real e calculadora de conversão cambial
│   ├── login/
│   │   ├── cadastro_page.dart    # Onboarding em 4 etapas com integração ViaCEP
│   │   └── login_page.dart       # Autenticação por credenciais, biometria e recuperação
│   ├── perfil/
│   │   ├── alterar_senhas_page.dart # Atualização de senhas de acesso (8 dig) e transação (6 dig)
│   │   ├── meus_dados_page.dart     # Visualização e edição de dados com confirmação de senha
│   │   ├── minhas_chaves_page.dart  # Gerenciamento e geração de chaves PIX aleatórias
│   │   └── perfil_page.dart         # Perfil com foto via câmera/galeria
│   ├── principal/
│   │   └── principal_page.dart   # Dashboard (saldo, extrato recente e depósito)
│   └── transferencia/
│       └── transferencia_page.dart # Fluxo completo de PIX com revisão e comprovante
├── pages/
│   └── welcome_page.dart         # Tela de boas-vindas com animações e cartões 3D
├── services/
│   └── cotacao_service.dart      # Serviço HTTP de integração com a AwesomeAPI
├── widgets/
│   └── bouncing_button.dart      # Componente visual com micro-interação animada
└── main.dart                     # Ponto de entrada e mapeamento de rotas nomeadas
```

---

## 💾 Persistência de Dados (SQLite)

O armazenamento interno é gerenciado pela classe `DatabaseHelper` (instância Singleton com arquivo `sistema_usuarios.db`), contendo controle de versão e migração dinâmica (`_upgradeDB` até a v4):

### Tabelas Principais:

1. **`usuarios`**:
   * Identificação: `id` (PK), `nome`, `nome_usuario` (UNIQUE), `cpf` (UNIQUE), `data_nascimento`.
   * Contato e Localização: `email`, `telefone`, `endereco`, `cep`.
   * Segurança: `senha` (login), `senha_transacao` (6 dígitos para operações).
   * Dados Bancários: `agencia` (fixa `0001`), `numero_conta` (gerado aleatoriamente), `saldo`.
   * Mídia e Chaves: `foto_rosto`, `chave_aleatoria`, `chave_cpf_ativa`, `chave_email_ativa`, `chave_telefone_ativa`.

2. **`transferencias`**:
   * `id` (PK), `id_usuario` (FK), `tipo` (`ENTRADA` / `SAIDA`), `valor`, `data`.
   * `recebedor`, `pagador`, `id_transacao`.
   * `cpf_recebedor`, `agencia_recebedor`, `conta_recebedor`.

---

## 📱 Principais Funcionalidades Implementadas

* **Onboarding Completo**: Cadastro progressivo em 4 etapas (*Dados Pessoais*, *Canais de Contato*, *Endereço* com preenchimento via CEP, e *Segurança* com definição de senhas).
* **Autenticação em Duas Modalidades**: Entrada com usuário/senha ou autenticação biométrica rápida após o primeiro acesso salvo.
* **Recuperação de Acesso**: Validação de segurança por cruzamento de usuário, CPF e data de nascimento cadastrados para redefinição de senha.
* **Dashboard & Privacidade**: Exibição de saldo da conta com alternância de visibilidade (ocultar/mostrar), atalhos de ações rápidas e extrato das últimas movimentações.
* **Depósito Virtual**: Modal com máscara de centavos monetária em tempo real e atualização instantânea de saldo com geração de comprovante de entrada.
* **Transferência PIX entre Contas**:
  * Suporte a múltiplos tipos de chave (CPF, Celular, E-mail e Chave Aleatória);
  * Validação de saldo disponível e bloqueio de auto-transferência;
  * Modal de revisão dos dados do destinatário antes da efetivação;
  * Confirmação mandatória por senha de transação numérica de 6 dígitos;
  * Emissão de comprovante detalhado com opção nativa de compartilhamento.
* **Conversor de Câmbio em Tempo Real**: Consulta dinâmica da AwesomeAPI com conversão instantânea de BRL para USD, EUR ou BTC.
* **Gestão de Perfil**: Captura de foto de perfil via Câmera ou Galeria, ativação/desativação de chaves PIX, e alteração de dados pessoais e senhas.
