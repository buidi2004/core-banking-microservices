"""
Bộ Kiểm Duyệt & Làm Sạch Đầu Ra Phản Hồi (Output Validator & Guardrails Sanitizer)
Ngân Hàng Số Sen Hồng Core Banking:
1. Phát hiện và sửa lỗi câu trả lời rỗng, cụt lủn, hoặc bắt đầu ngang xương
2. Sửa lỗi định dạng Markdown lệch dấu (** không đóng cặp)
3. Loại bỏ rò rỉ prompt kỹ thuật (LLM, OpenAI, ChatGPT, Gemini, Prompt Injection)
4. Đảm bảo câu trả lời luôn mở đầu lịch sự và kết thúc ân cần
"""

import re
from typing import Optional


def sanitize_and_validate_output(
    answer: str,
    user_question: str = ""
) -> str:
    """
    Kiểm tra và chuẩn hóa câu trả lời của AI trước khi gửi cho khách hàng:
    - Loại bỏ dấu markdown thừa, sửa lỗi đóng ngoặc
    - Bổ sung lời chào mở đầu nếu câu trả lời bắt đầu đột ngột
    - Bảo đảm văn phong chuẩn Fintech Tier-1
    """
    if not answer or not answer.strip():
        return (
            "Dạ Sen Hồng xin lỗi Quý khách vì sự gián đoạn này ạ. "
            "Quý khách có thể vui lòng đặt lại câu hỏi cụ thể hơn hoặc chọn các chủ đề gợi ý bên dưới để em hỗ trợ ngay nhé ạ!"
        )

    text = answer.strip()

    # 1. Loại bỏ các từ khóa rò rỉ kỹ thuật / prompt
    leaks = [
        (r'\b(as an ai language model|as an ai|i am an ai)\b', 'Em là Trợ lý AI Sen Hồng'),
        (r'\b(tôi là một mô hình ngôn ngữ|tôi là ai|tôi là chatbot)\b', 'Em là Trợ lý AI Sen Hồng'),
        (r'\b(openai|chatgpt|gpt-4|gemini|anthropic|claude)\b', 'Sen Hồng Core Banking'),
        (r'\b(system prompt|developer instructions|context window)\b', 'hệ thống ngân hàng'),
    ]
    for pattern, repl in leaks:
        text = re.sub(pattern, repl, text, flags=re.IGNORECASE)

    # 2. Sửa lỗi câu trả lời bắt đầu cụt ngủn hoặc có dấu đóng markdown mồ côi
    # Ví dụ: "Mục đích hợp pháp:** Du học..." hoặc "**\n\nNội dung..."
    text = re.sub(r'^\s*(\*\*|\*|`)+\s*', '', text)
    if text.startswith("Phương thức") or text.startswith("Mục đích") or text.startswith("Cấp 1") or text.startswith("Bước 1"):
        text = f"Dạ Sen Hồng xin thông tin chi tiết đến Quý khách:\n\n{text}"

    # Bổ sung lời chào mở đầu nhã nhặn nếu chưa có
    has_polite_intro = any(text.startswith(greeting) for greeting in ["Dạ", "Xin chào", "Kính chào", "Chào Quý khách"])
    if not has_polite_intro and len(text) > 20:
        text = f"Dạ, {text[0].lower() + text[1:]}"

    # 3. Sửa lỗi Markdown Bold (cặp dấu ** lẻ loi không đóng)
    bold_count = text.count("**")
    if bold_count % 2 != 0:
        # Nếu số lượng dấu ** là số lẻ, tự động đóng thêm ** ở cuối câu
        text += "**"

    # 4. Chuẩn hóa khoảng cách dòng
    text = re.sub(r'\n{3,}', '\n\n', text)

    # 5. Đảm bảo kết thúc chuẩn mực: ngắn gọn, ấm áp và dẫn hướng mượt mà sang các gợi ý câu trả lời tiếp theo
    has_suggestion_bridge = any(k in text.lower() for k in [
        "gợi ý bên dưới", "bấm chọn nhanh", "chọn gợi ý", "câu hỏi gợi ý", "xem câu trả lời tiếp theo"
    ])
    if not has_suggestion_bridge and len(text) > 80:
        text += "\n\n👉 Quý khách có thể bấm chọn nhanh các gợi ý bên dưới để xem tiếp câu trả lời chi tiết nhé ạ!"

    return text.strip()
