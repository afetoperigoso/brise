# Brise

Shell para Niri em Quickshell, com barra completa ou minimalista, Spotify, áudio por aplicativo, Bluetooth, wallpapers, clipboard e bandeja de aplicativos.

## Requisitos

- Quickshell com os módulos Niri, PipeWire, MPRIS, Bluetooth, SystemTray e BackgroundEffect. O pacote instalado precisa ser compatível com a versão do Qt do sistema.
- Python 3, dbus-python e PyGObject.
- PipeWire/WirePlumber (`wpctl`), BlueZ e wl-clipboard (`wl-copy`, `wl-paste`).
- Noto Sans para afeto. Tamzen8x16b já está incluída no genesis em `themes/genesis/fonts/`, com licença, e é carregada diretamente. Os ícones Tabler e sua licença estão em `fonts/`.
- Blur no afeto depende do suporte do compositor.

## Instalação

Coloque o projeto em `~/.config/quickshell/brise` ou mantenha seu checkout em outra pasta. Dentro da pasta do projeto, execute:

```bash
chmod +x brise install-command.sh
./install-command.sh
```

Isso instala um lançador em `~/.local/bin/brise` apontando para o projeto. Adicione `~/.local/bin` ao PATH se necessário. Se mover o projeto, atualize esse lançador. Não inicia serviços nem muda sua configuração do Niri.

```bash
~/.local/bin/brise start
~/.local/bin/brise stop
~/.local/bin/brise restart
```

## Temas

```bash
brise theme list       # Lista os temas instalados
brise theme            # Mostra o tema ativo
brise theme afeto
brise theme genesis
```

A troca é salva e recarregada automaticamente quando a shell está aberta. `afeto` é o padrão quando não existe uma seleção local.

- **afeto:** transparência com blur, fonte Noto Sans, cantos arredondados.
- **genesis:** preto opaco, fonte Tamzen bold, texto #DED6C5, quatro cantos recortados e pontas triangulares na barra minimalista e na bandeja.

Cada tema tem uma paleta independente em `themes/<nome>/Palette.qml`. Para criar outro, copie uma pasta de tema, use um nome com letras, números, hífen ou sublinhado e selecione com `brise theme <nome>`. Preserve as propriedades da paleta para manter compatibilidade com os componentes.

`Theme.qml` é gerado pelo comando de seleção e ignorado pelo Git. Preferências pessoais ficam em `preferences.ini`, também ignorado. Históricos e wallpaper selecionado ficam em `${XDG_STATE_HOME:-~/.local/state}/brise`.

## Iniciar com Niri

Adicione ao nível principal de `~/.config/niri/config.kdl`, fora de `binds`:

```kdl
spawn-sh-at-startup "~/.local/bin/brise start"
```

Se usar outra shell/barra, retire o comando de inicialização dela para evitar duas barras. Não é necessário iniciar um daemon separado para o clipboard da Brise.

Dentro do bloco `binds`, exemplos:

```kdl
Mod+V { spawn-sh "~/.local/bin/brise clipboard"; }
Mod+W { spawn-sh "~/.local/bin/brise wallpapers"; }
Mod+P { spawn-sh "~/.local/bin/brise power"; }
```

Substitua atalhos existentes com as mesmas teclas, em vez de duplicá-los. Comandos `dashboard`, `audio`, `bluetooth`, `tray`, `tray-settings` e `close` também estão disponíveis.

## Interações

- Relógio: clique esquerdo abre o calendário e Spotify; direito alterna entre barra completa e minimalista. A preferência é salva.
- Música: somente Spotify. Texto com faixa e artista e rolagem na barra minimalista. Na barra completa, a capa circular gira enquanto toca e para ao pausar.
- Bandeja: clique direito na barra, exceto no relógio, abre os ícones dos aplicativos. Clique esquerdo ativa o aplicativo; direito abre seu menu. A engrenagem escolhe os ícones visíveis na barra completa, a partir dos aplicativos registrados naquele momento.
- Áudio: cartões de entrada e saída, seleção de dispositivo e volume/mute por aplicativo. A entrada prioriza Starship/Matisse analógico quando disponível; outra entrada pode ser escolhida e salva.
- Bluetooth: busca de até 20 segundos, conexão, desconexão, opção Desemparelhar nos dispositivos pareados e pareamento com PIN/confirmação. Mantenha o painel aberto durante o pareamento.
- Wallpapers: painel central com miniaturas e atualização automática. Por padrão, busca em `~/Imagens` e pastas convencionais de wallpapers. A pasta pode ser alterada na paleta. Aplica a imagem a todos os monitores.
- Clipboard: textos e imagens copiados enquanto Brise está aberta; busca, setas e Enter ou clique para copiar. Cole normalmente com Ctrl+V. Até 80 itens e 10 MiB por item. Não importa históricos de outras shells.
- Energia: reiniciar, desligar e suspender. Clique novamente no mesmo ícone para confirmar.
- Painéis: Esc ou clique fora fecha.

## Desenvolvimento

`brise preview` abre uma composição e salva uma captura sem ativar ações de sistema. Componentes QML ficam na raiz; integrações em `DesktopState.qml` e helpers Python. A Brise usa os menus nativos dos aplicativos de bandeja; o arquivo principal já habilita QApplication.

Não inclui launcher, notificações de desktop ou lockscreen. A bandeja de aplicativos é distinta das notificações de desktop.
