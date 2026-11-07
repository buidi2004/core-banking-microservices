# Hướng Dẫn Vận Hành Hệ Thống 55 Con OpenCode & Lệnh Tắt / Khởi Động Lại

> [!NOTE]
> Hệ thống hiện tại đã mở rộng lên **55 Con OpenCode độc lập** (`con1` đến `con55`) và tích hợp **Daemon Cứu Hộ Tự Động (Auto-Rotator & Healer)** chạy ngầm 24/7 để giám sát, tự động phát hiện lỗi Rate Limit và hoán đổi ngay lập tức sang các model free đang online khỏe nhất.

---

## ⚡ CÁC LỆNH TẮT VÀ KHỞI ĐỘNG LẠI (QUAN TRỌNG)

### 1. Cách Tắt Toàn Bộ Hệ Thống (Dừng Sạch 100%)
Chỉ cần gõ lệnh duy nhất sau ở bất kỳ terminal nào:
```bash
opencode-stop
```
*(Hoặc dùng lệnh: `opencode-killall`)*

Lệnh này sẽ tự động:
* Tắt daemon Auto-Rotator cứu hộ ngầm.
* Dừng mọi tiến trình đang chạy trong dây chuyền `opencode-pipeline`.
* Đóng phiên Tmux `opencode-team`.
* Dọn sạch toàn bộ tiến trình con chạy ngầm và xóa các file khóa PID, giải phóng hoàn toàn RAM/CPU.

---

### 2. Cách Khởi Động Lại Toàn Bộ Hệ Thống Từ Đầu
Chỉ cần gõ lệnh duy nhất sau:
```bash
opencode-restart
```
*(Hoặc dùng lệnh: `opencode-start`)*

Lệnh này sẽ tự động:
1. Dọn dẹp tắt sạch các tiến trình cũ.
2. Kiểm tra và đồng bộ lại toàn bộ 55 profile con sang nhóm 5 Model Free Online khỏe nhất.
3. Kích hoạt lại Daemon **Auto-Rotator** chạy ngầm để chống Rate Limit 24/7.
4. Mở lại phiên Tmux `opencode-team` gồm 5 cửa sổ cho 5 con chính (`con1` đến `con5`).

---

## 3. Danh Sách 5 Model Free Khỏe Nhất (Đã Kiểm Chứng 100% Online)

Hệ thống tập trung vận hành xoay vòng trên 5 model free không bị nghẽn:
1. `opencode/minimax-m3.1-flash-free` ➔ Phản hồi siêu nhanh (gán cho **Con 1**)
2. `opencode/nemotron-3.5-lightning-free` ➔ Viết mã & giải quyết logic tốt (gán cho **Con 2**)
3. `opencode/longcat-2.5-preview-free` ➔ Đọc ngữ cảnh tài liệu dài (gán cho **Con 3**)
4. `opencode/nemotron-3-ultra-free` ➔ Kiểm thử QA & Unit test (gán cho **Con 4**)
5. `opencode/beam-free` ➔ Tốc độ tức thì, làm Review & Docs (gán cho **Con 5**)

---

## 4. Tool Tự Động Đổi Model: `opencode-auto-rotator`

Tool đã được tích hợp sẵn vào hệ thống và đang chạy ngầm (`daemon`) để bảo vệ:
* **Tự động quét cửa sổ Tmux:** Nếu bất kỳ cửa sổ nào bị dính dòng chữ `Error: Rate limit exceeded`, tool sẽ **tự động gửi lệnh đổi model ngay lập tức** trong cửa sổ đó.
* **Tự động cập nhật Config:** Cập nhật ngay file `opencode.json` của con đó sang model tiếp theo trong nhóm 5 model free.

### Các lệnh điều khiển Tool:
```bash
# Kiểm tra tình trạng và quét sửa lỗi tức thì
opencode-auto-rotator --fix

# Đo kiểm tra tốc độ phản hồi thực tế của 5 model free
opencode-auto-rotator --check

# Chuyển đổi thủ công 1 con sang model khác
opencode-auto-rotator --switch con1
```

---

## 5. Hệ Sinh Thái 55 Con OpenCode (`con1` -> `con55`)

Toàn bộ 55 con đều được phân chia đều đặn xoay vòng trên 5 model free:
* **5 Con Dây Chuyền Chính:**
  * **Con 1 (`con1`)**: `minimax-m3.1-flash-free`
  * **Con 2 (`con2`)**: `nemotron-3.5-lightning-free`
  * **Con 3 (`con3`)**: `longcat-2.5-preview-free`
  * **Con 4 (`con4`)**: `nemotron-3-ultra-free`
  * **Con 5 (`con5`)**: `beam-free`
* **50 Con Mở Rộng (`con6` -> `con55`):**
  * Được chia theo chu kỳ vòng xoay 5 model, mỗi con sở hữu thư mục Profile, Cache, SQLite DB riêng biệt trong `~/.opencode_profiles/`.

### Cách gọi:
* Dùng lệnh ngắn: `con1` đến `con55`
* Hoặc alias: `opencode1` đến `opencode55`

---

## 6. Các Phím Tắt Tiện Dụng

| Thao tác mong muốn | Lệnh gõ trên Terminal |
| :--- | :--- |
| **Khởi động lại toàn bộ hệ thống** | `opencode-restart` |
| **Tắt sạch toàn bộ hệ thống** | `opencode-stop` |
| **Vào giao diện chat 5 con chính (Tmux)** | `tmux attach -t opencode-team` *(hoặc `opencode-team`)* |
| **Xem bảng theo dõi đa nhiệm thời gian thực** | `opencode-monitor` |
| **Chạy dây chuyền tự động** | `opencode-pipeline "Nội dung nhiệm vụ"` |
| **Xem log cứu hộ của Auto-Rotator** | `tail -f ~/.opencode_profiles/rotator.log` |
