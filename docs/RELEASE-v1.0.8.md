## CF Link 1.0.8 — Full abre o instalador mesmo após renomear

Corrigido o Full que abria somente o aplicativo quando o navegador nomeava
downloads repetidos como `CFLink-Windows-Full-install (1).exe` ou `(2).exe`.
O pacote agora identifica a versão Full pelo conteúdo e abre o assistente de
instalação por padrão, independentemente do nome recebido no download.

### Atualizar a instalação existente

1. Baixe e abra o instalador Full desta release.
2. Confira o diretório da instalação atual, preenchido no assistente.
3. Escolha **Aceitar e instalar** e autorize o Windows quando solicitado.
4. Ao abrir o aplicativo instalado, confira **Versão 1.0.8**.

Full portátil continua disponível com `--noinstall`. O atualizador interno
preserva o comando `--update`; QS continua portátil e sem instalação.
O visual e a correção do início do atualizador da 1.0.7 foram mantidos.
Quem usa 1.0.5/1.0.6 deve instalar/abrir o pacote recente manualmente uma vez.

Validação: três testes de seleção do empacotador, identidade dos binários,
metadados, licença e integridade das fontes. O pacote renomeado para
`CFLink-Windows-Full-install (2).exe` abriu a janela real **CFLink - Install**;
o teste a fechou sem aceitar instalação nem UAC.
A substituição da instalação real e uma sessão remota exigem validação no piloto.

| Sistema | Full / QS |
|---|---|
| Windows x64 | **1.0.8** |
| macOS Apple Silicon ARM64 | **1.0.2**, DMGs preservados |

Links estáveis preservados. Fontes Windows: `CFLink-1.0.8-source.zip`. Fontes
dos DMGs: `CFLink-1.0.2-source.zip`. Consulte `SHA256SUMS.txt` e
`release-manifest.json`. Os arquivos automáticos “Source code” deste
repositório de downloads contêm somente a documentação.

Base RustDesk 1.5.0, licença GNU AGPLv3; créditos preservados em **Sobre**.
