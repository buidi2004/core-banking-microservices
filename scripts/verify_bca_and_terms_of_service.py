#!/usr/bin/env python3
"""
Test Suite: Xác thực Kiến thức Chuyên Sâu Về Bộ Công An (BCA, C06, Đề Án 06, VNeID, Luật Căn Cước)
và Điều Khoản Dịch Vụ App Sen Hồng Bank (Nghị Định 13/2023/NĐ-CP, Điều 291 BLHS).
"""

import json
import urllib.request
import sys

CHAT_URL = "http://localhost:8000/chat"

BCA_AND_TERMS_TESTS = [
    {
        "name": "1. Bộ Công An & Đề Án 06 (Làm sạch 100% dữ liệu tài khoản)",
        "question": "Bộ Công An và Đề án 06 quy định xác thực tài khoản ngân hàng với dữ liệu dân cư như thế nào?",
        "expected_steps": 5,
        "check_thought": ["BCA_VNEID_EKYC", "Đề án 06", "C06"],
        "check_answer": ["đề án 06", "bộ công an", "dân cư", "chính chủ duy nhất", "tài khoản rác"]
    },
    {
        "name": "2. Định Danh Điện Tử VNeID Mức 2 & Luật Căn Cước 2023",
        "question": "Tôi có tài khoản VNeID Mức 2 và Thẻ Căn cước theo Luật Căn cước mới thì có mở được tài khoản Sen Hồng không?",
        "expected_steps": 5,
        "check_thought": ["BCA_VNEID_EKYC", "VNeID", "Luật Căn cước"],
        "check_answer": ["vneid mức 2", "500.000.000", "luật căn cước số 26/2023/qh15", "thẻ căn cước"]
    },
    {
        "name": "3. Điều Khoản Dịch Vụ App & Bảo Vệ Dữ Liệu (Nghị Định 13/2023/NĐ-CP)",
        "question": "Điều khoản sử dụng app Sen Hồng và chính sách bảo vệ dữ liệu theo Nghị định 13 quy định những gì?",
        "expected_steps": 5,
        "check_thought": ["TERMS_OF_SERVICE", "Nghị định 13"],
        "check_answer": ["nghị định 13/2023/nđ-cp", "đủ 15 tuổi", "không mua bán", "legal@senhongbank.vn"]
    },
    {
        "name": "4. Chế Tài Mua Bán, Cho Thuê Tài Khoản Ngân Hàng (Điều 291 BLHS)",
        "question": "Cho người khác mượn hoặc bán tài khoản ngân hàng có bị đi tù không theo quy định pháp luật?",
        "expected_steps": 5,
        "check_thought": ["Điều 291 BLHS", "mua bán, cho thuê tài khoản"],
        "check_answer": ["điều 291", "03 tháng đến 07 năm tù", "blacklist", "40.000.000"]
    },
    {
        "name": "5. Cảnh Báo Lừa Đảo Mạo Danh Cán Bộ Công An",
        "question": "Công an có bao giờ gọi điện yêu cầu chuyển tiền vào tài khoản an toàn để điều tra không?",
        "expected_steps": 5,
        "check_thought": ["BCA_VNEID_EKYC", "Bộ Công An"],
        "check_answer": ["tuyệt đối không", "tài khoản an toàn", "100% lừa đảo", "làm việc qua điện thoại"]
    }
]

def run_tests():
    passed = 0
    total = len(BCA_AND_TERMS_TESTS)

    print("=" * 80)
    print("🛡️ BẮT ĐẦU KIỂM THỬ TRI THỨC BỘ CÔNG AN (C06, ĐỀ ÁN 06, VNEID) & ĐIỀU KHOẢN APP")
    print("=" * 80)

    for idx, tc in enumerate(BCA_AND_TERMS_TESTS, 1):
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

        print(f"  ✅ THÀNH CÔNG: Đã đối soát {dur_ms:.1f}ms, khớp toàn diện quy định Bộ Công An & Điều khoản App!")
        passed += 1

    print("\n" + "=" * 80)
    print(f"KẾT QUẢ NGHIỆM THU: {passed}/{total} Kịch bản PASS ({passed/total*100:.1f}%)")
    print("=" * 80)
    if passed == total:
        print("🎉 TẤT CẢ KỊCH BẢN BỘ CÔNG AN & ĐIỀU KHOẢN APP ĐẠT CHUẨN XUẤT SẮC!")
        sys.exit(0)
    else:
        print("⚠️ CÓ KỊCH BẢN CHƯA ĐẠT!")
        sys.exit(1)

if __name__ == "__main__":
    run_tests()
