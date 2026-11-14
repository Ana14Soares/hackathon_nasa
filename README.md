# Exploradores Esquecidos (Godot 4.7)

Jogo narrativo 2D: a viajante Lyra encontra 7 equipamentos da NASA à deriva e guarda as histórias deles.
Abra a pasta no Godot 4.7 e aperte F5 (cena principal: `scenes/menu/main_menu.tscn`).

## Fluxo
Menu → História inicial (Lyra relembra o dia em que encontrou o Pioneer 10) → Encontro
(chegada → **scan**: o equipamento fala em 1ª pessoa → **diário** → fechamento) →
Placa Pioneer desbloqueia o **radar** → viagem (warp) ao próximo → … → Cena final com a Terra.

Equipamentos: Pioneer 10, Surveyor 3, Eagle (Apollo 11), Spirit, NEAR Shoemaker, Dawn, InSight.

## Regras de interface
- **Radar** sempre centralizado na tela. Na nave, o **Diário de bordo** fica no painel de controle,
  à esquerda do botão Radar solar; na tela do radar, fica à esquerda do mapa.
- **Personificação**: quando o equipamento se apresenta no scan, ganha um rostinho
  (`ui/cute_face/cute_face.gd`) que pisca e mexe a boca enquanto o texto do balão é digitado,
  na janela e na foto do balão. Posição e tamanho do rosto vêm de `face_position`/`face_size` no `.tres`.
- **Diário** no formato "Mission report": moldura desenhada em `ui/overlays/diary_frame.gd`, relatório
  (TYPE/LAUNCH/TARGET/OBJECTIVE, campo `report` do JSON), NOTES manuscritas da Lyra e uma aba por
  equipamento (as coletadas mostram a miniatura). Fontes: coloque `assets/fonts/mono.ttf` e
  `assets/fonts/handwriting.ttf` para fixá-las (necessário na exportação Web); sem elas usa fontes do sistema.
- **Pausa** no canto superior direito (ou tecla P): pausa o jogo e volta ao menu inicial.
- **Balões**: Lyra fala só com texto (sem foto); o equipamento fala com a foto dele.
- **Texto grande** (Acessibilidade): o tema global escala fontes e margens; o balão cresce
  para cima com o texto e, se passar de 50% da tela, rola em vez de cortar.

## Adicionar um equipamento (sem código)
1. Duplique uma pasta em `data/explorers/`.
2. Ajuste o `.tres` (sprite, fundo, `radar_position`, imagens com crédito).
3. Escreva `story.pt_BR.json` (falas `"who": "explorer"` = equipamento em 1ª pessoa).
4. Acrescente o `.tres` em `data/registry.tres`.
5. Rode `tools/content_linter.gd` (Arquivo → Executar) no editor.

## Pendências de conteúdo
- As imagens são **ilustrações provisórias**: troque as texturas dos `ImageRef` pelas imagens oficiais da NASA (com crédito e URL).
- Todas as fontes estão com `checked_on` vazio: uma pessoa precisa conferir cada fato na fonte e preencher `checked_on`/`checked_by`.
- Áudio é opcional: coloque `.ogg` em `assets/audio/music/<cena>.ogg` e `assets/audio/sfx/<chave>.ogg`.
