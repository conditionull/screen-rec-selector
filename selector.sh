#!/usr/bin/env bash
PIDFILE=/tmp/monitor-recorder.pid
LOGFILE=/tmp/monitor-recorder.log

if [ -f "$PIDFILE" ]; then
    PID=$(awk -F':' '{print $1}' < "$PIDFILE")
    OUTPUT=$(awk -F':' '{print $2}' < "$PIDFILE")
    if kill -0 "$PID" 2>/dev/null; then
        kill "$PID"

        wait "$PID" 2>/dev/null
        if command -v wl-copy >/dev/null 2>&1; then
          wl-copy --type text/uri-list <<< "file://$OUTPUT"
        fi
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
kitty --class recorder-picker -e bash -c "
(
  gpu-screen-recorder --list-monitors | awk -F'|' '{print \$1}'
  echo 'region'
  echo 'portal'
) | fzf --no-input --height 40% --layout=reverse --border \
  --border-label ' Select Output ' \
  --color 'list-label:#99cc99' \
  --color 'footer:#FF7276' \
  --footer $'Press ESC to exit - \033[97mVideos saved at ~/Videos\033[0m' > '$TMP_SELECTION'
  
  if [ -s '$TMP_SELECTION' ]; then
    printf 'medium\nhigh\nvery_high\nultra' \
      | fzf --no-input --height 30% --layout=reverse --border \
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

RECORDER_WINDOW="$SELECTION"
if [[ "$SELECTION" == "region" ]]; then
    region_geometry=$(slurp -f "%wx%h+%x+%y")
    [ -z "$region_geometry" ] && { notify-send "Region selection cancelled"; exit; }
    RECORDER_WINDOW="$region_geometry"
fi

TIMESTAMP=$(date +%Y-%m-%d.%H.%M.%S)
OUTPUT="$HOME/Videos/${SELECTION}_${TIMESTAMP}.mp4"

RECORDER_ARGS=(-w "$RECORDER_WINDOW" -f 60 -c mp4 -a default_output)
if [[ "$QUALITY" == "very_high" || "$QUALITY" == "ultra" ]]; then
    RECORDER_ARGS+=(-bm cbr -q 20000)
else
    # use native quality modes for medium/high
    RECORDER_ARGS+=(-bm qp -q "$QUALITY")
fi
RECORDER_ARGS+=(-o "$OUTPUT")

GSR_KMS_SERVER=$(command -v gsr-kms-server 2>/dev/null)
if [ -n "$GSR_KMS_SERVER" ] && command -v getcap >/dev/null 2>&1 && ! getcap "$GSR_KMS_SERVER" | grep -q cap_sys_admin; then
    kitty --class recorder-auth -e sudo setcap cap_sys_admin+ep "$GSR_KMS_SERVER"
    if [ $? -ne 0 ] || ! getcap "$GSR_KMS_SERVER" | grep -q cap_sys_admin; then
        notify-send "Recording cancelled" "gsr-kms-server still needs cap_sys_admin"
        echo "$(date) - gsr-kms-server missing cap_sys_admin" >> $LOGFILE
        exit 1
    fi
fi

gpu-screen-recorder "${RECORDER_ARGS[@]}" &
PID=$!

while true; do
    if [ -f "$OUTPUT" ] && kill -0 "$PID" 2>/dev/null; then
        echo "$PID:$OUTPUT" > $PIDFILE
        # notification below not needed when using waybar tray indicator
        # notify-send -t 2000 -u critical "Screen recording started on $SELECTION at $QUALITY quality"
        echo "Recording started on $SELECTION at $QUALITY quality at: $(date)" >> $LOGFILE
        break
    elif ! kill -0 "$PID" 2>/dev/null; then # if process w/ PID does not exist
        notify-send "Recording failed" "See $LOGFILE for details"
        echo "$(date) - gpu-screen-recorder failed to start" >> $LOGFILE
        rm "$PIDFILE"
        exit 1
    fi
    sleep 0.1
done
