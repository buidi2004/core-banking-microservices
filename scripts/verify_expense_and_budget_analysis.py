#!/usr/bin/env python3
"""
Kiểm thử Toàn Diện Khả Năng Phân Tích Tiền Chi Tiêu Sinh Hoạt & Quản Lý Tài Chính Cá Nhân (PFM)
Ngân Hàng Số Sen Hồng Core Banking (48 Tài Liệu - 552 Chunks pgvector)

Mục tiêu kiểm thử:
1. Phân tích phân bổ ngân sách sinh hoạt theo Quy tắc 50/30/20 (50% Thiết yếu, 30% Mong muốn, 20% Tiết kiệm).
2. Mô hình 6 Chiếc Lọ (Jars System của T. Harv Eker: NEC 55%, LTSS 10%, FFA 10%, EDU 10%, PLAY 10%, GIVE 5%).
3. Kế hoạch ngân sách thực tế theo thu nhập (Lương 15 triệu, 25 triệu phân bổ thế nào).
4. Nhận diện các lỗ rò rỉ tài chính (Cà phê/trà sữa hàng ngày, Subscription định kỳ bị quên).
5. Tính năng Sổ Thu Chi Thông Minh & Báo cáo Phân tích Chi tiêu trên App Sen Hồng.
6. 100% phản hồi có câu dẫn tự nhiên kết nối sang gợi ý câu trả lời tiếp theo.
"""

import sys
import json
import urllib.request

BASE_URL = "http://localhost:8000"

EXPENSE_TEST_CASES = [
    {
        "name": "1. Phân tích chi tiêu sinh hoạt theo Quy tắc 50/30/20",
        "query": "Tôi muốn phân tích tiền chi tiêu sinh hoạt hàng tháng thì nên phân bổ ngân sách theo quy tắc 50/30/20 như thế nào?",
        "must_have": ["50/30/20", "thiết yếu", "mong muốn", "tiết kiệm", "ngân sách"],
        "expect_topic": "EXPENSES"
    },
    {
        "name": "2. Phương pháp quản lý tài chính 6 Chiếc Lọ (Jars System)",
        "query": "Phương pháp 6 chiếc lọ quản lý tiền sinh hoạt và chi tiêu chia các khoản như thế nào?",
        "must_have": ["6 chiếc lọ", "thiết yếu", "tự do tài chính", "giáo dục"],
        "expect_topic": "EXPENSES"
    },
    {
        "name": "3. Cảnh báo các lỗ rò rỉ chi tiêu và bội chi hàng tháng",
        "query": "Những khoản chi tiêu sinh hoạt nào dễ làm rò rỉ tài chính và gây bội chi cuối tháng?",
        "must_have": ["rò rỉ", "cà phê", "định kỳ", "bội chi"],
        "expect_topic": "EXPENSES"
    },
    {
        "name": "4. Tính năng Sổ thu chi & Quản lý chi tiêu trên App Sen Hồng",
        "query": "App Sen Hồng có tính năng tự động ghi chép sổ thu chi và cảnh báo hạn mức chi tiêu không?",
        "must_have": ["quản lý chi tiêu", "phân loại", "hạn mức", "80%"],
        "expect_topic": "EXPENSES"
    }
]

def run_tests():
    print("=" * 80)
    print("📊 KIỂM THỬ KHẢ NĂNG PHÂN TÍCH TIỀN CHI TIÊU SINH HOẠT & QUẢN LÝ TÀI CHÍNH (PFM)")
    print("=" * 80)

    total = len(EXPENSE_TEST_CASES)
    passed = 0

    for idx, tc in enumerate(EXPENSE_TEST_CASES, start=1):
        print(f"\n[{idx}/{total}] 🔍 KIỂM THỬ: {tc['name']}")
        print(f"   ❓ Câu hỏi: \"{tc['query']}\"")

        payload = json.dumps({
            "question": tc["query"],
            "user_id": f"test_expense_user_{idx}"
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
        sources = data.get("sources", [])
        quick_replies = data.get("quick_replies", [])
        action = data.get("suggested_action", {})

        print(f"   📄 Độ dài phản hồi: {len(answer)} ký tự, {len(answer.split())} từ")
        print(f"   📚 Nguồn trích dẫn: {sources}")
        print(f"   💡 Gợi ý kế tiếp: {quick_replies}")

        # 1. Kiểm tra từ khóa bắt buộc
        missing_kw = [kw for kw in tc["must_have"] if kw.lower() not in answer.lower()]
        if missing_kw:
            print(f"   ❌ LỖI: Thiếu các từ khóa phân tích chi tiêu quan trọng: {missing_kw}")
            print(f"   Trích đoạn câu trả lời:\n{answer[:250]}...")
            continue

        # 2. Kiểm tra câu cầu nối dẫn hướng sang câu trả lời tiếp theo
        has_bridge = any(k in answer.lower() for k in [
            "gợi ý bên dưới", "bấm chọn nhanh", "chọn gợi ý", "xem tiếp câu trả lời", "câu trả lời chi tiết"
        ])
        if not has_bridge:
            print(f"   ❌ LỖI: Thiếu câu cầu nối dẫn hướng sang câu trả lời tiếp theo!")
            continue

        # 3. Kiểm tra danh sách quick replies hữu ích
        if not quick_replies or len(quick_replies) < 2:
            print(f"   ❌ LỖI: Quick replies không đủ 2 gợi ý!")
            continue

        print(f"   ✅ ĐẠT: Phân tích chi tiêu sắc bén, chuẩn mực tài chính PFM, dẫn hướng tuyệt vời!")
        passed += 1

    print("\n" + "=" * 80)
    print(f"📊 KẾT QUẢ TỔNG HỢP: {passed}/{total} KỊCH BẢN PASS ({passed/total*100:.1f}%)")
    print("=" * 80)

    if passed == total:
        print("🎉 XUẤT SẮC: AI ĐÃ NẮM VỮNG VÀ PHÂN TÍCH TIỀN CHI TIÊU SINH HOẠT HOÀN HẢO!")
        sys.exit(0)
    else:
        sys.exit(1)

if __name__ == "__main__":
    run_tests()
