## CF Link 1.0.13 — senhas salvas e sessões recentes

O Full volta a oferecer **Lembrar senha** no diálogo de conexão. A senha deve
ser digitada no primeiro acesso; somente marcar essa opção autoriza seu
armazenamento e uso nas próximas conexões daquele computador. A senha padrão
incorporada para receber suporte não é enviada automaticamente pelo Full.

Corrigido o carregamento de **sessões recentes e favoritos** quando a pasta
Documentos não está disponível, por exemplo após redirecionamento do OneDrive.
O Full usa sua pasta de configuração como alternativa, permitindo ler os
registros já existentes. Não é necessário apagar configurações nem trocar o ID.
Sessões que não chegaram a ser gravadas precisarão de um novo acesso.

Mantidos servidor fixo, tema escuro, senha temporária, aprovação local,
verificação de atualizações e preparação automática do serviço do Full.
O QS permanece portátil e somente recebe conexões.

Validação: quatro testes nativos passaram. Uma verificação Dart/Rust confirmou
a leitura dos registros existentes sem Documentos, reproduzindo antes a lista
vazia. A reconexão real com senha salva permanece para validação no piloto.

| Sistema | Full / QS |
|---|---|
| Windows x64 | **1.0.13** |
| macOS Apple Silicon ARM64 | **1.0.2**, DMGs preservados |

Fontes Windows: `CFLink-1.0.13-source.zip`. Fontes dos DMGs:
`CFLink-1.0.2-source.zip`. Confira `SHA256SUMS.txt` e `release-manifest.json`.
Os arquivos automáticos “Source code” do repositório de downloads contêm
somente a documentação; use o ZIP CFLink correspondente para compilar.

Base RustDesk 1.5.0, GNU AGPLv3; créditos preservados em **Sobre**.
