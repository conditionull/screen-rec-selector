#!/usr/bin/env bash
PIDFILE="/tmp/monitor-recorder.pid"

if [ -f "$PIDFILE" ] && kill -0 "$(<"$PIDFILE")" 2>/dev/null; then
    START=$(stat -c %Y "$PIDFILE")
    NOW=$(date +%s)
    ELAPSED=$((NOW - START))
    printf '{"text":"⏺ %02d:%02d:%02d"}\n' $((ELAPSED/3600)) $((ELAPSED%3600/60)) $((ELAPSED%60))
else
    printf '{"text":""}\n'
fi
