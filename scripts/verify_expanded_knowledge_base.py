#!/usr/bin/env python3
"""
Kiểm thử Toàn Diện Cơ Sở Tri Thức & Dữ Liệu Ngân Hàng Mở Rộng
Ngân Hàng Số Sen Hồng Core Banking (47 Tài Liệu - 538 Chunks pgvector)

Mục tiêu:
Xác thực AI Chatbot đã tiếp nạp thành công và trả lời xuất sắc 8 mảng tri thức mới:
1. Thẩm định tín dụng CIC & Phân loại 5 nhóm nợ (Thông tư 11/2021/TT-NHNN).
2. Chứng chỉ tiền gửi (CD) & Bảo hiểm Tiền gửi Việt Nam DIV (Hạn mức 125 triệu).
3. Chuyển tiền quốc tế SWIFT (Mã BIC SENHVNVX) & Kiều hối Western Union.
4. Thẻ tín dụng hoàn tiền Cashback, Trả góp 0% & Xử lý sự cố nuốt thẻ ATM.
5. Nộp thuế điện tử eTax Mobile & Nộp phạt nguội Cổng Dịch vụ công Quốc gia.
6. Cây nạp tiền CRM 24/7 & Kiosk in thẻ tự động Smart Lounge.
7. Khách hàng Ưu tiên Sen Hong Priority & Phòng chờ thương gia LoungeKey.
8. 15 Thủ đoạn lừa đảo công nghệ cao & Quy trình 4 bước xử lý khẩn cấp.
"""

import sys
import json
import urllib.request

BASE_URL = "http://localhost:8000"

EXPANDED_TEST_CASES = [
    {
        "name": "1. Thẩm định tín dụng CIC & 5 Nhóm nợ",
        "query": "Nợ xấu nhóm 3 nhóm 4 trên CIC bao lâu thì được xóa và ngân hàng phân loại 5 nhóm nợ thế nào?",
        "must_have": ["cic", "nhóm 3", "nhóm 4", "5 năm", "thông tư 11"],
        "expect_title": "Vay thế chấp BĐS, Ô tô & Thẩm định CIC"
    },
    {
        "name": "2. Chứng chỉ tiền gửi CD & Bảo hiểm Tiền gửi DIV",
        "query": "Chứng chỉ tiền gửi CD khác gì tiết kiệm thông thường và hạn mức bảo hiểm tiền gửi chi trả bao nhiêu?",
        "must_have": ["chứng chỉ tiền gửi", "125.000.000", "bảo hiểm tiền gửi"],
        "expect_title": "Chứng chỉ tiền gửi CD & Bảo hiểm tiền gửi DIV"
    },
    {
        "name": "3. Chuyển tiền quốc tế SWIFT & Kiều hối",
        "query": "Mã SWIFT code của ngân hàng Sen Hồng là gì và hồ sơ chuyển tiền du học cần những gì?",
        "must_have": ["senhvnvx", "swift", "du học", "hộ chiếu"],
        "expect_title": "Chuyển tiền quốc tế SWIFT & Kiều hối"
    },
    {
        "name": "4. Thẻ tín dụng Cashback, Miễn lãi 55 ngày & Trả góp 0%",
        "query": "Thẻ tín dụng hoàn tiền Cashback được miễn lãi bao nhiêu ngày và làm sao để chuyển đổi trả góp 0%?",
        "must_have": ["55 ngày", "hoàn tiền", "trả góp 0%"],
        "expect_title": "Thẻ tín dụng hoàn tiền & Trả góp 0%"
    },
    {
        "name": "5. Nộp thuế điện tử eTax Mobile & Nộp phạt nguội",
        "query": "Làm thế nào để nộp thuế qua app eTax Mobile và nộp phạt nguội giao thông bằng tài khoản Sen Hồng?",
        "must_have": ["etax", "thuế", "kho bạc", "phạt nguội"],
        "expect_title": "Nộp thuế điện tử eTax Mobile & Dịch vụ công"
    },
    {
        "name": "6. Cây nạp tiền CRM 24/7 & Kiosk Smart Lounge",
        "query": "Cây CRM của ngân hàng có nạp được tiền mặt không cần thẻ không và hạn mức nạp một lần là bao nhiêu?",
        "must_have": ["crm", "100.000.000", "vietqr", "tiền mặt"],
        "expect_title": "Smart Lounge 24/7 & Cây nạp rút tiền CRM"
    },
    {
        "name": "7. Khách hàng Ưu tiên Sen Hong Priority Banking",
        "query": "Điều kiện để trở thành khách hàng ưu tiên Priority là gì và có được dùng phòng chờ sân bay không?",
        "must_have": ["priority", "phòng chờ", "1 tỷ", "lounge"],
        "expect_title": "Khách hàng ưu tiên Sen Hong Priority & Private Banking"
    },
    {
        "name": "8. Cảnh báo lừa đảo công nghệ cao & Xử lý khẩn cấp",
        "query": "Nếu nghi ngờ bị lừa đảo hoặc lỡ bấm link lạ thì 4 bước xử lý khẩn cấp cần làm ngay là gì?",
        "must_have": ["khóa", "khẩn cấp", "mật khẩu", "công an"],
        "expect_title": "Nhận diện 15 thủ đoạn lừa đảo & Xử lý khẩn cấp"
    }
]

def run_verification():
    print("=" * 80)
    print("📚 KIỂM THỬ TOÀN DIỆN KHO TRI THỨC MỞ RỘNG (47 TÀI LIỆU - 538 CHUNKS)")
    print("=" * 80)

    passed = 0
    total = len(EXPANDED_TEST_CASES)

    for idx, tc in enumerate(EXPANDED_TEST_CASES, start=1):
        print(f"\n[{idx}/{total}] 🔍 KIỂM THỬ: {tc['name']}")
        print(f"   ❓ Câu hỏi: \"{tc['query']}\"")

        payload = json.dumps({
            "question": tc["query"],
            "user_id": f"test_knowledge_user_{idx}"
        }).encode("utf-8")

        req = urllib.request.Request(
            f"{BASE_URL}/chat",
            data=payload,
            headers={"Content-Type": "application/json"}
        )

        try:
            with urllib.request.urlopen(req, timeout=20) as res:
                data = json.loads(res.read().decode("utf-8"))
        except Exception as e:
            print(f"   ❌ LỖI GỌI API: {e}")
            continue

        answer = data.get("answer", "")
        sources = data.get("sources", [])
        quick_replies = data.get("quick_replies", [])
        thought = data.get("thought_process", "")

        print(f"   📄 Độ dài câu trả lời: {len(answer)} ký tự, {len(answer.split())} từ")
        print(f"   📚 Nguồn trích dẫn: {sources}")
        print(f"   💡 Gợi ý kế tiếp: {quick_replies}")

        # 1. Kiểm tra từ khóa nghiệp vụ chuyên sâu
        missing = [kw for kw in tc["must_have"] if kw.lower() not in answer.lower()]
        if missing:
            print(f"   ❌ LỖI: Câu trả lời thiếu các từ khóa nghiệp vụ quan trọng: {missing}")
            print(f"   Đoạn trích câu trả lời:\n{answer[:300]}...")
            continue

        # 2. Kiểm tra câu cầu nối dẫn hướng sang câu trả lời tiếp theo
        has_bridge = any(k in answer.lower() for k in [
            "gợi ý bên dưới", "bấm chọn nhanh", "chọn gợi ý", "câu trả lời chi tiết"
        ])
        if not has_bridge:
            print(f"   ❌ LỖI: Thiếu câu cầu nối dẫn hướng sang câu trả lời tiếp theo!")
            continue

        print(f"   ✅ ĐẠT: Nắm vững dữ liệu chuyên sâu, trích xuất chính xác và dẫn hướng hoàn hảo!")
        passed += 1

    print("\n" + "=" * 80)
    print(f"📊 KẾT QUẢ NGHIỆM THU: {passed}/{total} KỊCH BẢN PASS ({passed/total*100:.1f}%)")
    print("=" * 80)

    if passed == total:
        print("🎉 XUẤT SẮC: KHO DỮ LIỆU MỞ RỘNG ĐÃ ĐƯỢC AI NẠP VÀ TRẢ LỜI ĐẠT CHUẨN 100%!")
        sys.exit(0)
    else:
        sys.exit(1)

if __name__ == "__main__":
    run_verification()
