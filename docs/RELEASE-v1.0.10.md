## CF Link 1.0.10 — verificação ao abrir

Windows Full e QS agora consultam novas versões em **toda abertura da tela
principal**, mesmo que já tenham verificado nas últimas 24 horas.

A consulta acontece em segundo plano. Quando existe um pacote novo compatível,
o cartão informa a versão e oferece **Atualizar agora** ou **Mais tarde**.
Download e instalação continuam dependendo da confirmação do usuário.
Falhas de rede automáticas não impedem a abertura nem interrompem o suporte.

O botão **Verificar atualização** permanece disponível. Com o aplicativo aberto,
as consultas periódicas mantêm o intervalo de 24 horas já existente.

### Instalar e testar

Atualize a 1.0.9 pela consulta manual ou baixe o pacote desta release. Depois
de instalada a 1.0.10, a checagem inicial funcionará em cada nova abertura.
O aviso de uma versão posterior só aparecerá quando houver um pacote novo.

| Sistema | Full / QS |
|---|---|
| Windows x64 | **1.0.10** |
| macOS Apple Silicon ARM64 | **1.0.2**, DMGs preservados |

As correções do instalador Full e do atualizador foram mantidas. As regras
de acesso, as senhas e o servidor permanecem iguais.

Fontes Windows: `CFLink-1.0.10-source.zip`. Fontes dos DMGs:
`CFLink-1.0.2-source.zip`. Confira `SHA256SUMS.txt` e `release-manifest.json`.
Os arquivos automáticos “Source code” do repositório de downloads contêm
somente a documentação; use o ZIP CFLink correspondente para compilar.

Base RustDesk 1.5.0, GNU AGPLv3. Créditos preservados em **Sobre**.
