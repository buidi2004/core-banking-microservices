#!/usr/bin/env bash
# ==============================================================================
# SEN HỒNG BANK - STOP NGROK TUNNEL
# ==============================================================================

echo "🛑 Đang dừng Ngrok Tunnel..."
systemctl --user stop ngrok 2>/dev/null || true
pkill -f "ngrok start" 2>/dev/null || true
pkill -f "ngrok http" 2>/dev/null || true
echo "✅ Đã tắt Ngrok Tunnel."

