#!/usr/bin/env bash
# ==============================================================================
# SEN HỒNG BANK - START NGROK TUNNEL (PUBLIC INTERNET)
# ==============================================================================

export PATH="$HOME/.local/bin:$PATH"
DOMAIN="mutation-tubby-overstock.ngrok-free.dev"

if systemctl --user is-active ngrok >/dev/null 2>&1 || pgrep -f "ngrok start" >/dev/null 2>&1; then
    echo "✅ Ngrok tunnel đã đang hoạt động!"
    echo "🌐 Endpoint: https://$DOMAIN"
    exit 0
fi

echo "🚀 Đang khởi động Ngrok Service (https://$DOMAIN -> http://localhost:8080)..."
systemd-run --user --unit=ngrok /home/buidi/.local/bin/ngrok start --all

sleep 2
if systemctl --user is-active ngrok >/dev/null 2>&1; then
    echo "🎉 Ngrok Public Tunnel đã sẵn sàng 100%!"
    echo "🌐 URL Gateway: https://$DOMAIN"
    echo "📡 WebSocket:   wss://$DOMAIN/ws-native"
    echo "📊 Web UI:      http://127.0.0.1:4040"
else
    echo "⚠️ Ngrok đang khởi động, kiểm tra log: journalctl --user -u ngrok -f"
fi
