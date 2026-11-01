#!/usr/bin/env bash
# ==============================================================================
# 📱 SEN HỒNG BANK - KHỞI ĐỘNG MÁY ẢO ANDROID TỐI ƯU & MƯỢT MÀ (ZERO-LAG)
# ==============================================================================
set -e

AVD_NAME="Android13_Lightweight_20_9"
EMULATOR_BIN="$HOME/Android/Sdk/emulator/emulator"

if [ ! -f "$EMULATOR_BIN" ]; then
    echo "❌ Không tìm thấy Android emulator tại: $EMULATOR_BIN"
    exit 1
fi

echo "🚀 Đang kiểm tra / khởi động máy ảo Android: $AVD_NAME..."

# Nếu máy ảo chưa chạy thì bật mới
if ! adb devices | grep -q "emulator-"; then
    echo "⏳ Đang bật emulator nền (4GB RAM, SwiftShader Vulkan/GLES, GPU ổn định)..."
    DISPLAY="${DISPLAY:-:0.0}" "$EMULATOR_BIN" \
        -avd "$AVD_NAME" \
        -gpu swiftshader \
        -no-boot-anim \
        -camera-back none \
        -camera-front none \
        >/dev/null 2>&1 &
    
    echo "⏳ Đang đợi máy ảo kết nối ADB..."
    adb wait-for-device
fi

echo "⏳ Đang kiểm tra hệ thống Android..."
while [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" != "1" ]; do
    sleep 2
done

echo "⚙️ Áp dụng tối ưu độ mượt giao diện (Giảm độ trễ Animation)..."
adb shell settings put global window_animation_scale 0.5
adb shell settings put global transition_animation_scale 0.5
adb shell settings put global animator_duration_scale 0.5
adb shell settings put global stay_on_while_plugged_in 3

echo "🔌 Cầu nối mạng (Reverse Ports): 8080 (Gateway), 8081 (Identity), 5173 (Portal)..."
adb reverse tcp:8080 tcp:8080
adb reverse tcp:8081 tcp:8081
adb reverse tcp:5173 tcp:5173

echo "📲 Khởi chạy ứng dụng Sen Hồng Bank..."
adb shell monkey -p com.senhong.sen_hong_bank -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1

echo "✅ Máy ảo đã sẵn sàng và ứng dụng Sen Hồng Bank đã mở thành công!"

