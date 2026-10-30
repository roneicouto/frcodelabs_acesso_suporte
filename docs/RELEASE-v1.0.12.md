## CF Link 1.0.12 — serviço ausente preparado automaticamente

O **Full instalado no Windows** agora tenta preparar o serviço automaticamente
quando ele estiver ausente, usando a mesma rotina do botão **Iniciar Serviço**.
Ela registra o serviço, preserva o ID/configurações e reabre o aplicativo.
O rodapé mostra **Preparando serviço…** durante a operação.

Não é necessário clicar em **Reparar serviço** para essa primeira tentativa.
O Windows ainda pode solicitar autorização de administrador. Se a operação
falhar ou for recusada, o reparo manual permanece disponível.

Há proteção contra ciclos de reparo/reabertura: uma tentativa recente impede
nova tentativa automática por dois minutos, até que o serviço seja confirmado
ativo. Uma nova tentativa manual pode ser solicitada nesse intervalo.

Serviço existente e parado mantém a tentativa automática de início; serviço
ativo não é reiniciado. Caminho divergente continua com reparo manual.
**QS e Full portátil não instalam nem controlam serviços.**

O registro do serviço pode reabrir o Full e interromper conexões. A verificação
de atualizações ao abrir e as demais funcionalidades foram mantidas.

Validação: três testes de recuperação persistente, análise/compilação Flutter
e verificações dos pacotes/fontes. O serviço real do computador não foi parado
ou removido nesses testes. Registro/reparo real com UAC permanece para o piloto.

| Sistema | Full / QS |
|---|---|
| Windows x64 | **1.0.12** |
| macOS Apple Silicon ARM64 | **1.0.2**, DMGs preservados |

Fontes Windows: `CFLink-1.0.12-source.zip`. Fontes dos DMGs:
`CFLink-1.0.2-source.zip`. Confira `SHA256SUMS.txt` e `release-manifest.json`.
Os arquivos automáticos “Source code” do repositório de downloads contêm
somente a documentação; use o ZIP CFLink correspondente para compilar.

Base RustDesk 1.5.0, GNU AGPLv3; créditos preservados em **Sobre**.
