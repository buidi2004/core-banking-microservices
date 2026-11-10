#!/usr/bin/env python3
"""
Test Suite: Kiểm thử Tối Ưu Gợi Ý AI Dựa Vào Câu Hỏi Trước Đó (Contextual Multi-Turn Quick Replies)
Giao tiếp trực tiếp qua REST API (http://localhost:8000/chat) của ewallet-chatbot-service:
1. Dự đoán chính xác bước logic tiếp theo trong hành trình khách hàng (Next logical follow-ups).
2. Tuyệt đối KHÔNG gợi ý lặp lại những gì người dùng đã hỏi trong các lượt trước (Anti-redundancy).
3. Thích ứng động đa lượt khi người dùng chuyển đổi chủ đề (Cross-product topic switching).
4. Xác thực chuỗi hội thoại đa lượt liên tục (Multi-turn conversations).
"""

import sys
import json
import unicodedata
import urllib.request
import urllib.error
import time

API_URL = "http://localhost:8000/chat"


def strip_accents(text: str) -> str:
    if not text:
        return ""
    normalized = unicodedata.normalize('NFD', text)
    stripped = ''.join(c for c in normalized if unicodedata.category(c) != 'Mn')
    return stripped.replace('đ', 'd').replace('Đ', 'D').lower()


def send_chat_query(question: str, history=None):
    payload = {
        "question": question,
        "history": history or []
    }
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        API_URL,
        data=data,
        headers={"Content-Type": "application/json"}
    )
    with urllib.request.urlopen(req, timeout=10) as resp:
        return json.loads(resp.read().decode("utf-8"))


def print_separator(title: str):
    print("\n" + "=" * 80)
    print(f"👉 {title}")
    print("=" * 80)


def assert_no_redundancy(replies, past_queries, current_query):
    """Kiểm tra không có gợi ý nào lặp lại câu hỏi quá khứ hoặc câu hiện tại"""
    q_norm = strip_accents(current_query)
    for r in replies:
        r_norm = strip_accents(r)
        assert r_norm != q_norm, f"Gợi ý '{r}' trùng câu hỏi hiện tại '{current_query}'"
        assert not (len(r_norm) >= 15 and len(q_norm) >= 15 and r_norm in q_norm), f"Gợi ý '{r}' là tập con của câu hỏi '{current_query}'"

        for past_q in past_queries:
            past_norm = strip_accents(past_q)
            assert r_norm != past_norm, f"Gợi ý '{r}' lặp lại câu hỏi trong lịch sử '{past_q}'"
            assert not (len(r_norm) >= 15 and len(past_norm) >= 15 and (r_norm in past_norm or past_norm in r_norm)), f"Gợi ý '{r}' trùng ngữ nghĩa với '{past_q}'"


def test_loan_journey_multi_turn():
    print_separator("TEST 1: HÀNH TRÌNH VAY VỐN ĐA LƯỢT (LOAN JOURNEY)")

    # Turn 1: Hỏi hồ sơ vay
    q1 = "Hồ sơ giấy tờ để vay Quick Loan cần những gì?"
    resp1 = send_chat_query(q1, history=[])
    r1 = resp1.get("quick_replies", [])
    print(f"Turn 1 Q: '{q1}'")
    print(f"Turn 1 Quick Replies: {r1}")
    assert len(r1) >= 2, "Turn 1 phải có ít nhất 2 gợi ý"
    assert any("lãi suất" in r.lower() for r in r1), f"Turn 1 phải gợi ý về lãi suất vay, got: {r1}"
    assert_no_redundancy(r1, [], q1)

    # Turn 2: Hỏi lãi suất vay (kèm history Turn 1)
    q2 = "Lãi suất vay Quick Loan bao nhiêu một tháng?"
    history_t2 = [
        {"role": "user", "content": q1},
        {"role": "assistant", "content": resp1.get("answer", "")}
    ]
    resp2 = send_chat_query(q2, history=history_t2)
    r2 = resp2.get("quick_replies", [])
    print(f"\nTurn 2 Q: '{q2}' (kèm history Turn 1)")
    print(f"Turn 2 Quick Replies: {r2}")
    assert len(r2) >= 2, "Turn 2 phải có ít nhất 2 gợi ý"
    assert_no_redundancy(r2, [q1], q2)

    # TUYỆT ĐỐI không được gợi ý lại Hồ sơ hay Lãi suất
    for r in r2:
        assert "hồ sơ" not in r.lower(), f"Turn 2 lặp lại hồ sơ: {r}"
        assert "lãi suất vay quick loan bao nhiêu" not in r.lower(), f"Turn 2 lặp lại câu hỏi: {r}"
    # Phải hướng tới: Bảng tính trả nợ / Thời gian giải ngân / Phí trả nợ trước hạn
    assert any(any(k in r.lower() for k in ["bảng tính", "lịch trả nợ", "trả nợ", "dư nợ giảm dần", "giải ngân", "trước hạn"]) for r in r2), f"Turn 2 phải gợi ý bước tiếp theo của khoản vay, got: {r2}"

    # Turn 3: Hỏi bảng tính trả nợ (kèm history Turns 1 & 2)
    q3 = "Bảng tính trả nợ theo dư nợ giảm dần 30 triệu mỗi tháng trả bao nhiêu?"
    history_t3 = history_t2 + [
        {"role": "user", "content": q2},
        {"role": "assistant", "content": resp2.get("answer", "")}
    ]
    resp3 = send_chat_query(q3, history=history_t3)
    r3 = resp3.get("quick_replies", [])
    print(f"\nTurn 3 Q: '{q3}' (kèm history Turns 1 & 2)")
    print(f"Turn 3 Quick Replies: {r3}")
    assert len(r3) >= 2, "Turn 3 phải có ít nhất 2 gợi ý"
    assert_no_redundancy(r3, [q1, q2], q3)
    # Phải gợi ý: Giải ngân / Phí trước hạn / Đăng ký vay
    assert any(any(k in r.lower() for k in ["giải ngân", "trước hạn", "đăng ký vay"]) for r in r3), f"Turn 3 phải gợi ý giải ngân hoặc đăng ký, got: {r3}"
    print("✅ TEST 1 PASSED: Hành trình vay vốn gợi ý chuẩn xác theo từng bước logic, không lặp lại câu hỏi cũ.")


def test_savings_journey_multi_turn():
    print_separator("TEST 2: HÀNH TRÌNH TIẾT KIỆM ĐA LƯỢT (SAVINGS JOURNEY)")

    # Turn 1: Hỏi biểu lãi suất
    q1 = "Biểu lãi suất tiết kiệm trực tuyến hiện nay là bao nhiêu?"
    resp1 = send_chat_query(q1, history=[])
    r1 = resp1.get("quick_replies", [])
    print(f"Turn 1 Q: '{q1}'")
    print(f"Turn 1 Quick Replies: {r1}")
    assert len(r1) >= 2
    assert_no_redundancy(r1, [], q1)

    # Turn 2: Hỏi tính lãi 100 triệu
    q2 = "Gửi 100 triệu 12 tháng tính lãi được bao nhiêu tiền?"
    history_t2 = [
        {"role": "user", "content": q1},
        {"role": "assistant", "content": resp1.get("answer", "")}
    ]
    resp2 = send_chat_query(q2, history=history_t2)
    r2 = resp2.get("quick_replies", [])
    print(f"\nTurn 2 Q: '{q2}' (kèm history Turn 1)")
    print(f"Turn 2 Quick Replies: {r2}")
    assert len(r2) >= 2
    assert_no_redundancy(r2, [q1], q2)
    # Gợi ý Turn 2 phải đưa tới: Rút trước hạn TT 04 / Tiết kiệm bậc thang / Mở sổ
    assert any(any(k in r.lower() for k in ["rút tiền", "thông tư 04", "tt 04", "bậc thang", "mở sổ"]) for r in r2), f"Turn 2 phải gợi ý TT 04 hoặc mở sổ, got: {r2}"

    # Turn 3: Hỏi rút tiền trước hạn
    q3 = "Rút tiền tiết kiệm trước hạn có bị mất hết tiền lãi không?"
    history_t3 = history_t2 + [
        {"role": "user", "content": q2},
        {"role": "assistant", "content": resp2.get("answer", "")}
    ]
    resp3 = send_chat_query(q3, history=history_t3)
    r3 = resp3.get("quick_replies", [])
    print(f"\nTurn 3 Q: '{q3}' (kèm history Turns 1 & 2)")
    print(f"Turn 3 Quick Replies: {r3}")
    assert len(r3) >= 2
    assert_no_redundancy(r3, [q1, q2], q3)
    # Gợi ý Turn 3 phải đưa tới: Cách rút một phần / Chiến lược bậc thang / Mở sổ online
    assert any(any(k in r.lower() for k in ["rút một phần", "bậc thang", "mở sổ", "không kỳ hạn"]) for r in r3), f"Turn 3 phải gợi ý rút một phần hoặc bậc thang, got: {r3}"
    print("✅ TEST 2 PASSED: Hành trình tiết kiệm chuyển tiếp thông minh sang TT 04 và chiến lược bậc thang.")


def test_onboarding_nfc_journey_multi_turn():
    print_separator("TEST 3: HÀNH TRÌNH TẠO APP & XỬ LÝ KHÔNG CÓ NFC (ONBOARDING & NFC)")

    # Turn 1: Hỏi giấy tờ tạo app
    q1 = "Giấy tờ để tạo app cần những gì?"
    resp1 = send_chat_query(q1, history=[])
    r1 = resp1.get("quick_replies", [])
    print(f"Turn 1 Q: '{q1}'")
    print(f"Turn 1 Quick Replies: {r1}")
    assert any("nfc" in r.lower() for r in r1), f"Turn 1 phải gợi ý về trường hợp máy không có NFC, got: {r1}"

    # Turn 2: Hỏi máy không có NFC
    q2 = "Điện thoại của tôi không có NFC có mở app được không?"
    history_t2 = [
        {"role": "user", "content": q1},
        {"role": "assistant", "content": resp1.get("answer", "")}
    ]
    resp2 = send_chat_query(q2, history=history_t2)
    r2 = resp2.get("quick_replies", [])
    print(f"\nTurn 2 Q: '{q2}' (kèm history Turn 1)")
    print(f"Turn 2 Quick Replies: {r2}")
    assert_no_redundancy(r2, [q1], q2)
    # Phải gợi ý: Smart Lounge / VNeID / Hạn mức 10 triệu
    assert any(any(k in r.lower() for k in ["smart lounge", "vneid", "10 triệu", "tài khoản"]) for r in r2), f"Turn 2 phải gợi ý Smart Lounge hoặc VNeID, got: {r2}"
    print("✅ TEST 3 PASSED: Hành trình mở tài khoản và giải pháp không có NFC điều hướng chuẩn xác.")


def test_topic_switching():
    print_separator("TEST 4: CHUYỂN ĐỔI CHỦ ĐỀ GIỮA CHỪNG (CROSS-PRODUCT TOPIC SWITCHING)")

    # Turn 1: Hỏi vay
    q1 = "Điều kiện vay tiêu dùng Quick Loan cần gì?"
    resp1 = send_chat_query(q1, history=[])
    history = [
        {"role": "user", "content": q1},
        {"role": "assistant", "content": resp1.get("answer", "")}
    ]

    # Turn 2: Đột ngột chuyển sang hỏi mở thẻ Visa Platinum ảo
    q2 = "Tôi muốn mở thẻ Visa Platinum ảo thì làm sao?"
    resp2 = send_chat_query(q2, history=history)
    r2 = resp2.get("quick_replies", [])
    print(f"Turn 1 (Vay): '{q1}'")
    print(f"Turn 2 (Thẻ): '{q2}'")
    print(f"Turn 2 Quick Replies: {r2}")
    # Tuyệt đối không được gợi ý câu hỏi của Vay vốn!
    for r in r2:
        assert "vay" not in r.lower(), f"Chuyển sang Thẻ nhưng vẫn gợi ý Vay: {r}"
    # Phải thuộc về Thẻ
    assert any(any(k in r.lower() for k in ["thẻ", "visa", "hạn mức", "phí thường niên"]) for r in r2), f"Phải gợi ý liên quan đến Thẻ, got: {r2}"
    print("✅ TEST 4 PASSED: Tự động phát hiện chuyển đổi chủ đề, không giữ lại câu hỏi của dịch vụ cũ.")


def test_security_pin_journey():
    print_separator("TEST 5: HÀNH TRÌNH BẢO MẬT & QUÊN MÃ PIN (SECURITY & PIN)")

    # Turn 1: Quên mã PIN
    q1 = "Tôi bị quên mã PIN giao dịch thì làm sao để lấy lại?"
    resp1 = send_chat_query(q1, history=[])
    r1 = resp1.get("quick_replies", [])
    print(f"Turn 1 Q: '{q1}'")
    print(f"Turn 1 Quick Replies: {r1}")

    # Turn 2: Đổi mã PIN
    q2 = "Hướng dẫn đổi mã PIN giao dịch"
    history_t2 = [
        {"role": "user", "content": q1},
        {"role": "assistant", "content": resp1.get("answer", "")}
    ]
    resp2 = send_chat_query(q2, history=history_t2)
    r2 = resp2.get("quick_replies", [])
    print(f"\nTurn 2 Q: '{q2}' (kèm history Turn 1)")
    print(f"Turn 2 Quick Replies: {r2}")
    assert_no_redundancy(r2, [q1], q2)
    # Phải hướng tới Smart OTP hoặc Quản lý thiết bị
    assert any(any(k in r.lower() for k in ["smart otp", "thiết bị", "bảo mật"]) for r in r2), f"Phải gợi ý Smart OTP hoặc bảo mật, got: {r2}"
    print("✅ TEST 5 PASSED: Hành trình bảo mật hướng khách hàng tới Smart OTP và quản lý thiết bị an toàn.")


def test_bca_and_terms_journey():
    print_separator("TEST 6: HÀNH TRÌNH BỘ CÔNG AN, VNEID & ĐIỀU KHOẢN APP (BCA & TERMS)")

    # Turn 1: Định danh VNeID
    q1 = "Hướng dẫn định danh mức 2 qua VNeID theo đề án 06 Bộ Công An"
    resp1 = send_chat_query(q1, history=[])
    r1 = resp1.get("quick_replies", [])
    print(f"Turn 1 Q: '{q1}'")
    print(f"Turn 1 Quick Replies: {r1}")
    assert len(r1) >= 2
    assert_no_redundancy(r1, [], q1)

    # Turn 2: Điều khoản bảo vệ dữ liệu Nghị định 13
    q2 = "Quy định bảo vệ dữ liệu cá nhân theo Nghị định 13 trên App Sen Hồng"
    history_t2 = [
        {"role": "user", "content": q1},
        {"role": "assistant", "content": resp1.get("answer", "")}
    ]
    resp2 = send_chat_query(q2, history=history_t2)
    r2 = resp2.get("quick_replies", [])
    print(f"\nTurn 2 Q: '{q2}' (kèm history Turn 1)")
    print(f"Turn 2 Quick Replies: {r2}")
    assert len(r2) >= 2
    assert_no_redundancy(r2, [q1], q2)
    assert any(any(k in r.lower() for k in ["đồng ý", "dữ liệu", "tài khoản", "trọng tài", "viac"]) for r in r2)
    print("✅ TEST 6 PASSED: Hành trình pháp lý BCA và Điều khoản dịch vụ sinh gợi ý chuẩn mực.")


if __name__ == "__main__":
    print("\n🚀 BẮT ĐẦU KIỂM THỬ TOÀN DIỆN: TỐI ƯU GỢI Ý AI DỰA VÀO CÂU HỎI TRƯỚC ĐÓ")
    test_loan_journey_multi_turn()
    test_savings_journey_multi_turn()
    test_onboarding_nfc_journey_multi_turn()
    test_topic_switching()
    test_security_pin_journey()
    test_bca_and_terms_journey()
    print("\n🎉 TẤT CẢ 6/6 HÀNH TRÌNH ĐA LƯỢT ĐỀU HOÀN THÀNH VƯỢT TRỘI 100%!")
