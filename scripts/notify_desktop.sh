#!/usr/bin/env bash
# notify_desktop.sh - クロスプラットフォーム デスクトップ通知 (macOS / Linux)
# Usage: notify_desktop.sh <title> <message> [sound]
#   sound: Glass (default) | Basso | Funk | Ping | Hero | Submarine など
#          - macOS では system sound 名として使用
#          - Linux では Basso のみ critical、それ以外は normal urgency

set -uo pipefail

TITLE="${1:-}"
MESSAGE="${2:-}"
SOUND="${3:-Glass}"

if [ -z "$TITLE" ] || [ -z "$MESSAGE" ]; then
  echo "Usage: $0 <title> <message> [sound]" >&2
  exit 1
fi

# noti優先（クロスプラットフォーム・独自バンドルIDで通知許可が安定）
if command -v noti >/dev/null 2>&1; then
  if noti -t "$TITLE" -m "$MESSAGE" >/dev/null 2>&1; then
    exit 0
  fi
fi

OS="$(uname -s)"

case "$OS" in
  Darwin)
    # macOS: osascript でクォートエスケープ対策しつつ通知
    osascript <<EOF 2>/dev/null
set theTitle to "$(printf '%s' "$TITLE" | sed 's/"/\\"/g')"
set theMessage to "$(printf '%s' "$MESSAGE" | sed 's/"/\\"/g')"
display notification theMessage with title theTitle sound name "$SOUND"
EOF
    ;;
  Linux)
    # Linux / Ubuntu: notify-send (libnotify)
    if command -v notify-send >/dev/null 2>&1; then
      case "$SOUND" in
        Basso) urgency="critical" ;;
        *)     urgency="normal"   ;;
      esac
      notify-send -u "$urgency" "$TITLE" "$MESSAGE"
    else
      echo "notify-send が見つからないじゃん。入れる: sudo apt-get install libnotify-bin" >&2
      exit 2
    fi
    ;;
  *)
    echo "未対応OS: $OS" >&2
    exit 3
    ;;
esac
