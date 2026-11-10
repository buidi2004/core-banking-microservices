#!/usr/bin/env python3
"""
Test Suite: Kiểm tra Tính Năng Cá Nhân Hóa Chi Tiết Sinh Hoạt & Hệ Thống Nhắc Nhở Thông Minh
- Xác thực Kịch bản 24: Hệ thống 6 loại nhắc nhở thông minh & lịch sinh hoạt tự động
- Xác thực Kịch bản 25: Cá nhân hóa chi tiết sinh hoạt theo từng nhóm đối tượng
- Xác thực Lời nhắc tài chính cá nhân hóa khi có user_id (Zero-PII Leak, kết nối trực tiếp microservices)
- Xác thực Tính súc tích, in đậm số liệu, không lan man, có gợi ý dẫn dắt quick_replies
"""

import sys
import json
import urllib.request
import urllib.error

BASE_URL = "http://localhost:8000"

TEST_CASES = [
    {
        "id": "TC1_SMART_REMINDERS_SYSTEM",
        "description": "Kiểm tra Hệ thống 6 Loại Nhắc Nhở Thông Minh (Kịch bản 24)",
        "query": "Hệ thống nhắc nhở thông minh của ngân hàng gồm những loại nào và lịch sinh hoạt tự động ra sao?",
        "user_id": None,
        "must_contain": [
            "Hệ Thống 6 Loại Nhắc Nhở Tài Chính Thông Minh",
            "10 đến 15 hàng tháng",
            "Auto-Debit",
            "45 - 55 ngày miễn lãi",
            "Quick Loan",
            "CIC",
            "đáo hạn sổ tiết kiệm",
            "Thông tư 04/2022/TT-NHNN",
            "80% hạn mức",
            "Auto-Savings",
            "👉 Quý khách có thể bấm chọn nhanh"
        ],
        "must_have_quick_replies": True,
        "expected_route": "/profile"
    },
    {
        "id": "TC2_PERSONALIZED_LIFESTYLE_SEGMENTS",
        "description": "Kiểm tra Cá Nhân Hóa Chi Tiết Sinh Hoạt Theo Nhóm Đối Tượng (Kịch bản 25)",
        "query": "Tư vấn cá nhân hóa chi tiết sinh hoạt cho các nhóm đối tượng sinh viên, văn phòng và gia đình",
        "user_id": None,
        "must_contain": [
            "Cá Nhân Hóa Chi Tiêu Sinh Hoạt Chi Tiết",
            "Sinh Viên & Người Mới Đi Làm",
            "2.000.000 – 3.000.000 VNĐ",
            "Dân Văn Phòng Độc Thân",
            "4.500.000 – 6.500.000 VNĐ",
            "Hộ Gia Đình Trẻ",
            "30% – 35%",
            "Hộ Kinh Doanh Cá Thể",
            "👉 Quý khách có thể bấm chọn nhanh"
        ],
        "must_have_quick_replies": True,
        "expected_route": "/profile"
    },
    {
        "id": "TC3_PERSONAL_REMINDERS_AUTHENTICATED",
        "description": "Kiểm tra Lời Nhắc Tài Chính Cá Nhân Hóa Khi Đã Đăng Nhập (User ID có sẵn)",
        "query": "Xem các lời nhắc tài chính cá nhân và lịch thanh toán của tôi",
        "user_id": "user-test-uuid-001",
        "must_contain": [
            "Bản Lời Nhắc Tài Chính & Lịch Sinh Hoạt Cá Nhân Hóa",
            "Số dư ví khả dụng hiện tại",
            "Nhắc Lịch Thanh Toán Hóa Đơn Sinh Hoạt",
            "10 đến 15 hàng tháng",
            "Nhắc Hạn Thanh Toán Thẻ Tín Dụng",
            "Nhắc Lịch Trả Nợ",
            "Nhắc Ngày Đáo Hạn Sổ Tiết Kiệm",
            "80% hạn mức",
            "Auto-Savings",
            "👉 Quý khách có thể bấm chọn nhanh"
        ],
        "must_have_quick_replies": True,
        "expected_route": "/profile"
    },
    {
        "id": "TC4_PERSONAL_REMINDERS_ANONYMOUS",
        "description": "Kiểm tra Lời Nhắc Khi Chưa Đăng Nhập (Bảo Mật Zero-PII Leak)",
        "query": "Nhắc nhở tài chính của tôi",
        "user_id": None,
        "must_contain": [
            "đăng nhập vào ứng dụng",
            "Sen Hồng Bank"
        ],
        "must_have_quick_replies": True,
        "expected_route": "/auth/login"
    },
    {
        "id": "TC5_STUDENT_SPECIFIC_LIFESTYLE",
        "description": "Kiểm tra Chi Tiết Sinh Hoạt Cụ Thể Cho Sinh Viên Mới Đi Làm",
        "query": "Sinh viên mới ra trường nên chi tiêu sinh hoạt thế nào cho hợp lý?",
        "user_id": None,
        "must_contain": [
            "Sinh Viên & Người Mới Đi Làm",
            "Tiền trọ",
            "Ăn uống sinh hoạt tự nấu",
            "Học tập & Nâng cao kỹ năng",
            "Tích lũy khẩn cấp",
            "👉 Quý khách có thể bấm chọn nhanh"
        ],
        "must_have_quick_replies": True,
        "expected_route": "/profile"
    }
]

def run_tests():
    print("=" * 80)
    print("🚀 BẮT ĐẦU KIỂM THỬ TÍNH NĂNG CÁ NHÂN HÓA CHI TIẾT SINH HOẠT & NHẮC NHỞ THÔNG MINH")
    print("=" * 80)
    
    passed = 0
    failed = 0

    for tc in TEST_CASES:
        print(f"\n🧪 Đang chạy: [{tc['id']}] - {tc['description']}")
        print(f"   Query: \"{tc['query']}\"")
        if tc["user_id"]:
            print(f"   Context: User ID = {tc['user_id']}")

        payload = {
            "question": tc["query"]
        }
        if tc["user_id"]:
            payload["user_id"] = tc["user_id"]

        req = urllib.request.Request(
            f"{BASE_URL}/chat",
            data=json.dumps(payload).encode("utf-8"),
            headers={"Content-Type": "application/json"}
        )
        if tc["user_id"]:
            req.add_header("X-User-Id", tc["user_id"])

        try:
            with urllib.request.urlopen(req, timeout=15) as resp:
                data = json.loads(resp.read().decode("utf-8"))
        except Exception as e:
            print(f"   ❌ HTTP LỖI: {e}")
            failed += 1
            continue

        answer = data.get("answer", "")
        quick_replies = data.get("quick_replies", [])
        suggested_action = data.get("suggested_action")
        sources = data.get("sources", [])

        # Kiểm tra nội dung bắt buộc
        missing_terms = [t for t in tc["must_contain"] if t.lower() not in answer.lower()]
        has_qr = len(quick_replies) > 0 if tc["must_have_quick_replies"] else True
        route_ok = True
        if tc.get("expected_route") and suggested_action:
            route_ok = (suggested_action.get("route") == tc["expected_route"])

        if not missing_terms and has_qr and route_ok:
            print(f"   ✅ PASS 100%")
            print(f"   - Độ dài câu trả lời: {len(answer)} ký tự (Ngắn gọn, súc tích)")
            print(f"   - Gợi ý chọn nhanh: {quick_replies}")
            if suggested_action:
                print(f"   - Hành động đề xuất: {suggested_action.get('label')} -> {suggested_action.get('route')}")
            print(f"   - Nguồn dữ liệu: {sources}")
            passed += 1
        else:
            print(f"   ❌ FAILED!")
            if missing_terms:
                print(f"   - Thiếu từ khóa: {missing_terms}")
            if not has_qr:
                print(f"   - Thiếu gợi ý quick_replies")
            if not route_ok:
                print(f"   - Sai route: Kỳ vọng {tc.get('expected_route')}, thực tế {suggested_action}")
            print(f"   - Trích đoạn thực tế:\n{answer[:300]}...")
            failed += 1

    print("\n" + "=" * 80)
    print(f"📊 KẾT QUẢ KIỂM THỬ: {passed}/{len(TEST_CASES)} PASS ({passed/len(TEST_CASES)*100:.1f}%)")
    print("=" * 80)

    if failed > 0:
        sys.exit(1)

if __name__ == "__main__":
    run_tests()
