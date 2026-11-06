#!/usr/bin/env bash
# ==============================================================================
# SEN HỒNG BANK - ANDROID 13 EMULATOR LAUNCHER (TỐI ƯU SIÊU MƯỢT / ZERO LAG)
# ==============================================================================

export ANDROID_HOME=/home/buidi/Android/Sdk
export ANDROID_SDK_ROOT=/home/buidi/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator

# Tắt triệt để popup "Không phản hồi -> Bắt buộc thoát" của GNOME Ubuntu
gsettings set org.gnome.mutter check-alive-timeout 0 2>/dev/null || true

# Bắt buộc cho Ubuntu Wayland / X11 để hiển thị cửa sổ Qt mượt mà
export QT_QPA_PLATFORM=xcb

# Đồng nhất GPU rendering trên NVIDIA GeForce GTX 1650 (Tránh xung đột chéo với AMD iGPU)
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json

# Kiểm tra nếu máy ảo đã đang chạy
if adb devices | grep -q "emulator-5554"; then
    echo "✅ Máy ảo Android 13 (emulator-5554) đã đang chạy sẵn sàng!"
    adb -s emulator-5554 reverse tcp:8080 tcp:8080
    exit 0
fi

echo "🚀 Đang khởi động Android 13 Emulator (20:9 - 1080x2400) với GPU & KVM (Cold Boot - Zero Crash)..."

# Dùng systemd-run để tiến trình emulator sống độc lập, không bao giờ bị tắt khi đóng terminal
systemd-run --user --unit=android-emulator \
    emulator -avd Android13_20_9 \
    -accel on \
    -gpu host \
    -no-snapshot \
    -cores 4 \
    -memory 4096 \
    -netdelay none \
    -netspeed full \
    -camera-back none \
    -camera-front none > /tmp/android-emulator.log 2>&1 || \
nohup emulator -avd Android13_20_9 \
    -accel on \
    -gpu host \
    -no-snapshot \
    -cores 4 \
    -memory 4096 \
    -netdelay none \
    -netspeed full \
    -camera-back none \
    -camera-front none > /tmp/android-emulator.log 2>&1 &

EMU_PID=$!
disown $EMU_PID 2>/dev/null || true

echo "📱 Đã phát lệnh chạy máy ảo (PID: $EMU_PID)."
echo "   Xem log chi tiết tại: /tmp/android-emulator.log"
echo "⏳ Đang đợi thiết bị khởi động hoàn tất..."

(
    adb -s emulator-5554 wait-for-device
    while [ "$(adb -s emulator-5554 shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" != "1" ]; do
        sleep 2
    done
    # Tinh chỉnh độ nhạy chuyển cảnh (0.5x)
    adb -s emulator-5554 shell settings put global window_animation_scale 0.5
    adb -s emulator-5554 shell settings put global transition_animation_scale 0.5
    adb -s emulator-5554 shell settings put global animator_duration_scale 0.5
    # Cấu hình ADB reverse cho API Gateway
    adb -s emulator-5554 reverse tcp:8080 tcp:8080
    echo "🎉 Máy ảo Android 13 (20:9) đã khởi động thành công (Zero-Lag, 60 FPS)!"
) &
disown 2>/dev/null || true
