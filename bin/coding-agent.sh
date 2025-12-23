#!/bin/bash

set -e

MODE=$1
if [[ $MODE == "" ]]; then
  MODE="link"
elif [[ $MODE != "unlink" ]]; then
  echo "coding-agent.sh: Invalid Argument"
  echo "Usage: coding-agent.sh [link|unlink]"
  exit 1
fi

CURRENT_DIR=`pwd`
AGENTS=("claude" "codex" "gemini")

for AGENT in "${AGENTS[@]}"
do
  SOURCE_BASE="$CURRENT_DIR/coding-agents/$AGENT"
  DEST_BASE="$HOME/.$AGENT"

  # ソースディレクトリが存在するか確認
  if [ ! -d "$SOURCE_BASE" ]; then
    continue
  fi

  # 親ディレクトリが存在しない場合は作成
  if [ ! -d "$DEST_BASE" ]; then
    mkdir -p "$DEST_BASE"
  fi

  # SOURCE_BASE 直下のディレクトリをリンク
  find "$SOURCE_BASE" -mindepth 1 -maxdepth 1 -type d -print0 | while IFS= read -r -d '' SOURCE_DIR
  do
    DIR_NAME=$(basename "$SOURCE_DIR")
    DEST_PATH="$DEST_BASE/$DIR_NAME"

    # リンク作成/削除処理
    if [[ $MODE == "link" ]]; then
      if [ -L "$DEST_PATH" ]; then
        echo "exist: $DEST_PATH"
      elif [ -e "$DEST_PATH" ]; then
        echo "skip (directory exists): $DEST_PATH"
      else
        echo "link: $DEST_PATH"
        ln -s "$SOURCE_DIR" "$DEST_PATH"
      fi
    else
      if [ -L "$DEST_PATH" ]; then
        echo "unlink: $DEST_PATH"
        unlink "$DEST_PATH"
      else
        echo "not-exist: $DEST_PATH"
      fi
    fi
  done
done
