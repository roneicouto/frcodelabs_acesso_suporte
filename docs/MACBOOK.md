# Compilar CF Link no MacBook

O código do projeto está no repositório `cdlawliet/CFLink`. Clone-o no MacBook
para compilar Full e QS. Os testes de conexão real do piloto Windows continuam
registrados em `docs/VALIDACAO-WINDOWS.md`; a publicação do código não substitui
esses testes. Não foi executada uma compilação macOS no Windows.

## Preparar o Mac

Use uma versão de macOS compatível com o Xcode instalado, Terminal nativo e
Xcode completo instalado pela App Store. O mínimo configurado para os aplicativos
gerados é macOS 12.3. Abra o Xcode uma vez e conclua a instalação dos componentes solicitados.
O Command Line Tools isolado não substitui o Xcode para compilar a interface.
Se necessário, selecione a instalação:

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
xcodebuild -version
```

Instale o [Homebrew](https://brew.sh/) seguindo as instruções oficiais e abra
um novo Terminal com `brew` disponível. Em Apple Silicon, execute fora do Rosetta.
Reserve espaço para os SDKs, o código e os caches de compilação; a primeira
execução baixa e compila várias dependências e pode demorar bastante.

## Obter e compilar

Clone o repositório e execute a preparação e o build:

```bash
git clone https://github.com/cdlawliet/CFLink.git CF-Link
cd CF-Link
bash scripts/setup-macos.sh
bash scripts/build-macos.sh both
```

Também é possível usar o arquivo de código-fonte: extraia `CFLink-1.0.2-source.zip`,
entre na pasta `cf-link` e execute os mesmos dois scripts. Não transfira a pasta
`.tools` do Windows: as ferramentas e bibliotecas são específicas de cada sistema.

O setup instala dependências de compilação pelo Homebrew. Mantém Flutter 3.24.5,
Rust 1.81.0, o bridge e o vcpkg fixado dentro de `.tools`, sem substituir os SDKs
Flutter/Rust de outros projetos nem alterar seu perfil do shell. O código RustDesk
é obtido pelo commit fixado em `config/source-lock.json`, com verificação do
submódulo. A configuração e a chave pública são incorporadas à compilação.

As dependências Dart começam com o lockfile do piloto. As bibliotecas nativas
usam os codecs de software, como nos pacotes Windows/Android preparados.
Cada perfil é compilado separadamente para impedir mistura entre Full e QS.

Para compilar apenas um perfil:

```bash
bash scripts/build-macos.sh full
bash scripts/build-macos.sh qs
```

Saídas para Apple Silicon:

```text
dist/macos/CFLink-1.0.2-arm64.dmg
dist/macos/CFLinkQS-1.0.2-arm64.dmg
```

Em Mac Intel, o sufixo será `x86_64`. Cada DMG tem seu arquivo `.sha256` e um
atalho para Aplicativos. Os pacotes são da arquitetura do computador que os
compila; este fluxo não gera um binário universal. O mínimo configurado é macOS 12.3.

## Validar no Mac

O build verifica o nome e a arquitetura do aplicativo, a assinatura ad hoc
e a integridade do DMG. Isso não comprova funcionamento remoto.

1. Abra o DMG, copie o aplicativo para Aplicativos e abra-o.
2. Autorize Gravação da Tela e Acessibilidade nas configurações do macOS;
   reinicie o aplicativo caso o sistema solicite.
3. Confirme nome, logo, ID e estado de conexão ao servidor da empresa.
4. No Full, realize e receba uma conexão usando outro cliente desse servidor.
5. No QS, receba uma solicitação, recuse-a e confirme que não abre sessão;
   depois aceite uma nova solicitação. Teste também acesso pela senha temporária,
   que dispensa aprovação local. Confirme ausência de conexão de saída
   e encerre a janela para verificar que o suporte deixa de estar disponível.
6. Confirme que nenhum perfil permite editar o servidor ou a chave.

A assinatura ad hoc serve para o teste local e não substitui assinatura
Developer ID e notarização Apple para distribuição. O macOS pode exigir
autorização para abrir o aplicativo nas configurações de Privacidade e Segurança.

## Manter o projeto

Antes de recompilar após atualizar o código, execute o setup novamente.
Ele preserva os caches e reaplica as preparações sem resetar o código existente.
Se detectar uma versão de origem diferente da fixada, interrompe com erro.
Não execute `git reset --hard` em `upstream`: ali ficam as alterações aplicadas.

Para carregar as ferramentas locais em uma sessão de Terminal:

```bash
source scripts/env-macos.sh
```

O repositório inclui configuração, chave pública, identidade visual, overlay,
dependência vendorizada e instruções. `.tools`, `upstream`, `dist` e chaves privadas
ficam fora do Git. Faça backup privado de `.tools/signing` do Windows, que contém
a identidade usada nos APKs; ela será necessária para atualizações Android.
