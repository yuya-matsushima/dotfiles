#!/bin/bash

set -e

MODE=$1
if [[ $MODE == "" ]]; then
  MODE="link"
elif [[ $MODE != "unlink" ]]; then
  echo "link.sh: Invalid Argument"
  exit 1
fi

if [ ! -d $HOME/.config ]; then
  mkdir -p $HOME/.config
fi

CURRENT_DIR=`pwd`
OS=`uname -s`
# Linux (omarchy 等) では omarchy/ 配下の OS 別定義があればそちらを優先する
OVERLAY_DIR=$CURRENT_DIR/omarchy

TARGETS=( \
         ".gemrc" \
         ".config/mise/config.toml" \
         ".gitconfig" \
         "_.gitignore" \
         ".tmux" \
         ".tmux.conf" \
         ".vim" \
         ".vimrc" \
         ".vimrc.minimal" \
         ".gvimrc" \
         ".zsh" \
         ".zshrc" \
         ".zshenv" \
         ".psqlrc" \
         ".config/hypr/input.lua" \
         ".config/hypr/bindings.lua" \
         ".config/hypr/autostart.lua" \
         ".config/hypr/envs.lua" \
         ".config/hypr/fcitx-sync.conf" \
         ".config/ghostty" \
         ".local/bin/ghostty" \
         ".local/bin/hypr-fcitx-sync" \
         ".local/bin/omarchy-screensaver" \
         ".local/share/applications/com.mitchellh.ghostty.desktop" \
         ".config/nvim" \
         ".config/opencode" \
         ".hammerspoon" \
         ".markdownlint.yml" \
         ".claude/hooks" \
         ".claude/CLAUDE.md" \
         ".claude/statusline.sh" \
         ".codex/AGENTS.md" \
         ".codex/hooks" \
         ".agents/hooks" \
         ".pi/agent/settings.json" \
         ".pi/agent/keybindings.json" \
       )

# macOS 専用のターゲット (Linux では link しない)
DARWIN_ONLY=( \
              ".hammerspoon" \
              ".gvimrc" \
            )

# Linux / Omarchy 専用のターゲット (macOS では link しない)
LINUX_ONLY=( \
              ".config/hypr/input.lua" \
              ".config/hypr/bindings.lua" \
              ".config/hypr/autostart.lua" \
              ".config/hypr/envs.lua" \
              ".config/hypr/fcitx-sync.conf" \
              ".local/bin/ghostty" \
              ".local/bin/hypr-fcitx-sync" \
              ".local/bin/omarchy-screensaver" \
              ".local/share/applications/com.mitchellh.ghostty.desktop" \
            )

is_darwin_only() {
  local target
  for target in "${DARWIN_ONLY[@]}"; do
    [ "$target" = "$1" ] && return 0
  done
  return 1
}

is_linux_only() {
  local target
  for target in "${LINUX_ONLY[@]}"; do
    [ "$target" = "$1" ] && return 0
  done
  return 1
}

for TARGET in "${TARGETS[@]}"
do
  if [ "$OS" != "Darwin" ] && is_darwin_only "$TARGET"; then
    echo "skip (macOS only): $TARGET"
    continue
  fi

  if [ "$OS" = "Darwin" ] && is_linux_only "$TARGET"; then
    echo "skip (Linux only): $TARGET"
    continue
  fi

  SOURCE=$CURRENT_DIR/$TARGET
  # Linux で OS 別定義があれば差し替える (例: omarchy/.config/ghostty)
  if [ "$OS" != "Darwin" ] && [ -e "$OVERLAY_DIR/$TARGET" ]; then
    SOURCE=$OVERLAY_DIR/$TARGET
  fi

  DEST=$HOME/$TARGET
  # _. 始まりのファイルは . 始まりに変換
  if [[ ${TARGET:0:2} == "_." ]]; then
    DEST=$HOME/${TARGET:1}
  fi

  # .gitconfig は XDG 配置 (~/.config/git/config) にリンクする
  if [ "$TARGET" = ".gitconfig" ]; then
    DEST=$HOME/.config/git/config
  fi

  # .tmux.conf は Linux では XDG 配置 (~/.config/tmux/tmux.conf) にリンクする。
  # tmux 3.7 は ~/.tmux.conf と ~/.config/tmux/tmux.conf の両方を読み, XDG 側が
  # 後に適用されるため, omarchy 既定を上書きするには XDG 側に置く必要がある。
  if [ "$TARGET" = ".tmux.conf" ] && [ "$OS" != "Darwin" ]; then
    DEST=$HOME/.config/tmux/tmux.conf
  fi

  if [[ $MODE == "link" ]]; then
    if [ -L $DEST ]; then
      echo "exist: $DEST"
    elif [ -e $DEST ]; then
      # 実ファイル / 実ディレクトリが既にある場合は内容を失わないよう退避してから link する。
      # 退避先は $DEST.bak.<timestamp>。
      BACKUP="$DEST.bak.$(date +%Y%m%d%H%M%S)"
      echo "backup: $DEST -> $BACKUP"
      mv "$DEST" "$BACKUP"
      DEST_PARENT=$(dirname "$DEST")
      [ -d "$DEST_PARENT" ] || mkdir -p "$DEST_PARENT"
      echo "link: $DEST -> $SOURCE"
      ln -s "$SOURCE" "$DEST"
    else
      DEST_PARENT=$(dirname "$DEST")
      [ -d "$DEST_PARENT" ] || mkdir -p "$DEST_PARENT"
      echo "link: $DEST -> $SOURCE"
      ln -s "$SOURCE" "$DEST"
    fi
  else
    if [ -L $DEST ]; then
      echo "unlink: $DEST"
      unlink $DEST
    else
      echo "not-exist: $DEST"
    fi
  fi
done
