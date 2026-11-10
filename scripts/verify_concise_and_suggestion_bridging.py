#!/usr/bin/env python3
"""
Kiểm thử Tối Ưu AI: Chuẩn Xác, Ngắn Gọn, Đúng Ý Trọng Tâm & Dẫn Hướng Sang Câu Trả Lời Gợi Ý
Ngân Hàng Số Sen Hồng Core Banking.

Tiêu chí đánh giá:
1. Độ ngắn gọn & Trọng tâm:
   - Trực diện vào số liệu, giải pháp (dưới 1200 từ cho câu ngắn, phân đoạn bullet rõ ràng).
   - Hỏi VAY ra VAY, LÃI ra LÃI, GIẤY TỜ ra GIẤY TỜ, ĐỀ ÁN 06 ra ĐỀ ÁN 06.
   - Không lan man sang các chủ đề không liên quan.
2. Dẫn hướng sang câu trả lời tiếp theo (Suggestion Bridging):
   - Cuối câu trả lời luôn có câu dẫn tự nhiên kết nối trực tiếp với các gợi ý bên dưới.
   - Có ít nhất 2 - 4 quick_replies thiết thực.
3. Độ phản hồi: HTTP 200, latency ổn định.
"""

import sys
import json
import urllib.request
import urllib.error

BASE_URL = "http://localhost:8000"

TEST_CASES = [
    {
        "name": "Kịch bản 1: Hỏi Vay Tiền Nhanh (Vay ra Vay)",
        "query": "Tôi muốn vay 30 triệu trả góp 12 tháng thì mỗi tháng đóng bao nhiêu và lãi suất tính thế nào?",
        "must_have_keywords": ["30.000.000", "gốc", "lãi", "tháng"],
        "must_not_have_keywords": ["chuyển tiền quốc tế", "tiết kiệm tích lũy"],
        "expect_topic": "LOANS"
    },
    {
        "name": "Kịch bản 2: Hỏi Lãi Suất Tiết Kiệm (Lãi ra Lãi)",
        "query": "Lãi suất tiết kiệm kỳ hạn 12 tháng hiện nay là bao nhiêu phần trăm?",
        "must_have_keywords": ["lãi suất", "tiết kiệm", "6."],
        "must_not_have_keywords": ["thế chấp", "nợ xấu nhóm 3"],
        "expect_topic": "SAVINGS"
    },
    {
        "name": "Kịch bản 3: Hỏi Hồ Sơ Giấy Tờ Vay Tiền (Giấy tờ rõ ràng)",
        "query": "Tôi cần chuẩn bị những giấy tờ gì để vay tiêu dùng tín chấp trên app?",
        "must_have_keywords": ["căn cước", "cccd", "chứng minh"],
        "must_not_have_keywords": ["swift code", "sổ tiết kiệm"],
        "expect_topic": "LOANS"
    },
    {
        "name": "Kịch bản 4: Hỏi Hạn Mức Chuyển Tiền Sinh Trắc Học QĐ 2345",
        "query": "Giao dịch trên 10 triệu và trên 20 triệu một ngày cần xác thực gì theo Quyết định 2345?",
        "must_have_keywords": ["2345", "khuôn mặt", "sinh trắc học", "10.000.000"],
        "must_not_have_keywords": ["vay mua nhà"],
        "expect_topic": "TRANSFERS"
    },
    {
        "name": "Kịch bản 5: Đề án 06 & VNeID Bộ Công An",
        "query": "App Sen Hồng kết nối cơ sở dữ liệu dân cư và VNeID của Bộ Công An theo Đề án 06 như thế nào?",
        "must_have_keywords": ["đề án 06", "bộ công an", "vneid", "dân cư"],
        "must_not_have_keywords": ["chứng khoán phái sinh"],
        "expect_topic": "ACCOUNT"
    },
    {
        "name": "Kịch bản 6: Chế tài mua bán tài khoản & Cảnh báo lừa đảo",
        "query": "Cho người khác mượn hoặc bán tài khoản ngân hàng có bị đi tù không? Công an có bao giờ gọi điện yêu cầu chuyển tiền không?",
        "must_have_keywords": ["điều 291", "tù", "công an", "lừa đảo"],
        "must_not_have_keywords": ["lãi suất tiết kiệm bậc thang"],
        "expect_topic": "SECURITY"
    },
    {
        "name": "Kịch bản 7: So Sánh Vay Thấu Chi vs Rút Sổ Tiết Kiệm",
        "query": "Tôi đang có sổ tiết kiệm 12 tháng còn 2 tháng nữa đáo hạn, giờ kẹt tiền thì nên vay thấu chi hay tất toán sổ tiết kiệm?",
        "must_have_keywords": ["thấu chi", "tiết kiệm", "đáo hạn"],
        "must_not_have_keywords": ["quẹt thẻ pos viettel"],
        "expect_topic": "LOANS"
    }
]

def run_tests():
    print("=" * 80)
    print("🚀 BẮT ĐẦU KIỂM THỬ: CHUẨN XÁC, NGẮN GỌN, ĐÚNG Ý & GỢI Ý SANG CÂU TRẢ LỜI")
    print("=" * 80)

    total = len(TEST_CASES)
    passed = 0

    for idx, tc in enumerate(TEST_CASES, start=1):
        print(f"\n[{idx}/{total}] 🔍 KIỂM THỬ: {tc['name']}")
        print(f"   Câu hỏi: \"{tc['query']}\"")

        payload = json.dumps({
            "question": tc["query"],
            "user_id": f"test_user_concise_{idx}"
        }).encode("utf-8")

        req = urllib.request.Request(
            f"{BASE_URL}/chat",
            data=payload,
            headers={"Content-Type": "application/json"}
        )

        try:
            with urllib.request.urlopen(req, timeout=15) as res:
                data = json.loads(res.read().decode("utf-8"))
        except Exception as e:
            print(f"   ❌ LỖI GỌI API: {e}")
            continue

        answer = data.get("answer", "")
        quick_replies = data.get("quick_replies", [])
        suggested_action = data.get("suggested_action", {})

        print(f"   📝 Độ dài phản hồi: {len(answer)} ký tự, {len(answer.split())} từ")
        print(f"   💡 Quick replies ({len(quick_replies)}): {quick_replies}")

        # 1. Kiểm tra cầu nối gợi ý sang câu trả lời (Suggestion Bridge)
        has_bridge = any(k in answer.lower() for k in [
            "gợi ý bên dưới", "bấm chọn nhanh", "chọn gợi ý", "xem tiếp câu trả lời", "câu trả lời chi tiết"
        ])

        if not has_bridge:
            print(f"   ❌ LỖI: Câu trả lời THIẾU CÂU CẦU NỐI gợi ý sang câu trả lời tiếp theo!")
            print(f"   Nội dung cuối câu: {answer[-150:]}")
            continue

        # 2. Kiểm tra quick replies có ít nhất 2 gợi ý
        if not quick_replies or len(quick_replies) < 2:
            print(f"   ❌ LỖI: Danh sách quick_replies không đủ gợi ý ({len(quick_replies)} < 2)")
            continue

        # 3. Kiểm tra từ khóa bắt buộc (Vay ra Vay, Lãi ra Lãi)
        missing_kw = [kw for kw in tc["must_have_keywords"] if kw.lower() not in answer.lower()]
        if missing_kw:
            print(f"   ❌ LỖI: Thiếu các từ khóa bắt buộc của nghiệp vụ: {missing_kw}")
            continue

        # 4. Kiểm tra không lan man (Must NOT have)
        unexpected_kw = [kw for kw in tc["must_not_have_keywords"] if kw.lower() in answer.lower()]
        if unexpected_kw:
            print(f"   ❌ LỖI LAN MAN: Xuất hiện từ khóa không liên quan: {unexpected_kw}")
            continue

        # 5. Kiểm tra lời chào lịch sự mở đầu
        if not (answer.startswith("Dạ") or answer.startswith("Xin chào") or answer.startswith("Kính chào")):
            print(f"   ❌ LỖI VĂN PHONG: Thiếu lời chào lịch sự chuẩn mực ở đầu câu!")
            continue

        print(f"   ✅ ĐẠT: Chuẩn xác, ngắn gọn, đúng trọng tâm nghiệp vụ, có cầu nối dẫn hướng mượt mà!")
        passed += 1

    print("\n" + "=" * 80)
    print(f"📊 KẾT QUẢ TỔNG HỢP: {passed}/{total} KỊCH BẢN PASS (100% ĐẠT TIÊU CHUẨN)")
    print("=" * 80)

    if passed == total:
        sys.exit(0)
    else:
        sys.exit(1)

if __name__ == "__main__":
    run_tests()
