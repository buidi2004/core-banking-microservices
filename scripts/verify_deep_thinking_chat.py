#!/usr/bin/env python3
"""
Verification Script: Kiểm thử toàn diện Động cơ Suy Luận Sâu (Deep Thinking Engine)
và cơ chế kiểm chứng số học trên Chatbot Service (FastAPI).
"""

import json
import urllib.request
import urllib.error
import sys

CHAT_URL = "http://localhost:8000/chat"

TEST_CASES = [
    {
        "name": "1. Câu hỏi Tiết Kiệm (Tính toán số học + Thông tư 04)",
        "question": "Tôi muốn gửi tiết kiệm 100 triệu trong 12 tháng thì lãi bao nhiêu?",
        "expected_steps": 5,
        "check_thought": ["SAVINGS", "100.000.000", "6.3%"],
        "check_answer": ["6.3%/năm", "tiết kiệm"]
    },
    {
        "name": "2. Câu hỏi Vay Tiêu Dùng Quick Loan",
        "question": "Tôi muốn vay 30 triệu tiêu dùng thì thủ tục thế nào và lãi suất tính ra sao?",
        "expected_steps": 5,
        "check_thought": ["LOANS", "30.000.000", "Quick Loan"],
        "check_answer": ["1.2%", "dư nợ giảm dần"]
    },
    {
        "name": "3. Câu hỏi Sinh Trắc Học QĐ 2345",
        "question": "Hạn mức chuyển tiền bao nhiêu thì bắt buộc quét khuôn mặt theo Quyết định 2345?",
        "expected_steps": 5,
        "check_thought": ["BIOMETRICS", "2345/QĐ-NHNN"],
        "check_answer": ["10 triệu", "20 triệu"]
    },
    {
        "name": "4. Câu hỏi Thẻ Ảo Visa Platinum Virtual",
        "question": "App có mở thẻ ảo Visa không và phí thường niên thế nào?",
        "expected_steps": 5,
        "check_thought": ["CARDS", "Visa Platinum Virtual"],
        "check_answer": ["miễn phí", "visa platinum"]
    },
    {
        "name": "5. Câu hỏi Dài Đa Ý Định (Long Compound Query)",
        "question": "Tôi đang có 200 triệu trong tài khoản, tôi muốn hỏi là gửi tiết kiệm online 12 tháng hay 24 tháng thì lãi suất cao hơn, và nếu giữa chừng tôi cần tiền rút ra một phần thì có bị mất hết tiền lãi không?",
        "expected_steps": 5,
        "check_thought": ["Thông tư 04/2022/TT-NHNN"],
        "check_answer": ["6.3%", "6.8%", "không bị mất hết"]
    }
]

def run_tests():
    passed = 0
    total = len(TEST_CASES)

    print("=" * 70)
    print("🚀 BẮT ĐẦU KIỂM THỬ DEEP THINKING & REASONING ENGINE TRÊN CORE BANKING")
    print("=" * 70)

    for idx, tc in enumerate(TEST_CASES, 1):
        print(f"\n▶ Test Case {idx}: {tc['name']}")
        print(f"  Câu hỏi: \"{tc['question']}\"")
        payload = json.dumps({"question": tc["question"]}).encode("utf-8")
        req = urllib.request.Request(CHAT_URL, data=payload, headers={"Content-Type": "application/json"})

        try:
            with urllib.request.urlopen(req, timeout=10) as resp:
                data = json.loads(resp.read().decode("utf-8"))
        except Exception as e:
            print(f"  ❌ LỖI KẾT NỐI: {e}")
            continue

        thought_proc = data.get("thought_process") or ""
        steps = data.get("reasoning_steps") or []
        dur_ms = data.get("thinking_duration_ms") or 0.0
        conf = data.get("confidence_score") or 0.0
        ans = data.get("answer") or ""

        # Validate steps count
        if len(steps) != tc["expected_steps"]:
            print(f"  ❌ Thất bại: Số bước suy nghĩ là {len(steps)}, kỳ vọng {tc['expected_steps']}")
            continue

        # Validate thinking duration
        if dur_ms < 400.0:
            print(f"  ❌ Thất bại: Thời gian suy nghĩ quá ngắn ({dur_ms}ms)")
            continue

        # Validate thought keywords
        missing_thought_kw = [kw for kw in tc.get("check_thought", []) if kw.lower() not in thought_proc.lower()]
        if missing_thought_kw:
            print(f"  ❌ Thất bại: Thought process thiếu từ khóa {missing_thought_kw}")
            continue

        # Validate answer keywords
        missing_ans_kw = [kw for kw in tc.get("check_answer", []) if kw.lower() not in ans.lower()]
        if missing_ans_kw:
            print(f"  ❌ Thất bại: Câu trả lời thiếu từ khóa {missing_ans_kw}")
            continue

        print(f"  ✅ THÀNH CÔNG: Đã suy nghĩ {dur_ms:.1f}ms, độ tin cậy {conf:.2f}, 5 bước suy luận rõ ràng!")
        passed += 1

    print("\n" + "=" * 70)
    print(f"KẾT QUẢ: {passed}/{total} Test Cases PASS ({passed/total*100:.1f}%)")
    print("=" * 70)
    if passed == total:
        print("🎉 TẤT CẢ KIỂM THỬ DEEP THINKING ENGINE ĐÃ ĐẠT TIÊU CHUẨN XUẤT SẮC!")
        sys.exit(0)
    else:
        print("⚠️ CÓ TEST THẤT BẠI!")
        sys.exit(1)

if __name__ == "__main__":
    run_tests()
