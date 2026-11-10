#!/usr/bin/env python3
"""
Test Suite: Kiểm thử Chuyên sâu Kịch bản Tư vấn Giấy tờ Mở tài khoản & Giấy tờ Vay vốn trên App Sen Hồng
- Giấy tờ & độ tuổi mở app: CCCD chip, 15 tuổi, NFC, Smart Lounge, VNeID Mức 2, Người nước ngoài.
- Giấy tờ vay vốn: Quick Loan 5-50tr (CCCD chip, 0đ giấy tờ, không cần bảng lương/sao kê);
  Vay tiêu dùng 50-200tr (sao kê lương, HĐLĐ, VssID); Vay hộ kinh doanh (ĐKKD, VietQR).
"""

import sys
import json
import urllib.request
import urllib.error

API_URL = "http://localhost:8000/chat"

TEST_CASES = [
    {
        "name": "TC1: Giấy tờ & độ tuổi tạo tài khoản / mở app cho công dân Việt Nam",
        "query": "Để tạo tài khoản app Sen Hồng thì cần những giấy tờ gì và điều kiện độ tuổi thế nào?",
        "expected_keywords": [
            ["căn cước", "cccd", "chip"],
            ["15 tuổi", "đủ 15 tuổi"],
            ["chính chủ"],
            ["/auth/register"]
        ],
        "expected_topic": "ACCOUNT_OPENING_DOCS"
    },
    {
        "name": "TC2: Điện thoại không có NFC làm sao mở app Sen Hồng",
        "query": "Điện thoại của mình không có NFC thì có mở app Sen Hồng được không?",
        "expected_keywords": [
            ["smart lounge", "quầy"],
            ["quét chip", "nfc"],
            ["vneid"]
        ],
        "expected_topic": "ACCOUNT_OPENING_DOCS"
    },
    {
        "name": "TC3: Giấy tờ mở app cho khách hàng người nước ngoài",
        "query": "Khách hàng người nước ngoài cần những giấy tờ gì để mở tài khoản app Sen Hồng?",
        "expected_keywords": [
            ["hộ chiếu", "passport"],
            ["thị thực", "tạm trú", "visa"],
            ["smart lounge", "quầy"]
        ],
        "expected_topic": "ACCOUNT_OPENING_DOCS"
    },
    {
        "name": "TC4: Giấy tờ vay Quick Loan 30 triệu (Có cần bảng lương hay sao kê không)",
        "query": "Mình muốn vay tiền trên app 30 triệu thì có cần nộp bảng lương hay sao kê không, cần giấy tờ gì?",
        "expected_keywords": [
            ["không cần bảng lương", "hoàn toàn không cần bảng lương", "không cần sao kê"],
            ["căn cước", "cccd"],
            ["quick loan", "1 phút", "30 giây"],
            ["/bills/quick-loan"]
        ],
        "expected_topic": "LOANS"
    },
    {
        "name": "TC5: Giấy tờ chứng minh thu nhập cho gói vay tiêu dùng 50-200 triệu",
        "query": "Nếu muốn vay tiêu dùng từ 50 đến 200 triệu trên app thì cần những hồ sơ chứng minh thu nhập gì?",
        "expected_keywords": [
            ["sao kê", "sao kê tài khoản"],
            ["hợp đồng lao động", "hđlđ"],
            ["vssid", "bảo hiểm xã hội"],
            ["căn cước", "cccd"]
        ],
        "expected_topic": "LOANS"
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
    print("🚀 BẮT ĐẦU KIỂM THỬ TỰ ĐỘNG: TƯ VẤN HỒ SƠ GIẤY TỜ MỞ TÀI KHOẢN & VAY VỐN")
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
            sources = resp.get("sources", [])

            # Check keywords
            ans_lower = (answer + " " + json.dumps(action) + " " + json.dumps(replies)).lower()
            failed_keywords = []
            for kw_group in tc["expected_keywords"]:
                if not any(k.lower() in ans_lower for k in kw_group):
                    failed_keywords.append(" / ".join(kw_group))

            if failed_keywords:
                print(f"  ❌ THẤT BẠI: Thiếu từ khóa bắt buộc: {failed_keywords}")
                print(f"  [Phản hồi thực tế]: {answer[:250]}...")
                continue

            print(f"  ✅ Phản hồi chính xác 100%!")
            print(f"  - Action route: {action.get('route', 'N/A')}")
            print(f"  - Quick replies: {replies}")
            print(f"  - Trích xuất: {answer[:180].replace(chr(10), ' ')}...")
            passed += 1

        except Exception as e:
            print(f"  💥 LỖI KHI GỌI API: {e}")

    print("\n" + "=" * 80)
    print(f"📊 KẾT QUẢ TỔNG HỢP: {passed}/{total} KIỂM THỬ THÀNH CÔNG ({(passed/total)*100:.1f}%)")
    print("=" * 80)

    if passed == total:
        print("🎉 TẤT CẢ KỊCH BẢN GIẤY TỜ MỞ APP & VAY VỐN ĐÃ ĐẠT CHUẨN XUẤT SẮC!")
        return 0
    else:
        print("⚠️ VẪN CÒN TEST CASE CHƯA ĐẠT, CẦN TINH CHỈNH THÊM.")
        return 1


if __name__ == "__main__":
    sys.exit(run_tests())
