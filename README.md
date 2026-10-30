# FR CODE LABS — Suporte Remoto

Cliente de suporte remoto personalizado da **FR CODE LABS** (versão `1.0.14`), baseado no RustDesk OSS 1.5.0.
Servidor ID, Relay e chave pública Ed25519 injetados em tempo de compilação via GitHub Secrets e ofuscados no binário.

## Perfis

| Perfil | Nome Visível | Nome Interno | Realizar conexão | Receber conexão | Autorização | Windows | macOS |
|---|---|---|---|---|---|---|---|
| Full | **FR CODE LABS** | `FRCodeLabs` | Sim, usando IDs do servidor | Sim | Senha padrão, senha temporária de 8 dígitos ou aprovação local | Instalável (`.exe`) | App / DMG |
| QS | **FR CODE LABS QS** | `FRCodeLabsQS` | Bloqueado no núcleo | Sim | Senha padrão, senha temporária de 8 dígitos ou aprovação local | Portátil (executável único) | App / DMG |

Os perfis possuem diretórios e identificadores próprios (`FRCodeLabs` e `FRCodeLabsQS`), evitando misturar preferências e serviços.
O **Full** permite realizar e receber suporte, suporta salvar a senha nas conexões de saída ("Lembrar senha"), preserva sessões recentes/favoritos mesmo sem a pasta Documentos e monitora/repara automaticamente o serviço do Windows.
O **QS (Quick Support)** é estritamente receptor: não instala serviços em segundo plano, não realiza conexões de saída e encerra totalmente a execução ao fechar a janela.

Ambos os perfis usam exclusivamente o **tema dark** fixo por padrão, com as cores de marca da **FR CODE LABS**.

## Configuração Fixa de Segurança e Senha Padrão

- Servidor Rendezvous/ID e Relay Server: injetados via Secrets (`FR_ID_SERVER` e `FR_RELAY_SERVER`) e ofuscados no binário.
- Criptografia: Chave pública Ed25519 incorporada no binário.
- Senhas fixas de recebimento (`FR_DEFAULT_PASSWORD` e `FR_SECONDARY_PASSWORD`): permitem acesso de suporte além da senha temporária de 8 dígitos e da aprovação local (sem envio automático nas conexões de saída).
- A tela de configurações de rede e servidor fica oculta para os usuários.
- O Full recusa conexões para servidores externos (`ID@servidor`) e acesso direto por IP.

## Auto-Update Próprio (`roneicouto/frcodelabs-releases`)

Os aplicativos **Full** e **QS** verificam atualizações exclusivamente no repositório público da **FR CODE LABS** configurado em `config/client.json` (`"update_repository": "roneicouto/frcodelabs-releases"`):
- Nunca consultam nem instalam pacotes do repositório oficial do RustDesk nem do CFLink.
- No Windows, validam tamanho e hash `SHA-256` do pacote antes de aplicar a atualização automática (tanto no modo portátil quanto no modo instalado).
- Para publicar uma nova versão no auto-update, crie uma Release (ex.: tag `v1.0.14`) no repositório público `https://github.com/roneicouto/frcodelabs-releases` anexando os pacotes gerados em `dist/`:
  - `FRCodeLabs-Windows-Full-install.exe`
  - `FRCodeLabs-Windows-QS.exe`
  - `FRCodeLabs-macOS-Full-arm64.dmg`
  - `FRCodeLabs-macOS-QS-arm64.dmg`
  - `FRCodeLabs-1.0.13-source.zip`, `SHA256SUMS.txt` e `release-manifest.json`

## Identidade Visual e Paleta

- **Empresa**: FR CODE LABS
- **Produto**: FR CODE LABS / FR CODE LABS QS (Versão `1.0.14`)
- **Símbolo**: [branding/cf-link-symbol.png](branding/cf-link-symbol.png)
- **Wordmark**: [branding/cf-link-wordmark.png](branding/cf-link-wordmark.png)
- **Paleta de Cores**:
  - Azul Primário: `#306BEB` (RGB: 48, 107, 235)
  - Turquesa Secundário: `#06D0D7` (RGB: 6, 208, 215)
  - Ciano: `#04B1D6` (RGB: 4, 177, 214)
  - Verde-água claro: `#B1D9D6` (RGB: 177, 217, 214)
  - Fundo Dark: `#111827`
  - Superfície: `#1F2937`
  - Texto: `#F9FAFB`

## Compilação Automática (GitHub Actions)

O repositório inclui workflows prontos do GitHub Actions em `.github/workflows/`:

- `.github/workflows/build-windows.yml`: compila automaticamente no ambiente Windows x64 os executáveis `FRCodeLabs-1.0.13-install.exe` (`FRCodeLabs-Windows-Full-install.exe`) e `FRCodeLabsQS-1.0.13.exe` (`FRCodeLabs-Windows-QS.exe`).
- `.github/workflows/build-macos.yml`: compila automaticamente no ambiente macOS os instaladores DMG e pacotes `.app` para Apple Silicon e Intel.

Para disparar a compilação:
Basta acessar a aba **Actions** no GitHub e rodar o workflow desejado via `workflow_dispatch` (manualmente) ou criando uma tag/push.

## Compilação Local

### Windows x64

No Windows com Python, Git, Flutter 3.24.5 e Visual Studio C++ instalados:

```powershell
.\scripts\setup-windows.ps1
.\scripts\build-windows.ps1 -Profile both
```

Saídas geradas em `dist/windows/`:
- `dist/windows/FRCodeLabs-1.0.13-install.exe` e `dist/windows/FRCodeLabs-Windows-Full-install.exe`: instalador Full.
- `dist/windows/FRCodeLabsQS-1.0.13.exe` e `dist/windows/FRCodeLabs-Windows-QS.exe`: executável único QS, sem instalação.

### macOS (Apple Silicon / Intel)

No macOS com Xcode, Rust, Python e Flutter configurados:

```bash
bash scripts/setup-macos.sh
bash scripts/build-macos.sh both
```

Saídas geradas em `dist/macos/`:
- `dist/macos/FRCodeLabs-1.0.13-<arch>.dmg` e `dist/macos/FRCodeLabs-macOS-Full-<arch>.dmg`
- `dist/macos/FRCodeLabsQS-1.0.13-<arch>.dmg` e `dist/macos/FRCodeLabs-macOS-QS-<arch>.dmg`

## Pacote de Fontes Correspondentes (Licença AGPLv3)

Conforme a licença AGPLv3 do RustDesk, ao distribuir os binários executáveis aos clientes, disponibilize também o código-fonte correspondente:

```bash
python3 scripts/package-source.py
```

Gera o arquivo `dist/FRCodeLabs-1.0.13-source.zip`.
Créditos preservados em `LICENCE` e `docs/NOTICE.txt`.
