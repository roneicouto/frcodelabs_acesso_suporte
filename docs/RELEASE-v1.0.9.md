## CF Link 1.0.9 — teste de atualização a partir da 1.0.8

Release para testar a atualização interna no Windows Full e QS. O aplicativo
passa a identificar a versão **1.0.9**, mantendo as funcionalidades da 1.0.8,
incluindo o instalador Full independente do nome do download e o novo rodapé.

### Como testar

1. Abra o **Full ou QS 1.0.8**.
2. Clique em **Verificar atualização** e depois em **Atualizar agora**.
3. Aguarde o download e confirme **Atualizar e reiniciar**.
4. No Full instalado, autorize o Windows quando solicitar administrador.
5. Confira **Versão 1.0.9**, feche e reabra pelo mesmo atalho/arquivo.

Ao aplicar, as conexões em andamento são interrompidas. Feche outras janelas
do mesmo portátil antes de confirmar. Também é possível cancelar o download
ou adiar a instalação. Quem usa 1.0.5/1.0.6 precisa instalar uma versão recente
manualmente para receber a correção da inicialização do atualizador.

| Sistema | Full / QS |
|---|---|
| Windows x64 | **1.0.9** |
| macOS Apple Silicon ARM64 | **1.0.2**, DMGs preservados |

Interface e pacotes Windows gerados com metadados 1.0.9. Bibliotecas nativas
Full/QS preservadas por perfil, pois não houve mudança funcional. A aplicação
real da atualização, incluindo serviço/UAC e sessão remota, cabe ao piloto.

Fontes Windows: `CFLink-1.0.9-source.zip`. Fontes dos DMGs:
`CFLink-1.0.2-source.zip`. Confira `SHA256SUMS.txt` e `release-manifest.json`.
Os arquivos automáticos “Source code” deste repositório de downloads contêm
somente a documentação. Use o ZIP CFLink correspondente para compilar.

Base RustDesk 1.5.0, GNU AGPLv3. Créditos e licença preservados em **Sobre**.
