## CF Link 1.0.4 para Windows

Full e QS agora exibem **Versão 1.0.4** na tela principal, acima do botão
“Sobre / Licenças”. O número vem dos mesmos metadados usados pela consulta
de atualização, sem depender da versão base do RustDesk.

As funcionalidades da 1.0.3 permanecem: escala adaptada como padrão, senha
padrão de recebimento mais temporária visível, senha digitada nas novas
conexões e aviso de atualização com download opcional.

### Testar a atualização

1. Abra o Full ou QS **1.0.3** instalado no Windows.
2. Clique em **Verificar atualização**. A consulta manual dispensa a espera
   do intervalo automático de 24 horas.
3. Confirme o aviso da **1.0.4** e escolha **Baixar atualização**.
4. Feche o aplicativo anterior, instale/abra o pacote novo e confira
   **Versão 1.0.4** na tela principal.

O download abre no navegador; a instalação não ocorre automaticamente.
Executáveis sem Authenticode continuam sujeitos aos avisos do SmartScreen.

### Pacotes desta release

| Sistema | Full / QS |
|---|---|
| Windows x64 | **1.0.4** |
| macOS Apple Silicon ARM64 | **1.0.2**, preservados até nova compilação no Mac |

Os links estáveis de download continuam iguais. Os labels dos assets informam
a versão real de cada pacote, evitando que os DMGs antigos sejam oferecidos
como atualização nova.

As fontes modificadas Windows estão em `CFLink-1.0.4-source.zip`; as fontes
anteriores mantidas para os DMGs estão em `CFLink-1.0.2-source.zip`. Confira os
hashes em `SHA256SUMS.txt` e os detalhes em `release-manifest.json`.
Os arquivos automáticos “Source code” deste repositório de downloads contêm
somente a documentação; para compilar o aplicativo use o ZIP CFLink correspondente.

Base RustDesk 1.5.0; licença GNU AGPLv3, com créditos preservados no aplicativo.
