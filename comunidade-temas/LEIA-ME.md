# Temas do CypherOS

Este é o repositório da **Loja de temas** do CypherOS. A Central CypherOS lê o `index.json` daqui e mostra os temas para instalar com um clique.

## Publicar

Crie no GitHub o repositório `cypheros-temas` (público) e envie o conteúdo desta pasta. O endereço padrão da loja no CypherOS é:

```
https://raw.githubusercontent.com/sCypher-me/cypheros-temas/main/
```

Se usar outro nome ou conta, troque em Central › Loja de temas › Endereço da loja.

## Mandar um tema

1. No CypherOS, monte o visual que você gosta e use Central › Loja de temas › Exportar. O arquivo vai para `~/CypherOS-temas/`.
2. Coloque o arquivo em `temas/` e adicione uma linha em `index.json`.
3. Abra um pull request.

## Formato

```json
{
  "name": "Neon Tóquio",
  "author": "seu-nome",
  "bg": "#0A0614", "glass": "#160E26", "text": "#F5EEFF", "muted": "#B4A6CF",
  "accent": "#FF3EA5", "accent2": "#00E5FF", "hot": "#FFD23F", "ok": "#3DFFA2",
  "wallpaper": "pulso"
}
```

Só `bg` e `accent` são obrigatórios; o resto cai nas cores do Prisma. `wallpaper` pode ser aurora, nebulosa, particulas, ondas ou pulso. O nome do arquivo (sem `.json`) é o id do tema: use letras minúsculas, números e hífen.
