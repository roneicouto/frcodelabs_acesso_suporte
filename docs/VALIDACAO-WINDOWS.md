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
| Full e QS abrem em dark, inclusive com Windows no tema claro | Pendente |
| Não há seletor de tema claro ou do sistema | Pendente |
| “Sobre / Licenças” funciona no Full e no QS e mostra a licença completa | Pendente |
| Banner RustDesk oculto na tela principal; créditos preservados na seção legal | Pendente |
| QS impede iniciar conexão e inversão de lados | Pendente |
| Fechar a janela QS encerra a disponibilidade para suporte | Pendente |
| Servidor, relay e chave não podem ser alterados na interface | Pendente |
| Full e QS mantêm suas preferências separadas | Pendente |

Use `dist/windows/CFLink-1.0.2-install.exe` para Full e
`dist/windows/CFLinkQS-1.0.2.exe` para QS. Cada computador deve executar uma única
instância de cada perfil durante o teste. Não use um cliente configurado para o
servidor público como destino do teste Full.

O código está no repositório `cdlawliet/CFLink`, publicado por solicitação do
responsável pelo projeto. A publicação não comprova o funcionamento remoto:
os testes acima continuam pendentes até serem realizados e registrados.
A obtenção do projeto e a compilação no MacBook seguem `docs/MACBOOK.md`.
