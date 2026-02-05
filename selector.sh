#!/usr/bin/env bash
PIDFILE=/tmp/monitor-recorder.pid
LOGFILE=/tmp/monitor-recorder.log

if [ -f "$PIDFILE" ]; then
    OLD_PID=$(<"$PIDFILE")
    if kill -0 "$OLD_PID" 2>/dev/null; then
        kill "$OLD_PID"
        # notify-send -t 3000 -u critical "Recording stopped"
        echo "Recording stopped at: $(date)" >> $LOGFILE
    else
        # notify-send -t 3000 "Empty screen-recording PID file removed"
        echo "Empty PID file removed at: $(date)" >> $LOGFILE
    fi
    rm -f "$PIDFILE"
    exit
fi

TMP_SELECTION=$(mktemp)
TMP_QUALITY=$(mktemp)

# picker
kitty --class recorder-picker -e bash -c \
"gpu-screen-recorder --list-capture-options \
  | awk -F'|' '{print \$1}' \
  | fzf --height 40% --layout=reverse --border \
  --border-label ' Select Output ' \
  --color 'list-label:#99cc99' \
  --color 'footer:#FF7276' \
  --footer $'Press ESC to exit - \033[97mVideos saved at ~/Videos\033[0m' > '$TMP_SELECTION'
  
  if [ -s '$TMP_SELECTION' ]; then
    printf 'medium\nhigh\nvery_high\nultra' \
      | fzf --height 30% --layout=reverse --border \
      --border-label ' Select Quality ' \
      --footer 'Press ESC for default quality' \
      > '$TMP_QUALITY'
  fi
"

# add tempfile content into var then delete tempfile
SELECTION=$(<"$TMP_SELECTION")
QUALITY=$(<"$TMP_QUALITY")
rm "$TMP_SELECTION" "$TMP_QUALITY"

[ -z "$SELECTION" ] && exit
[ -z "$QUALITY" ] && QUALITY="very_high"

# handle region selection
REGION_ARG=""
if [[ "$SELECTION" == "region" ]]; then
    region_geometry=$(slurp -f "%wx%h+%x+%y")
    [ -z "$region_geometry" ] && { notify-send "Region selection cancelled"; exit; }
    REGION_ARG="-region $region_geometry"
fi

TIMESTAMP=$(date +%Y-%m-%d.%H.%M.%S)
OUTPUT="$HOME/Videos/${SELECTION}_${TIMESTAMP}.mp4"

BITRATE_MODE=""
BITRATE_VALUE=""
if [[ "$QUALITY" == "very_high" || "$QUALITY" == "ultra" ]]; then
    BITRATE_MODE="-bm cbr"
    BITRATE_VALUE="-q 20000" # kbps
    gpu-screen-recorder \
      -w "$SELECTION" \
      $REGION_ARG \
      -f 60 \
      -c mp4 \
      $BITRATE_MODE $BITRATE_VALUE \
      -a default_output \
      -o "$OUTPUT" &
else
    # use quality mode for medium/high
    gpu-screen-recorder \
      -w "$SELECTION" \
      $REGION_ARG \
      -f 60 \
      -c mp4 \
      -bm qp \
      -q "$QUALITY" \
      -a default_output \
      -o "$OUTPUT" &
fi

PID=$!
echo "$PID" > "$PIDFILE"

while true; do
    if [ -f "$OUTPUT" ]; then
        # notification below not needed when using waybar tray indicator
        # notify-send -t 2000 -u critical "Screen recording started on $SELECTION at $QUALITY quality"
        echo "Recording started on $SELECTION at $QUALITY quality at: $(date)" >> $LOGFILE
        break
    elif ! kill -0 "$PID" 2>/dev/null; then # if process w/ PID does not exist
        notify-send "Recording failed" "See $LOGFILE for details"
        echo "$(date) - gpu-screen-recorder failed to start" >> "$LOGFILE"
        rm "$PIDFILE"
        exit 1
    fi
    sleep 0.1
done
