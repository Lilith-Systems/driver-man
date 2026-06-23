#!/usr/bin/env fish
# Lilith chat launcher — fish-native, no bash-isms, no recursive restart.
set -l LILITH_DIR_ENV "$LILITH_DIR"
set -g LILITH_DIR
if test -n "$LILITH_DIR_ENV"
    set -g LILITH_DIR (realpath "$LILITH_DIR_ENV")
else
    set -g LILITH_DIR /home/tehlappy/Desktop/Lilith
end
set -g MODELS_DIR "$LILITH_DIR/ollama-models"
set -g RAM_STAGING "/dev/shm/lilith"
set -g MODELFILE "$LILITH_DIR/Modelfile"
set -g SERVER_FILE "$LILITH_DIR/server/main.py"
set -g VENV "$LILITH_DIR/.venv"
set -g PY_BIN "$VENV/bin/python3"
if not set -q LILITH_PORT; or not string match -qr '^[0-9]+$' -- "$LILITH_PORT"
    set -g LILITH_PORT 3213
end
set -lx LILITH_MODEL lilith
set -lx LILITH_NUM_CTX 8192
set -lx LILITH_KEEP_ALIVE 30m
set -lx MSN_STATE_ROOT /home/tehlappy/Desktop/Lilith/state

function stage_to_ram
    echo "[lilith] staging model to $RAM_STAGING"
    mkdir -p "$RAM_STAGING"
    set -l MODEL_FILE "gemma-2b-coder-Q4_K_M.gguf"
    set -l SOURCE "$MODELS_DIR/$MODEL_FILE"
    set -l TARGET "$RAM_STAGING/$MODEL_FILE"
    if not test -f "$TARGET"; or test "$SOURCE" -nt "$TARGET"
        cp -a "$SOURCE" "$TARGET"
    end
    ln -sfn "$RAM_STAGING/$MODEL_FILE" "$RAM_STAGING/lilith_q8.gguf"
    ln -sfn "$RAM_STAGING/$MODEL_FILE" "$RAM_STAGING/lilith.gguf"
    ls -lh "$TARGET"
end

function ensure_ollama
    if ollama ps >/dev/null 2>&1
        return 0
    end

    echo "[lilith] starting ollama daemon"
    mkdir -p "$LILITH_DIR/logs"
    nohup ollama serve > "$LILITH_DIR/logs/ollama.log" 2>&1 &
    set -l ollama_pid $last_pid
    echo $ollama_pid > "$LILITH_DIR/.ollama.pid"

    for attempt in (seq 1 30)
        if curl -fsS http://127.0.0.1:11434/api/tags >/dev/null 2>&1
            return 0
        end
        sleep 1
    end

    echo "[lilith] ollama daemon did not become ready"
    return 1
end

function ensure_venv
    if not test -x "$PY_BIN"
        echo "[lilith] creating virtualenv"
        python3 -m venv "$VENV"
        "$PY_BIN" -m pip install -r "$LILITH_DIR/requirements.txt" -q
    end
end

function ensure_model
    echo "[lilith] registering/updating model from $MODELFILE"
    ollama create lilith -f "$MODELFILE"
end

function server_has_msn_routes
    if not curl -fsS "http://127.0.0.1:$LILITH_PORT/health" >/dev/null 2>&1
        return 1
    end
    if not curl -fsS "http://127.0.0.1:$LILITH_PORT/api/status" >/dev/null 2>&1
        return 1
    end
    return 0
end

function route_smoke_check
    set -l route_payload '{"prompt":"our LLM Lilith sucks i need you to work on The MSN skills symbiosis and integration"}'
    if not curl -fsS "http://127.0.0.1:$LILITH_PORT/api/msn/route" \
        -H 'content-type: application/json' \
        -d "$route_payload" 2>/dev/null | jq -e '(.selected_skills | length > 0) and (.selected_commands | length > 0) and ((.focus_categories | index("ops")) or (.focus_categories | index("memory")))' >/dev/null
        echo "[lilith] MSN route smoke check failed: unable to query /api/msn/route"
        return 1
    end
    echo "[lilith] MSN route smoke check passed"
    return 0
end

function maybe_start_server
    set -l launched 0
    if server_has_msn_routes
        set launched 1
    end
    if test -f "$LILITH_DIR/.server.pid"
        set -l server_pid (cat "$LILITH_DIR/.server.pid")
        if test -n "$server_pid"
            if kill -0 $server_pid 2>/dev/null
                if server_has_msn_routes
                    set launched 1
                else
                    echo "[lilith] stopping stale server PID $server_pid"
                    kill $server_pid
                    sleep 1
                end
            end
        end
    end

    if test $launched -eq 0
        echo "[lilith] starting server"
        env MSN_STATE_ROOT="$MSN_STATE_ROOT" nohup "$PY_BIN" -m uvicorn --app-dir "$LILITH_DIR" server.main:app --host 127.0.0.1 --port "$LILITH_PORT" --log-level info > "$LILITH_DIR/logs/server.log" 2>&1 &
        set -l spid $last_pid
        echo $spid > "$LILITH_DIR/.server.pid"
        echo "[lilith] server PID "$spid
        for attempt in (seq 1 20)
            if server_has_msn_routes
                break
            end
            sleep 1
        end
        curl -fsS "http://127.0.0.1:$LILITH_PORT/health" || true
    end
end

function ensure_logs_dir
    mkdir -p "$LILITH_DIR/logs"
end

# main
ensure_logs_dir
ensure_ollama
stage_to_ram
ensure_model
ensure_venv
maybe_start_server
if not route_smoke_check
    exit 1
end
echo "[lilith] ready: POST http://127.0.0.1:$LILITH_PORT/v1/chat with messages"
echo "Use: curl -sS http://127.0.0.1:$LILITH_PORT/v1/chat -H 'content-type: application/json' -d '{\"messages\":[{\"role\":\"user\",\"content\":\"hello\"}]}'"
