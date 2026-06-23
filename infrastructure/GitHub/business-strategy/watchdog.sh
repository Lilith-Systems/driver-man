#!/bin/bash
# Netzach: Infinite Uptime Watchdog
# Restarts polsia.service if memory usage exceeds 2GB

SERVICE="polsia.service"
LIMIT_KB=$((2 * 1024 * 1024)) # 2GB in KB

echo "Starting Netzach Watchdog for $SERVICE (Limit: 2GB)"

while true; do
    # Get the Main PID of the service
    PID=$(systemctl show -p MainPID --value "$SERVICE" 2>/dev/null)
    
    if [[ "$PID" =~ ^[0-9]+$ ]] && [ "$PID" -gt 0 ]; then
        # Get memory usage in KB (RSS)
        MEM_KB=$(ps -o rss= -p "$PID" 2>/dev/null | tr -d ' ')
        
        if [ -n "$MEM_KB" ] && [ "$MEM_KB" -gt "$LIMIT_KB" ]; then
            echo "$(date): $SERVICE memory usage (${MEM_KB} KB) exceeded 2GB. Restarting..."
            systemctl restart "$SERVICE"
        fi
    fi
    
    # Check every 10 seconds
    sleep 10
done
