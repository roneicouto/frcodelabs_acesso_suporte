## CF Link 1.0.6 para Windows

Release para testar a atualização interna introduzida na **1.0.5**, com Full e
QS identificando a versão **1.0.6**. As funcionalidades e regras de conexão
permanecem iguais às da 1.0.5.

### Testar a partir da 1.0.5

1. Abra o Full ou QS **1.0.5** no Windows.
2. Clique em **Verificar atualização** e depois em **Atualizar aplicativo**.
3. Acompanhe o download e confirme **Atualizar e reiniciar**.
4. Autorize o Windows se o Full instalado solicitar administrador.
5. Confira **Versão 1.0.6** na tela principal. Feche e reabra pelo mesmo
   arquivo/atalho e confira que a versão permanece atualizada.

As conexões em andamento são interrompidas ao aplicar a atualização. Feche
outras janelas do mesmo portátil antes de confirmar. Também é possível
cancelar o download ou adiar a instalação.

Quem usa 1.0.4 ou anterior ainda precisa baixar e instalar/abrir manualmente
um pacote recente para ter o atualizador interno.

| Sistema | Versão Full / QS |
|---|---|
| Windows x64 | **1.0.6** |
| macOS Apple Silicon ARM64 | **1.0.2**, DMGs preservados |

Os links estáveis continuam iguais. Fontes Windows: `CFLink-1.0.6-source.zip`.
Fontes dos DMGs: `CFLink-1.0.2-source.zip`. Confira os hashes em `SHA256SUMS.txt`
e a identificação dos pacotes em `release-manifest.json`. Os arquivos
automáticos “Source code” deste repositório de downloads contêm apenas a
documentação; para compilar o aplicativo use o ZIP CFLink correspondente.

A interface e os pacotes Windows foram gerados com metadados 1.0.6. As
bibliotecas nativas Full e QS da 1.0.5 foram preservadas por perfil, pois não
houve mudança no código nativo. O teste interativo da atualização, incluindo
Full instalado/UAC e sessões remotas reais, cabe ao piloto.

Base RustDesk 1.5.0, licença GNU AGPLv3. Créditos e licença preservados no app.
