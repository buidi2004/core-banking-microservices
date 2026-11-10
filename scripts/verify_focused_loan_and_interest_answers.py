#!/usr/bin/env python3
"""
Test Suite: Kiểm thử Tối ưu Phản hồi Đúng Trọng Tâm
"VAY RA VAY, LÃI RA LÃI, KHÔNG TRẢ LỜI LAN MAN"
Đảm bảo:
- Hỏi Vay -> Trả lời 100% về Vay, tuyệt đối KHÔNG nói lan man tiết kiệm.
- Hỏi Tiết kiệm -> Trả lời 100% về Tiết kiệm, tuyệt đối KHÔNG nói lan man vay nợ.
- Hỏi Lãi suất vay -> Trả lời 1.2% - 1.5%/tháng dư nợ giảm dần, không đá sang lãi suất tiết kiệm.
- Hỏi Lãi suất tiết kiệm -> Trả lời biểu lãi suất 3.8% - 6.8%/năm, không đá sang lãi suất vay.
"""

import sys
import json
import urllib.request
import urllib.error

API_URL = "http://localhost:8000/chat"

TEST_CASES = [
    {
        "name": "TC1: Hỏi tính tiền trả góp khoản vay (VAY RA VAY - CẤM LAN MAN TIẾT KIỆM)",
        "query": "Tôi muốn vay 30 triệu thì mỗi tháng trả bao nhiêu?",
        "must_include": ["30.000.000", "1.2%", "dư nợ giảm dần", "2.500.000", "/bills/quick-loan"],
        "must_NOT_include": ["mở sổ tiết kiệm", "kế hoạch gửi tiết kiệm", "6.3%/năm", "/bills/savings"]
    },
    {
        "name": "TC2: Hỏi Lãi suất vay Quick Loan (LÃI VAY RA LÃI VAY - CẤM ĐÁ SANG TIẾT KIỆM)",
        "query": "Lãi suất vay tiêu dùng Quick Loan hiện nay là bao nhiêu một tháng?",
        "must_include": ["1.2%", "dư nợ giảm dần", "tất toán trước hạn", "/bills/quick-loan"],
        "must_NOT_include": ["6.3%/năm", "6.8%/năm", "mở sổ tiết kiệm", "/bills/savings"]
    },
    {
        "name": "TC3: Hỏi tính tiền lãi gửi tiết kiệm (TIẾT KIỆM RA TIẾT KIỆM - CẤM LAN MAN VAY NỢ)",
        "query": "Có 100 triệu gửi tiết kiệm 12 tháng thì lãi bao nhiêu tiền?",
        "must_include": ["100.000.000", "6.3%", "tiết kiệm", "/bills/savings"],
        "must_NOT_include": ["quick loan", "khoản vay tương ứng", "vay tiêu dùng", "/bills/quick-loan"]
    },
    {
        "name": "TC4: Hỏi Lãi suất gửi tiết kiệm (LÃI TIẾT KIỆM RA LÃI TIẾT KIỆM - CẤM ĐÁ SANG VAY)",
        "query": "Biểu lãi suất tiền gửi tiết kiệm online hiện nay là bao nhiêu?",
        "must_include": ["3.8%/năm", "5.5%/năm", "6.3%/năm", "6.8%/năm", "/bills/savings"],
        "must_NOT_include": ["quick loan", "1.2%/tháng", "dư nợ giảm dần", "/bills/quick-loan"]
    },
    {
        "name": "TC5: Hỏi hạn mức gói vay (VAY RA VAY)",
        "query": "Hạn mức vay gói Quick Loan tối đa là bao nhiêu tiền?",
        "must_include": ["50.000.000", "5.000.000", "quick loan", "/bills/quick-loan"],
        "must_NOT_include": ["tiết kiệm online", "sổ tiết kiệm", "/bills/savings"]
    },
    {
        "name": "TC6: Hỏi so sánh 2 chiều (Chỉ khi hỏi cả hai mới so sánh)",
        "query": "Tôi đang phân vân nên gửi tiết kiệm hay vay vốn, hãy so sánh giúp tôi",
        "must_include": ["tiết kiệm", "vay", "6.3%", "1.2%"],
        "must_NOT_include": []
    }
]


def send_chat_query(query: str):
    payload = {
        "question": query,
        "history": []
    }
    req = urllib.request.Request(
        API_URL,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"}
    )
    with urllib.request.urlopen(req, timeout=15) as resp:
        return json.loads(resp.read().decode("utf-8"))


def run_tests():
    print("=" * 80)
    print("🎯 KIỂM THỬ TRỌNG TÂM: VAY RA VAY, LÃI RA LÃI, KHÔNG TRẢ LỜI LAN MAN")
    print("=" * 80)

    total = len(TEST_CASES)
    passed = 0

    for idx, tc in enumerate(TEST_CASES, 1):
        print(f"\n[{idx}/{total}] Đang kiểm thử: {tc['name']}")
        print(f"  👉 Query: \"{tc['query']}\"")
        try:
            resp = send_chat_query(tc["query"])
            answer = resp.get("answer", "")
            action = resp.get("suggested_action") or {}
            thought = resp.get("thought_process", "")
            replies = resp.get("quick_replies", [])

            # Gộp text để kiểm tra
            full_text = (answer + " " + json.dumps(action) + " " + json.dumps(replies)).lower()

            # 1. Kiểm tra từ khóa BẮT BUỘC có
            missing_keywords = [k for k in tc["must_include"] if k.lower() not in full_text]
            if missing_keywords:
                print(f"  ❌ THẤT BẠI: Thiếu từ khóa trọng tâm: {missing_keywords}")
                print(f"  [Phản hồi]: {answer[:250]}...")
                continue

            # 2. Kiểm tra từ khóa CẤM có (chống lan man)
            unwanted_keywords = [k for k in tc["must_NOT_include"] if k.lower() in full_text]
            if unwanted_keywords:
                print(f"  ❌ THẤT BẠI: Trả lời lan man, dính từ khóa cấm: {unwanted_keywords}")
                print(f"  [Phản hồi]: {answer[:250]}...")
                continue

            print(f"  ✅ CHUẨN XÁC 100%: Đúng trọng tâm, không lan man!")
            print(f"  - Action route: {action.get('route', 'N/A')}")
            print(f"  - Quick replies: {replies}")
            print(f"  - Trích xuất: {answer[:160].replace(chr(10), ' ')}...")
            passed += 1

        except Exception as e:
            print(f"  💥 LỖI KHI GỌI API: {e}")

    print("\n" + "=" * 80)
    print(f"📊 KẾT QUẢ TỔNG HỢP: {passed}/{total} KIỂM THỬ THÀNH CÔNG ({(passed/total)*100:.1f}%)")
    print("=" * 80)

    if passed == total:
        print("🎉 XUẤT SẮC: AI ĐÃ TRẢ LỜI ĐÚNG TRỌNG TÂM, VAY RA VAY, LÃI RA LÃI!")
        return 0
    else:
        print("⚠️ VẪN CÒN ĐIỂM CHƯA ĐẠT, CẦN TINH CHỈNH TIẾP.")
        return 1


if __name__ == "__main__":
    sys.exit(run_tests())
