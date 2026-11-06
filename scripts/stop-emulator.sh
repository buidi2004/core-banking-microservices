#!/usr/bin/env bash
# ==============================================================================
# SEN HỒNG BANK - STOP ANDROID EMULATOR
# ==============================================================================

export ANDROID_HOME=/home/buidi/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator

if adb devices | grep -q "emulator"; then
    echo "🛑 Đang tắt máy ảo Android..."
    adb emu kill 2>/dev/null || true
    systemctl --user stop android-emulator 2>/dev/null || true
    pkill -f "emulator.*Android13_20_9" 2>/dev/null || true
    echo "✅ Đã tắt máy ảo an toàn."
else
    echo "ℹ️  Không có máy ảo nào đang chạy."
fi

