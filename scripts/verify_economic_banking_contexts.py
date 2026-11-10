#!/usr/bin/env python3
"""
Test Suite: Xác thực Ngữ Cảnh Kinh Tế, Thị Trường Tiền Tệ & Quản Trị Tài Chính Ngân Hàng
Đảm bảo AI Chatbot nắm vững kinh tế vĩ mô, lạm phát, lãi suất thực dương, DTI an toàn,
quản trị dòng tiền, phân bổ tài sản kim tự tháp và quy định ngoại hối NHNN.
"""

import json
import urllib.request
import sys

CHAT_URL = "http://localhost:8000/chat"

ECONOMIC_TEST_CASES = [
    {
        "name": "1. Lạm phát, Lãi suất thực dương & So sánh Vàng vs Tiết kiệm",
        "question": "Tình hình lạm phát hiện nay gửi tiết kiệm có bị mất giá không? Nên gửi tiết kiệm hay mua vàng?",
        "expected_steps": 5,
        "check_thought": ["MACRO_ECONOMICS", "Fisher", "CPI", "Thực dương"],
        "check_answer": ["lãi suất thực", "3.5%", "6.3%", "không hề bị mất giá", "thông tư 04"]
    },
    {
        "name": "2. Quản trị Nợ An Toàn DTI (Debt-To-Income) Theo Thu Nhập",
        "question": "Lương 15 triệu thì vay bao nhiêu là an toàn để không bị vỡ nợ?",
        "expected_steps": 5,
        "check_thought": ["MACRO_ECONOMICS", "DTI", "35%"],
        "check_answer": ["dti", "30% - 35%", "5.250.000", "2.860.000", "vùng siêu an toàn"]
    },
    {
        "name": "3. Quản trị Dòng Tiền & Quỹ Dự Phòng Khẩn Cấp (Emergency Fund)",
        "question": "Cá nhân và hộ kinh doanh nên quản trị dòng tiền và chuẩn bị quỹ dự phòng khẩn cấp bao nhiêu tháng?",
        "expected_steps": 5,
        "check_thought": ["MACRO_ECONOMICS", "Quỹ dự phòng khẩn cấp"],
        "check_answer": ["3 đến 6 tháng", "chi tiêu cơ bản", "tiết kiệm online"]
    },
    {
        "name": "4. Mô Hình Kim Tự Tháp Tài Chính & Phân Bổ Danh Mục",
        "question": "Mô hình kim tự tháp tài chính cá nhân khuyên phân bổ tài sản cho tiết kiệm, vàng và đầu tư thế nào?",
        "expected_steps": 5,
        "check_thought": ["MACRO_ECONOMICS", "Kim Tự Tháp"],
        "check_answer": ["50% - 60%", "20% - 30%", "10% - 15%", "phòng thủ"]
    },
    {
        "name": "5. Quản Lý Ngoại Hối & Chính Sách Tiền Gửi USD Lãi Suất 0%",
        "question": "Tại sao tiền gửi tiết kiệm USD tại ngân hàng lại có lãi suất 0% theo quy định của Ngân hàng Nhà nước?",
        "expected_steps": 5,
        "check_thought": ["Pháp lệnh Quản lý Ngoại hối", "0%/năm"],
        "check_answer": ["0%/năm", "ngân hàng nhà nước", "đô la hóa"]
    }
]

def run_tests():
    passed = 0
    total = len(ECONOMIC_TEST_CASES)

    print("=" * 75)
    print("📈 BẮT ĐẦU KIỂM THỬ TOÀN DIỆN NGỮ CẢNH KINH TẾ & TÀI CHÍNH NGÂN HÀNG")
    print("=" * 75)

    for idx, tc in enumerate(ECONOMIC_TEST_CASES, 1):
        print(f"\n▶ Test {idx}: {tc['name']}")
        print(f"  Câu hỏi: \"{tc['question']}\"")
        payload = json.dumps({"question": tc["question"]}).encode("utf-8")
        req = urllib.request.Request(CHAT_URL, data=payload, headers={"Content-Type": "application/json"})

        try:
            with urllib.request.urlopen(req, timeout=12) as resp:
                data = json.loads(resp.read().decode("utf-8"))
        except Exception as e:
            print(f"  ❌ LỖI KẾT NỐI API: {e}")
            continue

        thought_proc = data.get("thought_process") or ""
        steps = data.get("reasoning_steps") or []
        dur_ms = data.get("thinking_duration_ms") or 0.0
        ans = data.get("answer") or ""

        # Validate steps count
        if len(steps) != tc["expected_steps"]:
            print(f"  ❌ Thất bại: Số bước suy nghĩ là {len(steps)}, kỳ vọng {tc['expected_steps']}")
            continue

        # Validate thought keywords
        missing_thought_kw = [kw for kw in tc.get("check_thought", []) if kw.lower() not in thought_proc.lower()]
        if missing_thought_kw:
            print(f"  ❌ Thất bại: Thought process thiếu từ khóa {missing_thought_kw}")
            print(f"  Thought process snippet: {thought_proc[:250]}...")
            continue

        # Validate answer keywords
        missing_ans_kw = [kw for kw in tc.get("check_answer", []) if kw.lower() not in ans.lower()]
        if missing_ans_kw:
            print(f"  ❌ Thất bại: Câu trả lời thiếu từ khóa {missing_ans_kw}")
            print(f"  Answer snippet: {ans[:250]}...")
            continue

        print(f"  ✅ THÀNH CÔNG: Đã đối soát {dur_ms:.1f}ms, khớp toàn diện ngữ cảnh kinh tế & số liệu ngân hàng!")
        passed += 1

    print("\n" + "=" * 75)
    print(f"KẾT QUẢ NGHIỆM THU: {passed}/{total} Kịch bản PASS ({passed/total*100:.1f}%)")
    print("=" * 75)
    if passed == total:
        print("🎉 TẤT CẢ KỊCH BẢN KINH TẾ NGÂN HÀNG ĐẠT CHUẨN XUẤT SẮC!")
        sys.exit(0)
    else:
        print("⚠️ CÓ KỊCH BẢN CHƯA ĐẠT!")
        sys.exit(1)

if __name__ == "__main__":
    run_tests()
