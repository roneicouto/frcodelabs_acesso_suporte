# Validação do piloto Windows

Os testes de política Full/QS e as verificações dos binários passaram.
Falta validar uma sessão real entre dois computadores usando seu servidor.
Registre abaixo os resultados e qualquer erro observado.

| Verificação | Resultado |
|---|---|
| Full abre com nome, logo e cores CF Link | Pendente |
| Full registra um ID e fica disponível no servidor da empresa | Pendente |
| Full realiza conexão por ID com outro cliente desse servidor | Pendente |
| Full recebe conexão por senha individual e por aprovação | Pendente |
| Full instalado funciona após reiniciar o Windows | Pendente |
| QS abre sem instalar serviço e recebe solicitação | Pendente |
| QS recusa a sessão quando a solicitação é negada | Pendente |
| QS aceita a sessão por senha temporária, sem aprovação local | Pendente |
| QS sem senha exige aprovação local | Pendente |
| Full e QS aceitam a senha padrão e a temporária, mantendo somente a temporária visível | Pendente |
| Full exige digitação sem “Lembrar senha”; ao marcar, salva a credencial por computador e a reutiliza | Pendente |
| Recentes e favoritos carregam com a pasta Documentos indisponível, preservando os registros existentes | Pendente |
| Escala adaptada é aplicada a novos clientes e à primeira abertura de clientes antigos | Pendente |
| Alterar manualmente a escala após a migração preserva a nova escolha | Pendente |
| Verificar atualização consulta o repositório CF Link; falha de rede não interrompe o suporte | Pendente |
| Aviso de versão nova oferece Baixar / Mais tarde e escolhe o pacote correto | Pendente |
| Full e QS abrem em dark, inclusive com Windows no tema claro | Pendente |
| Não há seletor de tema claro ou do sistema | Pendente |
| “Sobre / Licenças” funciona no Full e no QS e mostra a licença completa | Pendente |
| Banner RustDesk oculto na tela principal; créditos preservados na seção legal | Pendente |
| QS impede iniciar conexão e inversão de lados | Pendente |
| Fechar a janela QS encerra a disponibilidade para suporte | Pendente |
| Servidor, relay e chave não podem ser alterados na interface | Pendente |
| Full e QS mantêm suas preferências separadas | Pendente |

Use `dist/windows/CFLink-1.0.12-install.exe` para Full e
`dist/windows/CFLinkQS-1.0.12.exe` para QS. Cada computador deve executar uma única
instância de cada perfil durante o teste. Não use um cliente configurado para o
servidor público como destino do teste Full.

O código está no repositório `cdlawliet/CFLink`, publicado por solicitação do
responsável pelo projeto. A publicação não comprova o funcionamento remoto:
os testes acima continuam pendentes até serem realizados e registrados.
A obtenção do projeto e a compilação no MacBook seguem `docs/MACBOOK.md`.

## Atualização interna — piloto a partir da 1.0.5

Automatizado: oito testes Dart de seleção/download/integridade e três cenários
do helper portátil (Full, QS, recusa de pacote corrompido). Execute
`powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/tests/verify-update-windows.ps1`
para repetir o teste em uma pasta temporária com executáveis inofensivos.

O piloto detectou falha na inicialização do PowerShell nas versões 1.0.5/1.0.6.
Instale a **1.0.7 manualmente uma vez**. O teste agora chama a função Dart real
e comprova que o helper continua depois de o processo pai encerrar.
Para testar com o aplicativo real, use a 1.0.7 como origem e uma release superior
como destino. A 1.0.4 ainda usa download no navegador.

1. No QS, abra pelo EXE distribuído, consulte a atualização e cancele o download:
   o aplicativo deve continuar disponível.
2. Baixe novamente e escolha **Agora não**: a versão atual permanece aberta.
3. Aceite **Atualizar e reiniciar** sem outra janela do QS aberta: o EXE original
   deve mudar, a cópia `.previous` deve existir e a tela deve mostrar a versão nova.
4. Feche e reabra pelo mesmo arquivo/atalho: a versão deve continuar nova.
5. Repita com Full portátil: não deve abrir a tela de instalação ao reiniciar.
6. Repita com Full instalado: confirme o UAC, confira versão, ID e serviço após
   reabrir. Faça também o teste recusando o UAC: a atualização deve falhar com
   mensagem e a versão anterior deve poder ser aberta.
7. Confira senha temporária, senha predefinida, aprovação local, servidor fixo e
   digitação numa nova conexão sem marcar “Lembrar senha”. Marque a opção e
   reconecte pelo histórico/favoritos; confira também a ação de esquecer a senha.
   Repita uma sessão entre dois PCs.

Esses testes interativos, especialmente Full instalado/UAC, permanecem pendentes.
Erros após o fechamento ficam em `%TEMP%/CFLink-update-*/update.log`.
Falhas de inicialização ficam em `plan.json.launch.log` na mesma pasta.

## Full renomeado pelo navegador — 1.0.8

Downloads repetidos com `(1)`/`(2)` antes de `.exe` não eram reconhecidos como
instaladores. A 1.0.8 identifica Full pelo conteúdo do pacote. Três testes de
seleção passaram, e o pacote real com nome `install (2).exe` abriu a janela
**CFLink - Install**, fechada pelo teste sem aceitar instalação.

`scripts/tests/verify-full-installer-window.ps1` repete a abertura da janela,
refaz o cache de extração do Full e exige que o Full portátil esteja fechado.
Não instala o serviço nem substitui arquivos em Program Files. Para validar a
substituição real, abra o Full, confira o diretório já preenchido, escolha
**Aceitar e instalar**, autorize o Windows e confira a versão 1.0.8 no atalho
da instalação. QS deve continuar abrindo diretamente para receber suporte.

## Teste 1.0.8 → 1.0.9

Use a **1.0.8 como origem** e a **1.0.9 como destino**. Consulte manualmente,
clique em **Atualizar agora** e confirme **Atualizar e reiniciar**. No Full
instalado, autorize o UAC e confira a versão 1.0.9 pelo atalho da instalação.
No QS e Full portátil, feche as outras janelas do mesmo perfil e confira a
versão ao reabrir pelo mesmo arquivo. A 1.0.9 mantém o código da 1.0.8.

## Consulta inicial na 1.0.10

Ao fechar e abrir a tela principal, a consulta inicial deve acontecer mesmo
que o registro `cf-update-check-ms` seja recente. Com uma release posterior
disponível, o cartão deve aparecer sem clicar no botão manual. Sem rede, o
programa deve abrir normalmente; a consulta manual continua informando erros.
Download e reinício só devem ocorrer após a escolha do usuário.

## Serviço do Full instalado — 1.0.11

`powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/tests/verify-service-windows.ps1`
valida sete cenários com controle de serviço simulado, sem alterar o sistema.

No piloto, usando o Full **instalado** e sem sessão remota em andamento:

1. Com o serviço ativo, abrir o Full: deve mostrar **Serviço ativo**, sem reinício/UAC.
2. Com o serviço parado, abrir: deve tentar iniciá-lo e mostrar ativo. Autorizar
   o Windows quando solicitado; testar também recusando, sem fechar o app.
3. Com o serviço ausente, conferir **Serviço não instalado** e **Reparar serviço**.
   Confirmar o reparo, conferir a reabertura e a preservação do ID/configurações.
4. Confirmar que o serviço de outra instalação/caminho não é iniciado automaticamente.
5. No QS e Full portátil, confirmar que não há verificação ou controle do serviço.
6. Esconder/minimizar o Full, parar seu serviço pelo Windows e reabrir a janela:
   deve repetir a verificação. Alternar entre aplicativos e retornar do UAC
   não deve causar uma nova solicitação de administrador.

Testes reais de serviço/UAC permanecem pendentes. O reparo pode interromper
conexões e reabrir o Full; a confirmação informa isso antes de prosseguir.

## Serviço ausente na 1.0.12

Com o Full instalado e serviço ausente, abrir o app deve iniciar a rotina
original de registro, sem clicar em **Reparar serviço**. Autorizar o UAC e
conferir a reabertura, serviço ativo e ID/configurações preservados.
Recusar o UAC deve resultar em falha visível com reparo manual disponível.
Uma reabertura imediata após falha não deve gerar ciclo de reparo/UAC.

O teste `flutter test test/cf_service_recovery_test.dart` verifica três cenários
de tentativa persistente sem modificar serviços do Windows. A validação real
de registro permanece pendente; não parar/remover o serviço durante suporte.
