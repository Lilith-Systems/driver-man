#!/usr/bin/env fish
# Hermes fish launcher — one-shot test mode against the active Hermes install.

set -l PROMPT "say just one word: hello"
if set -q argv[1]
  set PROMPT $argv[1]
end

set -lx LILITH_DIR /home/tehlappy/Desktop/Lilith
set -l DESKTOP_PORT 3213
if set -q LILITH_PORT; and string match -qr '^[0-9]+$' -- "$LILITH_PORT"
    set DESKTOP_PORT $LILITH_PORT
end
set -gx LILITH_PORT $DESKTOP_PORT
set -gx LILITH_BRIDGE_URL "http://localhost:$DESKTOP_PORT"
fish /home/tehlappy/Desktop/Lilith/fish/run_lilith_chat.fish

function proxy_has_current_bridge
    set -l health_json (curl -fsS http://127.0.0.1:8888/health 2>/dev/null)
    if test $status -ne 0
        return 1
    end
    if string match -q "*\"bridge\":\"$LILITH_BRIDGE_URL\"*" -- $health_json
        return 0
    end
    return 1
end

function maybe_start_proxy
    if proxy_has_current_bridge
        return 0
    end
    set -l proxy_pid_file "$LILITH_DIR/.lilith-proxy.pid"
    if test -f "$proxy_pid_file"
        set -l proxy_pid (cat "$proxy_pid_file")
        if test -n "$proxy_pid"
            if kill -0 $proxy_pid 2>/dev/null
                if proxy_has_current_bridge
                    return 0
                else
                    echo "[hermes] stopping stale proxy PID $proxy_pid"
                    kill $proxy_pid
                    sleep 1
                end
            end
        end
    end

    echo "[hermes] starting lilith proxy"
    nohup /home/tehlappy/.hermes/hermes-agent/venv/bin/python \
        /home/tehlappy/.hermes/skills/integration/lilith-hermes-integration/scripts/lilith_openai_proxy.py \
        > "$LILITH_DIR/logs/lilith-proxy.log" 2>&1 &
    set -l proxy_pid $last_pid
    echo $proxy_pid > "$proxy_pid_file"
    sleep 2
    curl -fsS http://127.0.0.1:8888/health >/dev/null 2>&1 || true
end

maybe_start_proxy
set -l H /home/tehlappy/.local/bin/hermes
echo "[hermes] using $H"
exec $H -s metaconscious -z "$PROMPT"
