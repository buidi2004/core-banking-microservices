#!/usr/bin/env python3
"""
Test Suite: Xác Thực Khả Năng Đưa Ra Các Phương Án Toàn Diện Cho Người Dùng (Actionable Financial Options)
- Xác thực Kịch bản 26: Đưa ra 3 phương án lựa chọn cụ thể (Phương án 1 Khuyên dùng, Phương án 2 Linh hoạt, Phương án 3 Cấp bách/Phòng vệ)
- Ma trận so sánh Ưu - Nhược điểm & Đánh đổi (Trade-off Matrix)
- Gợi ý dẫn dắt chọn nhanh các phương án (quick_replies)
- Chuẩn mực súc tích, in đậm số liệu, không lan man
"""

import sys
import json
import urllib.request

BASE_URL = "http://localhost:8000"

TEST_CASES = [
    {
        "id": "TC1_GENERAL_FINANCIAL_OPTIONS",
        "description": "Kiểm tra Tư Vấn Đưa Ra Các Phương Án Tài Chính Cho Người Dùng (Kịch bản 26)",
        "query": "Tôi muốn ngân hàng đưa ra các phương án tài chính cho người dùng để lựa chọn thì có những phương án nào?",
        "must_contain": [
            "3 Phương Án Phân Bổ Vốn & Quản Trị Tài Chính Toàn Diện",
            "Phương Án 1",
            "Chiến Lược Bậc Thang Cân Bằng Laddering",
            "60% Vốn",
            "30% Vốn",
            "10% Vốn",
            "Phương Án 2",
            "Lãi Kép Dài Hạn",
            "Thông tư 04/2022/TT-NHNN",
            "Phương Án 3",
            "Đa Dạng Hóa Danh Mục",
            "Ma Trận So Sánh",
            "👉 Quý khách có thể bấm chọn nhanh"
        ],
        "must_have_quick_replies": True,
        "expected_route": "/savings"
    },
    {
        "id": "TC2_TIGHT_MONEY_OPTIONS",
        "description": "Kiểm tra Các Phương Án Xử Lý Cấp Bách Khi Kẹt Tiền Đang Có Sổ Tiết Kiệm",
        "query": "Tôi đang có sổ tiết kiệm nhưng đang kẹt tiền gấp thì có những phương án xử lý nào để không bị mất lãi?",
        "must_contain": [
            "3 Phương Án Xử Lý Cấp Bách Khi Kẹt Tiền Mà Đang Có Sổ Tiết Kiệm",
            "Phương Án 1",
            "Vay Thấu Chi Cầm Cố Sổ Tiết Kiệm",
            "85% - 90% giá trị sổ",
            "Bảo toàn trọn vẹn 100% tiền lãi",
            "Phương Án 2",
            "Rút Một Phần Gốc Theo Thông Tư 04/2022/TT-NHNN",
            "0.2%/năm",
            "Phương Án 3",
            "Vay Tiêu Dùng Quick Loan 1 Phút",
            "Miễn phí 100%",
            "tất toán trước hạn",
            "Ma Trận So Sánh",
            "👉 Quý khách có thể bấm chọn nhanh"
        ],
        "must_have_quick_replies": True,
        "expected_route": "/savings"
    },
    {
        "id": "TC3_CARD_DEBT_OPTIONS",
        "description": "Kiểm tra Các Phương Án Xử Lý Dư Nợ Thẻ Tín Dụng Đến Hạn",
        "query": "Thẻ tín dụng sắp đến hạn thanh toán mà chưa đủ tiền thì có phương án nào để không bị phạt và nợ xấu?",
        "must_contain": [
            "3 Phương Án Xử Lý Dư Nợ Thẻ Tín Dụng Đến Hạn",
            "Phương Án 1",
            "Chuyển Đổi Trả Góp 0%",
            "phí chuyển đổi",
            "1% - 2%",
            "Phương Án 2",
            "Trả Số Tiền Tối Thiểu 5%",
            "CIC",
            "Phương Án 3",
            "Bảo Toàn 55 Ngày Miễn Lãi",
            "👉 Quý khách có thể bấm chọn nhanh"
        ],
        "must_have_quick_replies": True,
        "expected_route": "/cards"
    },
    {
        "id": "TC4_IDLE_MONEY_ACTION_OPTIONS",
        "description": "Kiểm tra Phương Án Hành Động Cho Người Dùng Có Tiền Nhàn Rỗi",
        "query": "Tư vấn các phương án hành động cho người dùng khi có một khoản tiền nhàn rỗi",
        "must_contain": [
            "3 Phương Án Phân Bổ Vốn & Quản Trị Tài Chính Toàn Diện",
            "Phương Án 1",
            "Phương Án 2",
            "Phương Án 3",
            "Ma Trận So Sánh",
            "👉 Quý khách có thể bấm chọn nhanh"
        ],
        "must_have_quick_replies": True,
        "expected_route": "/savings"
    }
]

def run_tests():
    print("=" * 80)
    print("🚀 BẮT ĐẦU KIỂM THỬ TÍNH NĂNG ĐƯA RA CÁC PHƯƠNG ÁN TOÀN DIỆN CHO NGƯỜI DÙNG")
    print("=" * 80)

    passed = 0
    failed = 0

    for tc in TEST_CASES:
        print(f"\n🧪 Đang chạy: [{tc['id']}] - {tc['description']}")
        print(f"   Query: \"{tc['query']}\"")

        payload = {"question": tc["query"]}
        req = urllib.request.Request(
            f"{BASE_URL}/chat",
            data=json.dumps(payload).encode("utf-8"),
            headers={"Content-Type": "application/json"}
        )

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

        missing_terms = [t for t in tc["must_contain"] if t.lower() not in answer.lower()]
        has_qr = len(quick_replies) > 0 if tc["must_have_quick_replies"] else True
        route_ok = True
        if tc.get("expected_route") and suggested_action:
            route_ok = (suggested_action.get("route") == tc["expected_route"])

        if not missing_terms and has_qr and route_ok:
            print(f"   ✅ PASS 100%")
            print(f"   - Độ dài: {len(answer)} ký tự")
            print(f"   - Gợi ý chọn nhanh: {quick_replies}")
            if suggested_action:
                print(f"   - Hành động đề xuất: {suggested_action.get('label')} -> {suggested_action.get('route')}")
            print(f"   - Nguồn: {sources}")
            passed += 1
        else:
            print(f"   ❌ FAILED!")
            if missing_terms:
                print(f"   - Thiếu từ khóa: {missing_terms}")
            if not has_qr:
                print(f"   - Thiếu quick_replies")
            if not route_ok:
                print(f"   - Sai route: Kỳ vọng {tc.get('expected_route')}, thực tế {suggested_action}")
            print(f"   - Trích đoạn:\n{answer[:300]}...")
            failed += 1

    print("\n" + "=" * 80)
    print(f"📊 KẾT QUẢ KIỂM THỬ: {passed}/{len(TEST_CASES)} PASS ({passed/len(TEST_CASES)*100:.1f}%)")
    print("=" * 80)

    if failed > 0:
        sys.exit(1)

if __name__ == "__main__":
    run_tests()
