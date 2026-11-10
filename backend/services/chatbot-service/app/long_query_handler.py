"""
Module: Long Query & Compound Intent Handler
Chuyên trách xử lý các câu hỏi dài, phức tạp, đa ý định của khách hàng:
1. Gói Vay tiêu dùng Quick Loan toàn diện (Điều kiện + Thủ tục + Lãi suất + Giải ngân + Hạn mức).
2. Tư vấn Tiết kiệm So sánh kỳ hạn (12 tháng vs 24 tháng) & Rút trước hạn một phần theo TT 04/2022/TT-NHNN.
3. Sự cố Tra soát Chuyển khoản Napas 24/7 (Bị trừ tiền nhưng chưa nhận, Cam kết bảo toàn tiền Saga Ledger, Tạo yêu cầu tra soát).
4. Thẻ ảo quốc tế Visa Platinum Virtual toàn diện (Biểu phí 0đ, Hạn mức 100tr, Thanh toán quốc tế Netflix/Spotify, Apple Pay).
5. Quy định Sinh trắc học Quyết định 2345 (Hạn mức quét khuôn mặt, Vị trí đầu đọc NFC theo dòng máy iPhone/Android).
"""

import re
from typing import Optional, Dict, Any, List
from app import rate_config
from app.financial_calculator import extract_amount_from_text, format_vnd


def handle_comprehensive_long_query(query: str) -> Optional[Dict[str, Any]]:
    """
    Nhận diện và phản hồi trọn vẹn, có cấu trúc các câu hỏi dài (Long / Compound Queries).
    Trả về dict {'answer': ..., 'quick_replies': ..., 'suggested_action': ..., 'sources': ...}
    hoặc None nếu không phải câu hỏi dài đặc thù.
    """
    q_lower = query.lower()
    words = q_lower.split()

    # Chỉ xử lý các câu hỏi có độ dài từ 8 từ trở lên hoặc chứa nhiều ý kết hợp
    if len(words) < 8:
        return None

    # Ngoại lệ: Nếu câu hỏi yêu cầu mô phỏng kế hoạch tài chính lãi kép dài hạn 5-10 năm
    # thì nhường quyền cho Financial Advisory Engine (Robo-Advisor) sinh bảng tính chi tiết
    if any(k in q_lower for k in [
        "tự nó tính", "tu no tinh", "tu nso tinh", "10 năm", "10 nam", "10 namw",
        "vài năm", "vai nam", "lãi kép", "lai kep", "tiền trong tài khoản để tiết kiệm"
    ]):
        return None

    # =========================================================================
    # KỊCH BẢN 26: TƯ VẤN ĐƯA RA CÁC PHƯƠNG ÁN TÀI CHÍNH TOÀN DIỆN CHO NGƯỜI DÙNG (ACTIONABLE FINANCIAL OPTIONS)
    # Ví dụ: "Đưa ra phương án cho người dùng", "Có những phương án tài chính nào", "Nên chọn phương án nào", "Tư vấn phương án xử lý"
    # =========================================================================
    has_options_term = any(k in q_lower for k in [
        "đưa ra phương án", "dua ra phuong an", "phương án cho người dùng", "phuong an cho nguoi dung",
        "các phương án", "cac phuong an", "tư vấn phương án", "tu van phuong an",
        "nên chọn phương án nào", "nen chon phuong an nao", "có những phương án gì", "co nhung phuong an gi",
        "phương án xử lý", "phuong an xu ly", "giải pháp tài chính", "giai phap tai chinh",
        "lựa chọn tài chính", "lua chon tai chinh", "phương án hành động", "phuong an hanh dong",
        "phương án nào", "phuong an nao", "phương án gì", "phuong an gi", "có phương án nào", "co phuong an nao"
    ]) or (
        any(k in q_lower for k in ["phương án", "phuong an", "giải pháp", "giai phap"]) and
        any(k in q_lower for k in ["kẹt tiền", "sổ tiết kiệm", "tiền nhàn rỗi", "thẻ tín dụng", "nợ thẻ", "người dùng", "cho tôi"])
    )
    if has_options_term:
        is_tight_money = any(k in q_lower for k in ["kẹt tiền", "ket tien", "cần tiền gấp", "can tien gap", "chưa đáo hạn", "chua dao han", "rút sổ", "rut so", "thấu chi", "thau chi"])
        is_card_debt = any(k in q_lower for k in ["nợ thẻ", "no the", "thẻ tín dụng", "the tin dung", "sao kê", "sao ke", "trả góp 0%", "tra gop 0%"])

        if is_tight_money:
            answer = (
                "Dạ Sen Hồng Bank xin đưa ra **3 Phương Án Xử Lý Cấp Bách Khi Kẹt Tiền Mà Đang Có Sổ Tiết Kiệm** "
                "để Quý khách lựa chọn giải pháp tối ưu nhất:\n\n"
                "🎯 **1. Phương Án 1 (Khuyên Dùng - Vay Thấu Chi Cầm Cố Sổ Tiết Kiệm):**\n"
                "  - Hạn mức vay đến **85% - 90% giá trị sổ**, duyệt tự động online trong 30 giây.\n"
                "  - Lãi suất chỉ chênh **+1.5% - 2%/năm** so với lãi suất sổ, chỉ tính theo số ngày vay thực tế.\n"
                "  - **Lợi ích lớn nhất:** Bảo toàn trọn vẹn 100% tiền lãi của sổ tiết kiệm kỳ hạn ban đầu (không bị mất lãi).\n\n"
                "🔄 **2. Phương Án 2 (Linh Hoạt - Rút Một Phần Gốc Theo Thông Tư 04/2022/TT-NHNN):**\n"
                "  - Rút đúng số tiền cần thiết; phần tiền rút chịu lãi không kỳ hạn **0.2%/năm**.\n"
                f"  - **Phần gốc còn lại trong sổ:** Vẫn tiếp tục được giữ nguyên lãi suất kỳ hạn cao (**{rate_config.SAVINGS_RATES[12]:.1f}% - {rate_config.SAVINGS_RATES[24]:.1f}%/năm**).\n"
                "  - **Lợi ích:** Không phát sinh khoản nợ vay nào trên hệ thống.\n\n"
                "⚡ **3. Phương Án 3 (Cấp Tốc - Vay Tiêu Dùng Quick Loan 1 Phút):**\n"
                f"  - Giải ngân online vào ví từ 5 đến 50 triệu không cần thế chấp, lãi {rate_config.DEFAULT_LOAN_MONTHLY_RATE:.1f}%/tháng dư nợ giảm dần.\n"
                "  - **Đặc quyền:** **Miễn phí 100%** phí tất toán trước hạn, có tiền trả ngay không bị phạt.\n\n"
                "⚖️ **Ma Trận So Sánh:** Phương án 1 tối đa hóa tiền lãi, Phương án 2 không mang nợ, Phương án 3 giải ngân siêu tốc 1 phút.\n\n"
                "👉 Quý khách có thể bấm chọn nhanh các gợi ý bên dưới để xem tiếp câu trả lời chi tiết cho từng phương án nhé ạ!"
            )
            return {
                "answer": answer,
                "quick_replies": ["Vay thấu chi cầm cố sổ", "Rút một phần gốc TT 04", "Vay nhanh Quick Loan"],
                "suggested_action": {"label": "Quản lý sổ tiết kiệm", "route": "/savings"},
                "sources": ["Cẩm nang Các phương án tài chính Sen Hồng Bank", "Thông tư 04/2022/TT-NHNN"]
            }

        elif is_card_debt:
            answer = (
                "Dạ Sen Hồng Bank xin đưa ra **3 Phương Án Xử Lý Dư Nợ Thẻ Tín Dụng Đến Hạn** "
                "giúp Quý khách bảo vệ lịch sử tín dụng và tối ưu chi phí:\n\n"
                "🎯 **1. Phương Án 1 (Khuyên Dùng - Chuyển Đổi Trả Góp 0%):**\n"
                "  - Chuyển toàn bộ dư nợ sao kê sang trả góp 0% kỳ hạn 3 - 12 tháng trực tiếp trên app.\n"
                "  - Chỉ chịu phí chuyển đổi **1% - 2%** một lần duy nhất, tránh phí phạt trễ hạn **4% - 5%** và lãi suất thẻ 20% - 28%/năm.\n\n"
                "🔄 **2. Phương Án 2 (Duy Trì Điểm CIC Sạch - Trả Số Tiền Tối Thiểu 5%):**\n"
                "  - Thanh toán tối thiểu **5% dư nợ** trước ngày 15 để giữ lịch sử tín dụng Nhóm 1 sạch trên **CIC**.\n"
                "  - Sau đó thanh toán dứt điểm phần còn lại ngay khi nhận lương để chặn tiền lãi phát sinh.\n\n"
                "🛡️ **3. Phương Án 3 (Bảo Toàn 55 Ngày Miễn Lãi - Vay Thấu Chi Ví Thanh Toán Dứt Điểm):**\n"
                "  - Kích hoạt hạn mức thấu chi ví để thanh toán trọn vẹn 100% sao kê trước ngày 15.\n"
                "  - **Bảo Toàn 55 Ngày Miễn Lãi** cho các kỳ thanh toán tiếp theo.\n\n"
                "👉 Quý khách có thể bấm chọn nhanh các gợi ý bên dưới để xem tiếp câu trả lời chi tiết nhé ạ!"
            )
            return {
                "answer": answer,
                "quick_replies": ["Chuyển đổi trả góp 0%", "Thanh toán tối thiểu 5%", "Biểu phí thẻ tín dụng"],
                "suggested_action": {"label": "Quản lý thẻ tín dụng", "route": "/cards"},
                "sources": ["Quy chế phát hành thẻ tín dụng Visa Platinum Sen Hồng", "Cẩm nang Các phương án tài chính"]
            }

        else:
            answer = (
                "Dạ Sen Hồng Bank xin đưa ra **3 Phương Án Phân Bổ Vốn & Quản Trị Tài Chính Toàn Diện** "
                "để Quý khách lựa chọn giải pháp phù hợp nhất với khẩu vị tài chính của mình:\n\n"
                "🎯 **1. Phương Án 1 (Khuyên Dùng - Chiến Lược Bậc Thang Cân Bằng Laddering):**\n"
                f"  - 📈 **60% Vốn:** Gửi Tiết kiệm Online kỳ hạn **12 - 24 tháng (lãi suất {rate_config.SAVINGS_RATES[12]:.1f}% - {rate_config.SAVINGS_RATES[24]:.1f}%/năm)** để tối ưu lợi nhuận.\n"
                f"  - 🔄 **30% Vốn:** Gửi Tiết kiệm Online kỳ hạn **3 - 6 tháng (lãi suất đến {rate_config.SAVINGS_RATES[6]:.1f}%/năm)** để sẵn sàng xoay xở khi cần tiền.\n"
                "  - 💵 **10% Vốn:** Giữ trong Ví Sen Hồng (**0.2%/năm**) để chi tiêu sinh hoạt hàng ngày.\n"
                "  - **Đánh giá:** Cân bằng hoàn hảo giữa tối đa hóa tiền lãi và tính thanh khoản linh hoạt.\n\n"
                "🚀 **2. Phương Án 2 (Tối Đa Hóa Lợi Nhuận Lãi Kép Dài Hạn):**\n"
                f"  - Gửi trọn 100% vốn vào kỳ hạn **24 - 36 tháng lãi suất đỉnh {rate_config.SAVINGS_RATES[36]:.1f}%/năm**, tự động tái tục cả gốc và lãi.\n"
                "  - Bảo toàn vốn tuyệt đối theo **Thông tư 04/2022/TT-NHNN** (khi cần gấp vẫn được rút một phần gốc bảo toàn lãi kỳ hạn).\n"
                "  - **Đánh giá:** Tăng trưởng tài sản mạnh mẽ nhất, đánh bại hoàn toàn lạm phát.\n\n"
                "🛡️ **3. Phương Án 3 (Đa Dạng Hóa Danh Mục & Phòng Thủ Vĩ Mô):**\n"
                "  - **50%:** Tiết kiệm online an toàn sinh lời cố định.\n"
                "  - **30%:** Tích sản Vàng miếng SJC hoặc Chứng chỉ quỹ mở (Mutual Fund).\n"
                "  - **20%:** Quỹ dự phòng khẩn cấp 3 - 6 tháng chi phí sinh hoạt.\n"
                "  - **Đánh giá:** Phòng hộ rủi ro lạm phát và biến động kinh tế vĩ mô.\n\n"
                "⚖️ **Ma Trận So Sánh:** Phương án 1 phù hợp 85% người dùng, Phương án 2 cho tiền rảnh rỗi dài hạn, Phương án 3 cho khẩu vị đa dạng hóa.\n\n"
                "👉 Quý khách có thể bấm chọn nhanh các gợi ý bên dưới để xem tiếp câu trả lời chi tiết cho từng phương án nhé ạ!"
            )
            return {
                "answer": answer,
                "quick_replies": ["Phương án Bậc thang (Khuyên dùng)", "Phương án Lãi kép dài hạn", "Phương án Đa dạng danh mục"],
                "suggested_action": {"label": "Mở sổ tiết kiệm online", "route": "/savings"},
                "sources": ["Cẩm nang Các phương án tài chính toàn diện Sen Hồng Bank", "Thông tư 04/2022/TT-NHNN"]
            }

    # =========================================================================
    # KỊCH BẢN 12: HỒ SƠ & GIẤY TỜ ĐỂ TẠO TÀI KHOẢN APP (MỞ TÀI KHOẢN NGÂN HÀNG SỐ)
    # Ví dụ: "Để tạo tài khoản app Sen Hồng thì cần những giấy tờ gì và điều kiện bao nhiêu tuổi?"
    # =========================================================================
    has_account_create_terms = any(k in q_lower for k in [
        "tạo tài khoản", "tao tai khoan", "mở tài khoản", "mo tai khoan",
        "tạo app", "tao app", "mở app", "mo app", "đăng ký tài khoản", "dang ky tai khoan", "đăng ký app"
    ])
    has_docs_query = any(k in q_lower for k in [
        "giấy tờ", "giay to", "hồ sơ", "ho so", "cần những gì", "can nhung gi", "cần gì", "thủ tục", "thu tuc"
    ])

    if has_account_create_terms and has_docs_query:
        answer = (
            "Dạ để **Tạo tài khoản / Mở ứng dụng Ngân hàng Số Sen Hồng** trực tuyến 100% qua eKYC, "
            "Quý khách chỉ cần chuẩn bị danh mục giấy tờ và điều kiện đơn giản như sau ạ:\n\n"
            "1. 🪪 **Giấy tờ tùy thân bắt buộc (Chuẩn bị 01 loại duy nhất):**\n"
            "  - **Thẻ Căn cước** (cấp theo Luật Căn cước 2023) hoặc **Thẻ CCCD gắn chip 12 số** còn thời hạn sử dụng do Bộ Công An cấp.\n"
            "  - *(Lưu ý: CMND 9 số cũ hoặc CCCD mã vạch không có chip đã ngừng hỗ trợ mở tài khoản ngân hàng điện tử theo quy định của NHNN & Bộ Công An).*\n\n"
            "2. 📱 **Điều kiện Thuê bao & Thiết bị:**\n"
            "  - **Số điện thoại chính chủ:** Thuê bao di động trùng khớp thông tin cá nhân trên cơ sở dữ liệu nhà mạng viễn thông.\n"
            "  - **Điện thoại thông minh:** Có camera chụp ảnh chân dung rõ nét và hỗ trợ kết nối **NFC** để đọc chip vi mạch CCCD.\n"
            "  - 👉 **Nếu điện thoại không có NFC:** Quý khách mang thẻ CCCD gắn chip đến bất kỳ điểm **Sen Hồng Smart Lounge** trên toàn quốc để giao dịch viên hỗ trợ quét chip miễn phí chỉ trong 2 phút.\n"
            "  - 👉 **Nếu có VNeID Mức 2:** Quý khách có thể chọn mở tài khoản trực tiếp qua tài khoản định danh VNeID mà không cần chụp lại thẻ.\n\n"
            "3. ⚖️ **Độ tuổi & Khách hàng Nước ngoài:**\n"
            "  - Công dân Việt Nam từ **đủ 15 tuổi trở lên**, có đầy đủ năng lực hành vi dân sự.\n"
            "  - Khách hàng người nước ngoài: Cần Hộ chiếu (còn hạn từ 6 tháng trở lên) kèm Thị thực/Thẻ tạm trú (còn hạn từ 12 tháng trở lên) mở trực tiếp tại quầy.\n\n"
            "Quý khách có thể bấm nút **[Đăng ký tài khoản ngay]** bên dưới để kích hoạt tài khoản chỉ trong 30 giây ạ!\n\n"
            "👉 Quý khách có thể bấm chọn nhanh các gợi ý bên dưới để xem tiếp câu trả lời chi tiết nhé ạ!"
        )
        return {
            "answer": answer,
            "quick_replies": ["Đăng ký tài khoản ngay", "Quét chip NFC CCCD", "Định danh VNeID"],
            "suggested_action": {"label": "Đăng ký tài khoản ngay", "route": "/auth/register"},
            "sources": ["Cẩm nang Giấy tờ Mở tài khoản Sen Hồng Bank", "Thông tư 17/2024/TT-NHNN"]
        }

    # =========================================================================
    # KỊCH BẢN 13: HỒ SƠ & GIẤY TỜ ĐỂ VAY TIỀN TRÊN APP (CÓ CẦN BẢNG LƯƠNG KHÔNG)
    # Ví dụ: "Vay tiền trên app Sen Hồng cần những giấy tờ gì? Có cần nộp bảng lương hay sao kê không?"
    # =========================================================================
    has_loan_terms = any(k in q_lower for k in ["vay", "quick loan", "vay tiền", "vay tien", "vay vốn", "vay von"])
    has_loan_doc_query = any(k in q_lower for k in [
        "giấy tờ", "giay to", "hồ sơ", "ho so",
        "bảng lương", "bang luong", "sao kê", "sao ke", "chứng minh thu nhập", "chung minh thu nhap"
    ])
    has_interest_rate_inquiry = any(k in q_lower for k in ["lãi suất", "lai suat", "lãi bao nhiêu", "tính ra sao", "tính sao"])

    if has_loan_terms and has_loan_doc_query and not has_interest_rate_inquiry:
        answer = (
            "Dạ Sen Hồng Bank xin tư vấn chi tiết về **Hồ sơ, Giấy tờ vay vốn** theo từng hạn mức để Quý khách chuẩn bị thuận tiện nhất ạ:\n\n"
            "1. 🚀 **GÓI VAY NHANH QUICK LOAN (Từ 5 triệu đến 50 triệu VNĐ) - 100% ONLINE:**\n"
            "  - **Giấy tờ yêu cầu:** **DUY NHẤT 01 GIẤY TỜ** là **Thẻ Căn cước / CCCD gắn chip chính chủ** đã eKYC trên App Sen Hồng.\n"
            "  - **Có cần bảng lương không?** 👉 **HOÀN TOÀN KHÔNG CẦN BẢNG LƯƠNG**, không cần sao kê giấy, không cần thế chấp tài sản. Hệ thống tự động chấm điểm tín dụng dựa trên lịch sử giao dịch và điểm CIC.\n"
            "  - **Lãi suất:** Ưu đãi chỉ từ **1.2% - 1.5%/tháng** tính theo **dư nợ giảm dần**.\n"
            "  - **Điều kiện:** Tuổi từ 18 - 60, không có nợ xấu CIC (nhóm 2 - 5).\n"
            "  - **Thời gian giải ngân:** Phê duyệt trong **30 giây**, tiền về ví sau **1 phút**.\n\n"
            "2. 🏢 **GÓI VAY TIÊU DÙNG HẠN MỨC CAO (Từ 50 triệu đến 200 triệu VNĐ):**\n"
            "  - Thẻ Căn cước / CCCD gắn chip chính chủ.\n"
            "  - **Chứng minh thu nhập (Chuẩn bị 01 trong 3 loại):**\n"
            "    + Bản sao kê tài khoản nhận lương 3 - 6 tháng gần nhất (từ 5 triệu/tháng).\n"
            "    + Hoặc Hợp đồng lao động chính thức (từ 12 tháng trở lên) kèm xác nhận lương.\n"
            "    + Hoặc ảnh chụp thông tin tham gia Bảo hiểm Xã hội trên ứng dụng **VssID**.\n"
            "    + 01 Hóa đơn điện, nước hoặc internet 3 tháng gần nhất tại nơi cư trú.\n\n"
            "3. 🏪 **GÓI VAY HỘ KINH DOANH / TIỂU THƯƠNG (Hạn mức đến 300 triệu VNĐ):**\n"
            "  - Thẻ Căn cước của chủ hộ kinh doanh + Giấy ĐKKD hoặc hợp đồng thuê sạp/mặt bằng.\n"
            "  - Biên lai nộp thuế môn bài/thuế khoán và lịch sử nhận tiền qua mã **VietQR Pro Sen Hồng** 3 - 6 tháng.\n\n"
            "Quý khách có thể bấm **[Vay nhanh Quick Loan]** bên dưới để kiểm tra hạn mức được cấp sẵn của mình mà không cần bất kỳ giấy tờ nào ạ!\n\n"
            "👉 Quý khách có thể bấm chọn nhanh các gợi ý bên dưới để xem tiếp câu trả lời chi tiết nhé ạ!"
        )
        return {
            "answer": answer,
            "quick_replies": ["Vay nhanh Quick Loan", "Bảng tính trả nợ chi tiết", "Biểu lãi suất vay"],
            "suggested_action": {"label": "Vay nhanh Quick Loan", "route": "/bills/quick-loan"},
            "sources": ["Cẩm nang Hồ sơ Vay vốn Sen Hồng Bank", "Quy chế Vay tiêu dùng tín chấp Quick Loan"]
        }

    # =========================================================================
    # KỊCH BẢN 1: GÓI VAY QUICK LOAN TOÀN DIỆN (Điều kiện + Lãi suất + Giải ngân)
    # Ví dụ: "em là nhân viên văn phòng... muốn tìm hiểu gói vay Quick Loan 30 triệu thì điều kiện thủ tục thế nào, lãi suất bao nhiêu và giải ngân có nhanh không?"
    # =========================================================================
    is_loan_mention = any(k in q_lower for k in ["vay", "quick loan", "khoản vay", "khoan vay"])
    has_loan_conditions = any(k in q_lower for k in ["điều kiện", "dieu kien", "thủ tục", "thu tuc", "hồ sơ", "ho so", "giấy tờ"])
    has_loan_rate = any(k in q_lower for k in ["lãi suất", "lai suat", "lãi bao nhiêu", "mỗi tháng trả bao nhiêu"])
    has_loan_disburse = any(k in q_lower for k in ["giải ngân", "giai ngan", "bao lâu", "có nhanh không", "thời gian nhận tiền"])

    if is_loan_mention and (has_loan_conditions or has_loan_rate or has_loan_disburse):
        extracted_amt = extract_amount_from_text(query)
        amt_str = f" khoản vay **{format_vnd(extracted_amt)}**" if (extracted_amt and extracted_amt >= 5_000_000) else " gói vay tiêu dùng Quick Loan"
        amt_calc_text = ""
        if extracted_amt and extracted_amt >= 5_000_000 and extracted_amt <= 50_000_000:
            monthly_principal = extracted_amt / 12
            first_interest = extracted_amt * 0.012
            amt_calc_text = (
                f"- 📊 **Dự tính trả góp mẫu cho {format_vnd(extracted_amt)} (Kỳ hạn 12 tháng):**\n"
                f"  + Tiền gốc trả cố định hàng tháng: **{format_vnd(monthly_principal)}/tháng**.\n"
                f"  + Tiền lãi tháng đầu tiên (1.2%/tháng): **{format_vnd(first_interest)}**.\n"
                f"  + Tổng tiền trả tháng đầu: **{format_vnd(monthly_principal + first_interest)}** (các tháng sau tiền lãi sẽ giảm dần theo dư nợ thực tế).\n"
            )

        answer = (
            f"Dạ Sen Hồng Bank xin tư vấn chi tiết và trọn vẹn về{amt_str} để Quý khách nắm rõ thông tin ạ:\n\n"
            f"1. 📋 **Điều kiện & Thủ tục đăng ký:**\n"
            f"  - Là công dân Việt Nam từ đủ **18 đến 60 tuổi**.\n"
            f"  - Đang sở hữu tài khoản ví Sen Hồng đã hoàn tất định danh **eKYC Cấp 1 trở lên**.\n"
            f"  - Có CCCD gắn chip chính chủ còn hiệu lực, không có nợ xấu nhóm 2 trở lên tại CIC.\n"
            f"  - **Hồ sơ & Giấy tờ:** Chỉ cần duy nhất 01 Thẻ Căn cước / CCCD gắn chip chính chủ đã eKYC, **hoàn toàn không cần nộp bảng lương**, không cần sao kê giấy hay thế chấp tài sản.\n"
            f"  - **Thủ tục 100% online:** Thao tác hoàn tất trong 2 phút trên ứng dụng.\n\n"
            f"2. 📈 **Lãi suất & Biểu phí vay:**\n"
            f"  - **Lãi suất ưu đãi:** Chỉ từ **1.2% - 1.5%/tháng** (tương đương 14.4%/năm) tính trên **dư nợ giảm dần** (tiền lãi giảm đều qua từng tháng).\n"
            f"  - **Phí thẩm định hồ sơ:** **0 VNĐ (Miễn phí 100%)**.\n"
            f"  - **Phí tất toán trước hạn:** **0 VNĐ (Miễn phí 100%)**, Quý khách có thể trả hết nợ bất kỳ lúc nào mà không bị phạt.\n\n"
            f"{amt_calc_text}"
            f"3. ⚡ **Thời gian xét duyệt & Giải ngân:**\n"
            f"  - Hệ thống trí tuệ nhân tạo chấm điểm tín dụng tự động trong **30 giây**.\n"
            f"  - Tiền giải ngân được cộng trực tiếp vào số dư ví Sen Hồng chỉ sau **1 phút** kể từ khi ký hợp đồng điện tử bằng Smart OTP.\n\n"
            f"Quý khách có thể bấm nút **[Vay nhanh Quick Loan]** bên dưới để kiểm tra hạn mức và duyệt hồ sơ trực tuyến ngay ạ!\n\n"
            f"👉 Quý khách có thể bấm chọn nhanh các gợi ý bên dưới để xem tiếp câu trả lời chi tiết nhé ạ!"
        )
        return {
            "answer": answer,
            "quick_replies": ["Đăng ký vay ngay", "Bảng lịch trả nợ 12 tháng", "Biểu phí & Hạn mức"],
            "suggested_action": {"label": "Vay nhanh Quick Loan", "route": "/bills/quick-loan"},
            "sources": ["Quy chế vay tiêu dùng tín chấp Quick Loan", "Biểu lãi suất cho vay Sen Hồng Bank"]
        }

    # =========================================================================
    # KỊCH BẢN SO SÁNH: NÊN GỬI TIẾT KIỆM HAY VAY VỐN (So sánh 2 chiều khách quan)
    # Ví dụ: "Tôi đang phân vân nên gửi tiết kiệm hay vay vốn, hãy so sánh giúp tôi"
    # =========================================================================
    is_savings_mention = any(k in q_lower for k in ["tiết kiệm", "tiet kiem", "gửi tiền", "gui tien", "sổ tiết kiệm"])
    is_loan_mention_comp = any(k in q_lower for k in ["vay", "quick loan", "vay vốn", "vay von", "vay tiền", "vay tien"])
    is_comparing_savings_vs_loan = (
        is_savings_mention and is_loan_mention_comp and
        any(k in q_lower for k in [
            "so sánh", "so sanh", "phân vân", "phan van", "hay là", "hay la",
            "nên gửi tiết kiệm hay", "nen gui tiet kiem hay", "nên vay hay", "nen vay hay", "lựa chọn", "lua chon"
        ])
    )
    if is_comparing_savings_vs_loan:
        extracted_amt = extract_amount_from_text(query)
        amt_str = f" với số tiền **{format_vnd(extracted_amt)}**" if extracted_amt else ""
        answer = (
            f"Dạ Sen Hồng Bank xin phân tích và so sánh 2 chiều giữa **Gửi Tiết Kiệm** và **Vay Vốn**{amt_str} "
            f"để Quý khách dễ dàng đưa ra quyết định tài chính phù hợp nhất ạ:\n\n"
            f"1. 📈 **Chiều Gửi Tiết Kiệm Online (Tích lũy & Sinh lời an toàn):**\n"
            f"  - **Lãi suất hấp dẫn:** Từ **{rate_config.SAVINGS_RATES[6]:.1f}%/năm** (6 tháng), **{rate_config.SAVINGS_RATES[12]:.1f}%/năm** (12 tháng) đến **{rate_config.SAVINGS_RATES[36]:.1f}%/năm** (24 - 36 tháng).\n"
            f"  - **Ưu điểm:** Vốn được bảo hiểm tiền gửi và bảo toàn 100%, tiền lãi tự động sinh lời đều đặn.\n"
            f"  - **Tính thanh khoản (Thông tư 04/2022/TT-NHNN):** Quý khách được rút một phần tiền trước hạn khi cần, phần tiền còn lại vẫn giữ nguyên mức lãi suất ban đầu.\n"
            f"  - 👉 **Phù hợp khi:** Quý khách có nguồn tiền nhàn rỗi, muốn bảo vệ tài sản trước lạm phát và gia tăng thu nhập thụ động.\n\n"
            f"2. 💼 **Chiều Vay Tiêu Dùng Quick Loan (Cung cấp thanh khoản tức thì):**\n"
            f"  - **Lãi suất vay:** {rate_config.LOAN_RATE_RANGE_TEXT}.\n"
            f"  - **Ưu điểm:** Duyệt tự động AI trong 30 giây, giải ngân tiền vào ví trong **1 phút**, chỉ cần CCCD gắn chip, **0đ nộp bảng lương**, **0đ phí phạt tất toán trước hạn**.\n"
            f"  - 👉 **Phù hợp khi:** Quý khách đang cần vốn gấp cho chi tiêu, kinh doanh hoặc việc đột xuất mà không muốn tất toán sớm các sổ tiết kiệm đang có lãi suất cao.\n\n"
            f"Quý khách có thể bấm nút bên dưới để chọn dịch vụ phù hợp với nhu cầu hiện tại của mình ạ!\n\n"
            f"👉 Quý khách có thể bấm chọn nhanh các gợi ý bên dưới để xem tiếp câu trả lời chi tiết nhé ạ!"
        )
        return {
            "answer": answer,
            "quick_replies": ["Mở sổ tiết kiệm ngay", "Vay nhanh Quick Loan", "Bảng lịch trả nợ vay"],
            "suggested_action": {"label": "Mở sổ tiết kiệm", "route": "/bills/savings"},
            "sources": ["Biểu lãi suất tiết kiệm Sen Hồng", "Quy chế vay tiêu dùng Quick Loan"]
        }

    # =========================================================================
    # KỊCH BẢN 2: TƯ VẤN TIẾT KIỆM (So sánh kỳ hạn 12 vs 24 tháng & Rút một phần trước hạn)
    # Ví dụ: "Tôi đang có 200 triệu... gửi 12 tháng hay 24 tháng thì lãi suất cao hơn, và rút ra một phần có mất hết tiền lãi không?"
    # =========================================================================
    has_term_compare = any(k in q_lower for k in ["12 tháng hay 24 tháng", "12 thang hay 24 thang", "so sánh", "so sanh", "kỳ hạn nào", "ky han nao", "lãi cao hơn", "lai cao hon"])
    has_early_withdraw = any(k in q_lower for k in ["rút ra một phần", "rut ra mot phan", "rút trước hạn", "rut truoc han", "giữa chừng", "mất hết tiền lãi", "mất tiền lãi", "mất lãi", "bảo toàn lãi"])

    if is_savings_mention and not is_loan_mention_comp and (has_term_compare or has_early_withdraw):
        extracted_amt = extract_amount_from_text(query) or 200_000_000.0
        amt_fmt = format_vnd(extracted_amt)
        interest_12m = extracted_amt * (rate_config.SAVINGS_RATES[12] / 100.0)
        interest_24m = extracted_amt * (rate_config.SAVINGS_RATES[24] / 100.0) * 2

        answer = (
            f"Dạ với số tiền **{amt_fmt}**, Sen Hồng Bank xin giải đáp chi tiết băn khoăn về kỳ hạn và quy định rút vốn của Quý khách như sau ạ:\n\n"
            f"1. 📊 **So sánh lãi suất kỳ hạn 12 tháng vs 24 tháng:**\n"
            f"  - **Kỳ hạn 12 tháng ({rate_config.SAVINGS_RATES[12]:.1f}%/năm):** Tiền lãi nhận được sau 1 năm là **{format_vnd(interest_12m)}**. Ưu điểm: Thanh khoản tốt, tái tục linh hoạt sau mỗi năm.\n"
            f"  - **Kỳ hạn 24 tháng ({rate_config.SAVINGS_RATES[24]:.1f}%/năm):** Lãi suất cao hơn **+{rate_config.SAVINGS_RATES[24] - rate_config.SAVINGS_RATES[12]:.1f}%/năm**. Tổng tiền lãi nhận được sau 2 năm là **{format_vnd(interest_24m)}** (trung bình **{format_vnd(interest_24m / 2)}/năm**). Ưu điểm: Khóa mức lãi suất cao tối đa trong dài hạn.\n\n"
            f"2. 🛡️ **Quy định rút một phần tiền trước hạn (Thông tư 04/2022/TT-NHNN):**\n"
            f"  - **HOÀN TOÀN KHÔNG BỊ MẤT HẾT TIỀN LÃI**: Khi có việc đột xuất, Quý khách được quyền **rút một phần tiền gốc** trước hạn bất kỳ lúc nào.\n"
            f"  - **Cơ chế tính lãi bảo toàn:**\n"
            f"    + Số tiền rút sớm: Áp dụng lãi suất tiền gửi không kỳ hạn hiện hành (**0.2%/năm**).\n"
            f"    + **TOÀN BỘ PHẦN TIỀN GỐC CÒN LẠI VẪN ĐƯỢC GIỮ NGUYÊN LÃI SUẤT CÓ KỲ HẠN BAN ĐẦU ({rate_config.SAVINGS_RATES[12]:.1f}% hoặc {rate_config.SAVINGS_RATES[24]:.1f}%/năm)** cho đến ngày đáo hạn!\n\n"
            f"3. 💡 **Lời khuyên tài chính thông minh:** Quý khách có thể chia số tiền {amt_fmt} thành 2 sổ tiết kiệm online (ví dụ: 1 sổ 12 tháng và 1 sổ 24 tháng) để vừa tối ưu hóa lợi nhuận vừa đảm bảo tính linh hoạt thanh khoản.\n\n"
            f"Quý khách có thể mở sổ tiết kiệm online ngay trong 30 giây bằng nút bấm bên dưới ạ!\n\n"
            f"👉 Quý khách có thể bấm chọn nhanh các gợi ý bên dưới để xem tiếp câu trả lời chi tiết nhé ạ!"
        )
        return {
            "answer": answer,
            "quick_replies": ["Mở sổ tiết kiệm ngay", "Biểu lãi suất tiết kiệm", "Chiến lược tiết kiệm bậc thang"],
            "suggested_action": {"label": "Mở sổ tiết kiệm", "route": "/bills/savings"},
            "sources": ["Biểu lãi suất tiền gửi Sen Hồng Bank", "Quy chế tiền gửi theo Thông tư 04/2022/TT-NHNN"]
        }

    # =========================================================================
    # KỊCH BẢN 3: SỰ CỐ CHUYỂN KHOẢN NAPAS TREO TIỀN & BẢO TOÀN DÒNG TIỀN
    # Ví dụ: "trưa nay mình chuyển 15 triệu qua Napas sang Vietcombank chưa nhận được, ví bị trừ tiền, có bị mất tiền không và làm gì để tra soát?"
    # =========================================================================
    is_tx_issue = any(k in q_lower for k in ["chưa nhận được", "chua nhan duoc", "chưa thấy tiền", "tiền chưa qua", "tiền chưa tới"])
    is_money_deducted = any(k in q_lower for k in ["đã bị trừ tiền", "bị trừ tiền", "trừ tiền rồi", "ví đã trừ"])
    is_dispute_ask = any(k in q_lower for k in ["tra soát", "tra soat", "làm gì", "tiền có bị mất không", "có mất tiền không", "khiếu nại"])

    if (is_tx_issue or is_money_deducted) and is_dispute_ask:
        answer = (
            "Dạ Quý khách hoàn toàn an tâm, **TIỀN CỦA QUÝ KHÁCH ĐƯỢC BẢO TOÀN TUYỆT ĐỐI 100% VÀ KHÔNG THỂ BỊ MẤT** ạ!\n\n"
            "Sen Hồng Bank xin hướng dẫn Quý khách quy trình đối soát và xử lý tức thì như sau:\n\n"
            "1. ⏱️ **Thời gian hạch toán liên ngân hàng Napas 24/7:**\n"
            "  - Bình thường tiền sẽ về tài khoản thụ hưởng trong 1 - 3 giây. Tuy nhiên vào các khung giờ cao điểm chuyển mạch, ngân hàng nhận có thể mất từ **5 đến 30 phút** để cập nhật số dư.\n\n"
            "2. 🛡️ **Cơ chế bảo toàn dòng tiền (Saga Orchestration & Double-Entry Ledger):**\n"
            "  - Nếu đường truyền mạng Napas gặp sự cố ngắt kết nối, hệ thống sẽ tự động kích hoạt tiến trình hoàn tiền nguyên vẹn (**Reversal**) về lại ví Sen Hồng của Quý khách.\n\n"
            "3. 📝 **Các bước Quý khách cần làm ngay:**\n"
            "  - **Bước 1:** Vào mục **Lịch sử giao dịch** trên App Sen Hồng, bấm vào lệnh chuyển tiền đó để lấy **Mã chuẩn chi (Trace No)** hoặc bấm **Tải biên lai** gửi người nhận kiểm tra với ngân hàng thụ hưởng.\n"
            "  - **Bước 2:** Nếu sau 30 phút người nhận vẫn chưa thấy tiền, Quý khách bấm nút **[Lịch sử giao dịch & Tra soát]** bên dưới để tạo phiếu tra soát trực tuyến tự động.\n"
            "  - **Bước 3:** Hoặc liên hệ trực tiếp Tổng đài hỗ trợ 24/7 **1900-SENHONG** (1900 736 466) để tổng đài viên tra soát trực tiếp trên hệ thống Napas trong 5 phút ạ!\n\n"
            "👉 Quý khách có thể bấm chọn nhanh các gợi ý bên dưới để xem tiếp câu trả lời chi tiết nhé ạ!"
        )
        return {
            "answer": answer,
            "quick_replies": ["Xem lịch sử giao dịch", "Gửi yêu cầu tra soát", "Hotline 1900-SENHONG"],
            "suggested_action": {"label": "Lịch sử giao dịch & Tra soát", "route": "/history"},
            "sources": ["Quy trình tra soát khiếu nại liên ngân hàng Napas", "Tiêu chuẩn bảo toàn dòng tiền Core Banking"]
        }

    # =========================================================================
    # KỊCH BẢN 4: THẺ ẢO QUỐC TẾ VISA PLATINUM VIRTUAL TOÀN DIỆN
    # Ví dụ: "chuẩn bị đi nước ngoài muốn mở thẻ ảo Visa Platinum... có mất phí mở, phí thường niên không, hạn mức thanh toán ngày bao nhiêu, quẹt ở nước ngoài hay thanh toán Netflix Spotify được không?"
    # =========================================================================
    is_visa_mention = any(k in q_lower for k in ["visa", "thẻ ảo", "the ao", "platinum"])
    has_fee_check = any(k in q_lower for k in ["phí mở", "phí thường niên", "mất phí không", "mất bao nhiêu phí"])
    has_limit_or_global = any(k in q_lower for k in ["hạn mức", "han muc", "nước ngoài", "quốc tế", "netflix", "spotify", "apple pay", "google pay"])

    if is_visa_mention and (has_fee_check or has_limit_or_global):
        answer = (
            "Dạ, Thẻ ảo quốc tế **Visa Platinum Virtual** tại Sen Hồng Bank là lựa chọn hoàn hảo cho nhu cầu chi tiêu toàn cầu và thanh toán trực tuyến của Quý khách:\n\n"
            "1. 🆓 **Biểu phí phát hành & Duy trì:**\n"
            "  - **Phí phát hành thẻ:** **0 VNĐ (Miễn phí 100%)**, phát hành tức thì trong **30 giây** ngay trên ứng dụng.\n"
            "  - **Phí thường niên trọn đời:** **0 VNĐ (Miễn phí 100%)**, không kèm điều kiện chi tiêu tối thiểu.\n"
            "  - **Phí đổi mã bảo mật CVV động:** Miễn phí 100% không giới hạn số lần.\n\n"
            "2. 💰 **Hạn mức thanh toán trực tuyến:**\n"
            "  - Hạn mức tiêu chuẩn: Lên đến **100.000.000 VNĐ/ngày** (sau khi định danh eKYC Cấp 2).\n"
            "  - Quý khách có thể tự do điều chỉnh bật/tắt tính năng thanh toán trực tuyến và cài đặt hạn mức chi tiêu mỗi giao dịch ngay trong mục Quản lý thẻ.\n\n"
            "3. 🌍 **Khả năng thanh toán quốc tế & Nước ngoài:**\n"
            "  - **Thanh toán dịch vụ quốc tế:** Chấp nhận thanh toán 100% tại mọi nền tảng toàn cầu (Netflix, Spotify, Youtube Premium, Apple App Store, Google Play, vé máy bay, đặt phòng khách sạn quốc tế Agoda, Booking...).\n"
            "  - **Hỗ trợ Apple Pay & Google Wallet:** Dễ dàng liên kết vào ví điện thoại để chạm thanh toán không tiếp xúc (Contactless) tại các máy POS khi đi công tác nước ngoài.\n"
            "  - **Phí chuyển đổi ngoại tệ:** Cực kỳ ưu đãi chỉ **1.5%** trên giá trị giao dịch (thấp nhất thị trường, minh bạch không phụ phí ẩn).\n\n"
            "Quý khách có thể bấm nút **[Mở thẻ Visa Platinum]** bên dưới để kích hoạt thẻ và nhận thông tin số thẻ dùng ngay trong 30 giây ạ!\n\n"
            "👉 Quý khách có thể bấm chọn nhanh các gợi ý bên dưới để xem tiếp câu trả lời chi tiết nhé ạ!"
        )
        return {
            "answer": answer,
            "quick_replies": ["Mở thẻ Visa Platinum ngay", "Quản lý thẻ", "Biểu phí & Hạn mức"],
            "suggested_action": {"label": "Mở thẻ Visa Platinum", "route": "/cards"},
            "sources": ["Biểu phí dịch vụ Thẻ ảo quốc tế Visa Platinum Virtual Sen Hồng Bank"]
        }

    # =========================================================================
    # KỊCH BẢN 5: SINH TRẮC HỌC QĐ 2345 & HƯỚNG DẪN QUÉT CHIP NFC THEO THIẾT BỊ
    # Ví dụ: "quy định sinh trắc học theo quyết định 2345... iPhone thì quét chip NFC ở đâu và chuyển tiền từ bao nhiêu triệu bắt buộc quét khuôn mặt?"
    # =========================================================================
    is_biometric_mention = any(k in q_lower for k in ["sinh trắc học", "sinh trac hoc", "2345", "khuôn mặt", "nfc", "chip cccd"])
    has_device_or_limit = any(k in q_lower for k in ["iphone", "android", "samsung", "vị trí", "quét ở đâu", "bao nhiêu triệu", "bắt buộc"])

    if is_biometric_mention and has_device_or_limit:
        is_iphone = "iphone" in q_lower or "apple" in q_lower
        is_android = any(k in q_lower for k in ["android", "samsung", "xiaomi", "oppo"])
        pos_text = ""
        if is_iphone:
            pos_text = (
                "- 📱 **Vị trí ăng-ten NFC trên iPhone:** Nằm ở **mép đỉnh trên cùng mặt lưng máy** (khu vực nằm ngang cụm camera sau).\n"
                "  + **Mẹo quét thành công trong 3 giây:** Tháo ốp lưng (đặc biệt ốp có vòng nam châm MagSafe hoặc kim loại), áp phần chip vi mạch bằng đồng trên thẻ CCCD vào sát mép đỉnh lưng iPhone và giữ yên không rung tay trong 3 - 5 giây."
            )
        elif is_android:
            pos_text = (
                "- 📱 **Vị trí ăng-ten NFC trên Android (Samsung, Xiaomi, Oppo):** Nằm ở **chính giữa tâm mặt lưng máy**.\n"
                "  + **Mẹo quét thành công trong 3 giây:** Hãy đảm bảo đã bật tính năng NFC trong mục Cài đặt của điện thoại. Tháo ốp lưng và áp sát chip CCCD vào giữa mặt lưng máy, giữ yên trong 3 - 5 giây."
            )
        else:
            pos_text = (
                "- 📱 **Vị trí đầu đọc NFC trên từng dòng máy:**\n"
                "  + **iPhone:** Nằm ở **mép đỉnh trên cùng** mặt lưng máy (ngang cụm camera sau).\n"
                "  + **Android (Samsung, Xiaomi, Oppo...):** Nằm ở **chính giữa tâm mặt lưng** (vui lòng bật NFC trong phần Cài đặt điện thoại trước khi quét)."
            )

        answer = (
            "Dạ theo **Quyết định 2345/QĐ-NHNN** của Ngân hàng Nhà nước, Sen Hồng Bank xin giải đáp chi tiết về quy định sinh trắc học và mẹo quét chip NFC như sau ạ:\n\n"
            "1. 🛡️ **Hạn mức giao dịch bắt buộc phải xác thực khuôn mặt 3D:**\n"
            "  - Giao dịch chuyển tiền từ **10.000.000 VNĐ/lần** trở lên.\n"
            "  - Tổng số tiền các giao dịch chuyển tiền tích lũy trong ngày vượt quá **20.000.000 VNĐ/ngày**.\n"
            "  - Lần đầu tiên thực hiện giao dịch chuyển tiền trên thiết bị mới cài đặt ứng dụng Sen Hồng.\n"
            "  *(Các giao dịch dưới 10 triệu đồng/lần và tổng ngày dưới 20 triệu chỉ cần xác thực bằng mã PIN hoặc Face ID thông thường của máy, không bắt buộc quét lại dữ liệu Bộ Công an).*\n\n"
            f"2. {pos_text}\n\n"
            "3. 🚀 **Quyền lợi sau khi xác thực thành công:**\n"
            "  - Nâng hạn mức chuyển tiền trực tuyến lên tới **500.000.000 VNĐ/ngày**.\n"
            "  - Bảo vệ tài khoản an toàn tuyệt đối, ngăn chặn 100% rủi ro kẻ gian chiếm quyền thiết bị từ xa.\n\n"
            "Quý khách có thể bấm nút **[Quét chip NFC CCCD]** bên dưới để mở trực tiếp màn hình thu nhận dữ liệu chip ạ!\n\n"
            "👉 Quý khách có thể bấm chọn nhanh các gợi ý bên dưới để xem tiếp câu trả lời chi tiết nhé ạ!"
        )
        return {
            "answer": answer,
            "quick_replies": ["Quét chip NFC CCCD", "Hạn mức theo eKYC", "Chữ ký số Smart OTP"],
            "suggested_action": {"label": "Quét chip NFC CCCD", "route": "/profile/nfc-reader"},
            "sources": ["Quyết định 2345/QĐ-NHNN của Ngân hàng Nhà nước", "Hướng dẫn thu thập sinh trắc học qua chip CCCD"]
        }

    # =========================================================================
    # KỊCH BẢN 6: TƯ VẤN KINH TẾ VĨ MÔ, LẠM PHÁT & SO SÁNH TIẾT KIỆM VS VÀNG / CHỨNG KHOÁN
    # Ví dụ: "Tình hình lạm phát hiện nay gửi tiết kiệm có bị mất giá không? Nên gửi tiết kiệm hay mua vàng?"
    # =========================================================================
    has_inflation_concern = any(k in q_lower for k in [
        "lạm phát", "lam phat", "mất giá", "mat gia", "lãi suất thực", "lai suat thuc"
    ])
    has_investment_comparison = any(k in q_lower for k in [
        "mua vàng", "mua vang", "vàng hay tiết kiệm", "tiết kiệm hay vàng",
        "chứng khoán", "chung khoan", "bất động sản", "bat dong san", "đầu tư gì", "dau tu gi"
    ])
    is_macro_savings_query = any(k in q_lower for k in ["tiết kiệm", "tiet kiem", "gửi ngân hàng", "gui ngan hang"])

    if (has_inflation_concern and (is_macro_savings_query or has_investment_comparison)) or (has_investment_comparison and is_macro_savings_query):
        answer = (
            "Dạ trong bối cảnh kinh tế vĩ mô và chỉ số giá tiêu dùng hiện nay, Sen Hồng Bank xin phân tích chuyên sâu "
            "về **Lạm phát**, **Lãi suất thực dương** và **Chiến lược phân bổ tài sản an toàn** như sau ạ:\n\n"
            "1. 📈 **Phân tích Lãi suất Thực dương (Fisher Equation):**\n"
            "  - Mục tiêu lạm phát (CPI) bình quân của Việt Nam được Ngân hàng Nhà nước kiểm soát chặt chẽ ở mức **3.5% - 4.0%/năm**.\n"
            f"  - Lãi suất Tiết kiệm Online tại Sen Hồng hiện đạt **{rate_config.SAVINGS_RATES[12]:.1f}%/năm** (kỳ hạn 12 tháng) và **{rate_config.SAVINGS_RATES[24]:.1f}%/năm** (kỳ hạn 24 tháng).\n"
            f"  - 👉 **Lãi suất thực nhận sau lạm phát:** ${rate_config.SAVINGS_RATES[12]:.1f}\\% - 3.8\\% = \\mathbf{{+{rate_config.SAVINGS_RATES[12] - 3.8:.1f}\\%/năm}}$ (12 tháng) hoặc $\\mathbf{{+{rate_config.SAVINGS_RATES[24] - 3.8:.1f}\\%/năm}}$ (24 tháng).\n"
            "  - **Kết luận:** Tiền gửi tiết kiệm tại Sen Hồng **không hề bị mất giá** mà vẫn tăng trưởng thực dương bền vững, bảo toàn sức mua tuyệt đối so với giữ tiền mặt.\n\n"
            "2. ⚖️ **So sánh Tiết kiệm Ngân hàng vs Vàng & Bất động sản:**\n"
            "  - 💎 **Tiết kiệm Sen Hồng:** Rủi ro gần như bằng 0 (được bảo hiểm tiền gửi NHNN), dòng tiền lãi thụ động cố định hàng tháng/cuối kỳ. Đặc biệt theo **Thông tư 04/2022/TT-NHNN**, Quý khách được rút một phần tiền gốc khi cần gấp mà phần còn lại **vẫn giữ nguyên lãi suất có kỳ hạn**.\n"
            "  - 🥇 **Vàng (SJC / 9999):** Kênh phòng thủ tốt nhưng chênh lệch giá Mua - Bán (Spread) thường lớn từ 1 - 2 triệu/lượng, không sinh dòng tiền thụ động và có rủi ro cất giữ.\n"
            "  - 🏢 **Bất động sản / Chứng khoán:** Tiềm năng tăng trưởng nhưng thanh khoản thấp, biên độ biến động mạnh và đòi hỏi vốn lớn.\n\n"
            "3. 🏛️ **Khuyến nghị Phân bổ Danh mục (Kim Tự Tháp Tài Chính):**\n"
            "  - Dành **50% - 60%** tài sản cho Tiền gửi Tiết kiệm Sen Hồng làm trụ cột phòng thủ vững chắc.\n"
            "  - Dành **20% - 30%** cho vàng hoặc tích lũy tài sản mục tiêu dài hạn.\n"
            "  - Dành **10% - 15%** cho các kênh đầu tư mạo hiểm nếu có kiến thức chuyên môn.\n\n"
            f"Quý khách có thể bấm nút **[Mở sổ tiết kiệm ngay]** bên dưới để kích hoạt gói lãi suất ưu đãi {rate_config.SAVINGS_RATES[12]:.1f}%/năm chỉ từ 1 triệu đồng ạ!\n\n"
            "👉 Quý khách có thể bấm chọn nhanh các gợi ý bên dưới để xem tiếp câu trả lời chi tiết nhé ạ!"
        )
        return {
            "answer": answer,
            "quick_replies": ["Mở sổ tiết kiệm online", "Biểu lãi suất chi tiết", "Kế hoạch tài chính 10 năm"],
            "suggested_action": {"label": "Mở sổ tiết kiệm ngay", "route": "/bills/savings"},
            "sources": ["Cẩm nang Kinh tế & Quản trị tài chính Sen Hồng Bank", "Quy chế Tiết kiệm Online & Thông tư 04/2022/TT-NHNN"]
        }

    # =========================================================================
    # KỊCH BẢN 7: TƯ VẤN QUẢN TRỊ NỢ VAY AN TOÀN THEO CHỈ SỐ DTI & THU NHẬP
    # Ví dụ: "Lương 15 triệu thì vay bao nhiêu là an toàn để không bị vỡ nợ?"
    # =========================================================================
    has_income_mention = any(k in q_lower for k in ["lương", "luong", "thu nhập", "thu nhap", "mỗi tháng kiếm", "kiem duoc"])
    has_safe_debt_concern = any(k in q_lower for k in [
        "vay bao nhiêu là an toàn", "vay bao nhieu la an toan", "dti", "khả năng trả nợ",
        "vỡ nợ", "vo no", "trả nợ an toàn", "nguy hiểm không", "nguy hiem khong"
    ])
    if has_income_mention and has_safe_debt_concern:
        income_amt = extract_amount_from_text(query) or 15_000_000.0
        max_safe_monthly_payment = income_amt * 0.35
        answer = (
            f"Dạ theo tiêu chuẩn quản trị tài chính ngân hàng quốc tế, Sen Hồng Bank xin tư vấn hạn mức vay "
            f"và nguyên tắc trả nợ an toàn dựa trên mức thu nhập **{format_vnd(income_amt)}/tháng** của Quý khách như sau ạ:\n\n"
            "1. 📊 **Nguyên tắc Chỉ số Trả nợ trên Thu nhập (DTI - Debt-To-Income):**\n"
            "  - **Ngưỡng an toàn tối đa (Vùng Xanh):** Tổng số tiền trả góp hàng tháng (cả gốc và lãi) **không nên vượt quá 30% - 35% thu nhập thực nhận**.\n"
            f"  - 👉 Với thu nhập {format_vnd(income_amt)}/tháng: Số tiền trả góp tối đa an toàn là **{format_vnd(max_safe_monthly_payment)}/tháng**.\n"
            "  - Nếu vượt quá 45% - 50%, Quý khách sẽ rơi vào vùng căng thẳng ngân sách, dễ bị trễ hạn nếu phát sinh chi phí y tế hoặc đột xuất.\n\n"
            "2. 💡 **Gợi ý Gói Vay Tiêu Dùng Quick Loan Phù Hợp Tại Sen Hồng:**\n"
            "  - **Gói vay 30.000.000 VNĐ (Kỳ hạn 12 tháng):**\n"
            "    + Trả tháng đầu tiên (gốc + lãi): **2.860.000 VNĐ** (chỉ chiếm ~19% thu nhập).\n"
            "    + Các tháng sau giảm dần đều theo **dư nợ giảm dần 1.2%/tháng**.\n"
            "    + 👉 **Đánh giá:** Khoản vay nằm hoàn toàn trong **Vùng Siêu An Toàn**, bảo đảm không áp lực chi tiêu.\n"
            "  - **Gói vay 50.000.000 VNĐ (Kỳ hạn 12 tháng):** Trả tháng đầu **4.766.000 VNĐ** (~31% thu nhập), vẫn nằm trong ngưỡng an toàn tối đa.\n\n"
            "3. 🛡️ **Đặc quyền Vay Tiêu Dùng Sen Hồng Bank:**\n"
            "  - **0đ phí tất toán:** Quý khách có thể trả nợ trước hạn bất kỳ lúc nào mà không bị phạt.\n"
            "  - Duyệt và giải ngân tự động về ví trong 1 phút qua CCCD gắn chip.\n\n"
            "Quý khách có thể bấm **[Vay nhanh Quick Loan]** bên dưới để kiểm tra hạn mức được cấp sẵn của mình ạ!\n\n"
            "👉 Quý khách có thể bấm chọn nhanh các gợi ý bên dưới để xem tiếp câu trả lời chi tiết nhé ạ!"
        )
        return {
            "answer": answer,
            "quick_replies": ["Vay nhanh Quick Loan", "Bảng tính trả nợ chi tiết", "Biểu phí vay"],
            "suggested_action": {"label": "Vay nhanh Quick Loan", "route": "/bills/quick-loan"},
            "sources": ["Cẩm nang Quản trị Tài chính & Rủi ro Tín dụng Sen Hồng Bank", "Quy chế Vay tiêu dùng Quick Loan"]
        }

    # =========================================================================
    # KỊCH BẢN 8: MÔ HÌNH KIM TỰ THÁP TÀI CHÍNH & PHÂN BỔ DANH MỤC TÀI SẢN
    # Ví dụ: "Mô hình kim tự tháp tài chính cá nhân khuyên phân bổ tài sản cho tiết kiệm, vàng và đầu tư thế nào?"
    # =========================================================================
    has_pyramid_or_allocation = any(k in q_lower for k in [
        "kim tự tháp", "kim tu thap", "phân bổ tài sản", "phan bo tai san", "danh mục đầu tư", "phan bo danh muc"
    ])
    if has_pyramid_or_allocation:
        answer = (
            "Dạ theo mô hình **Kim Tự Tháp Tài Chính Cá Nhân** chuẩn quốc tế, các chuyên gia tài chính Sen Hồng Bank "
            "khuyên Quý khách nên phân bổ nguồn vốn theo 3 tầng tài sản vững chắc để phòng ngừa rủi ro chu kỳ kinh tế như sau ạ:\n\n"
            "1. 🏛️ **Tầng 1 - Nền tảng An toàn & Phòng thủ (Chiếm 50% - 60% tổng tài sản):**\n"
            "  - **Quỹ dự phòng khẩn cấp:** Chuẩn bị sẵn từ **3 đến 6 tháng chi phí cơ bản** (tiền ăn uống, nhà ở, học phí) để phòng ngừa biến cố bất ngờ.\n"
            f"  - **Tiền gửi Tiết kiệm Online Sen Hồng:** Kỳ hạn từ 6 đến 24 tháng với lãi suất hấp dẫn **{rate_config.SAVINGS_RATES[6]:.1f}% - {rate_config.SAVINGS_RATES[24]:.1f}%/năm**, tạo dòng tiền lãi thụ động cố định đều đặn và được bảo hiểm tiền gửi bảo toàn 100% vốn gốc.\n"
            "  - 👉 Tầng móng này giúp Quý khách luôn có bệ đỡ an toàn tài chính vững chãi trong mọi hoàn cảnh thị trường.\n\n"
            "2. 🎯 **Tầng 2 - Tích lũy Mục tiêu & Phòng hộ Lạm phát (Chiếm 20% - 30% tổng tài sản):**\n"
            "  - **Tiết kiệm Tích lũy Gửi góp:** Đều đặn trích từ lương hàng tháng cho các mục tiêu dài hạn (mua nhà, mua xe, học vấn tương lai).\n"
            "  - **Vàng nhẫn / Vàng miếng 9999:** Tài sản phòng hộ lạm phát và bất ổn địa chính trị toàn cầu.\n\n"
            "3. 🚀 **Tầng 3 - Tăng trưởng & Cơ hội (Chiếm 10% - 15% tổng tài sản):**\n"
            "  - Cổ phiếu, chứng chỉ quỹ mở, bất động sản đầu tư.\n"
            "  - **Nguyên tắc sống còn:** Chỉ dùng nguồn vốn nhàn rỗi dài hạn từ 3 - 5 năm trở lên, tuyệt đối không dùng tiền vay mượn ngắn hạn để đầu cơ.\n\n"
            "Quý khách có thể bắt đầu xây dựng tầng móng tài chính an toàn ngay hôm nay với các gói tiết kiệm sinh lời tại Sen Hồng Bank ạ!\n\n"
            "👉 Quý khách có thể bấm chọn nhanh các gợi ý bên dưới để xem tiếp câu trả lời chi tiết nhé ạ!"
        )
        return {
            "answer": answer,
            "quick_replies": ["Mở sổ tiết kiệm ngay", "Kế hoạch tài chính 10 năm", "Biểu lãi suất"],
            "suggested_action": {"label": "Mở sổ tiết kiệm", "route": "/bills/savings"},
            "sources": ["Cẩm nang Kinh tế & Quản trị tài chính Sen Hồng Bank", "Mô hình Kim tự tháp tài chính cá nhân"]
        }

    # =========================================================================
    # KỊCH BẢN 9: BỘ CÔNG AN, ĐỀ ÁN 06 & ĐỊNH DANH VNEID MỨC 2
    # Ví dụ: "Bộ Công An và Đề án 06 quy định xác thực tài khoản ngân hàng với VNeID và dữ liệu dân cư như thế nào?"
    # =========================================================================
    has_bca_mention = any(k in q_lower for k in [
        "bộ công an", "bo cong an", "bca", "c06", "đề án 06", "de an 06", "dân cư quốc gia", "dan cu quoc gia"
    ])
    has_vneid_or_idlaw = any(k in q_lower for k in [
        "vneid", "định danh điện tử", "dinh danh dien tu", "luật căn cước", "luat can cuoc", "căn cước 2023"
    ])
    if has_bca_mention or (has_vneid_or_idlaw and any(k in q_lower for k in ["ngân hàng", "xác thực", "tài khoản", "liên kết"])):
        answer = (
            "Dạ thực hiện **Đề án 06 của Chính phủ** và chỉ đạo của **Bộ Công An (C06)** phối hợp cùng Ngân hàng Nhà nước, "
            "Sen Hồng Bank xin thông tin chi tiết về việc kết nối dữ liệu dân cư và định danh VNeID như sau ạ:\n\n"
            "1. 🏛️ **Mục tiêu của Đề án 06 đối với Tài khoản Ngân hàng:**\n"
            "  - **Làm sạch 100% dữ liệu tài khoản:** Đối soát trực tiếp thông tin chủ tài khoản với **Cơ sở Dữ liệu Quốc gia về Dân cư** do Trung tâm Dữ liệu Quốc gia về Dân cư (C06 - Bộ Công An) quản lý.\n"
            "  - Xóa bỏ triệt để tài khoản rác, tài khoản mở bằng giấy tờ giả mạo, bảo đảm nguyên tắc **Một danh tính số chính chủ duy nhất**.\n"
            "  - Chặn đứng các hành vi gian lận, rửa tiền và lừa đảo chiếm đoạt tài sản qua mạng viễn thông.\n\n"
            "2. 🆔 **Tích hợp Định danh Điện tử VNeID Mức 2:**\n"
            "  - Khách hàng đã có tài khoản định danh điện tử **VNeID Mức 2** (đã xác thực vân tay, mống mắt tại Công an phường/xã) có thể sử dụng VNeID để mở tài khoản Sen Hồng online siêu tốc mà không cần chụp lại giấy tờ.\n"
            "  - Được cấp ngay hạn mức giao dịch trực tuyến cao nhất lên tới **500.000.000 VNĐ/ngày**.\n\n"
            "3. 🪪 **Tuân thủ Luật Căn Cước Số 26/2023/QH15:**\n"
            "  - Sen Hồng Bank hỗ trợ đầy đủ cả Thẻ CCCD gắn chip (12 số) và **Thẻ Căn cước mẫu mới** (có hiệu lực từ 01/07/2024).\n"
            "  - Các thẻ CCCD gắn chip cũ còn hạn sử dụng vẫn giữ nguyên giá trị pháp lý, không bắt buộc phải đổi sang Thẻ Căn cước mới.\n\n"
            "Quý khách có thể bấm nút **[Xác thực Căn cước / VNeID]** bên dưới để đồng bộ dữ liệu dân cư chính chủ chỉ trong 1 phút ạ!\n\n"
            "👉 Quý khách có thể bấm chọn nhanh các gợi ý bên dưới để xem tiếp câu trả lời chi tiết nhé ạ!"
        )
        return {
            "answer": answer,
            "quick_replies": ["Xác thực CCCD / NFC", "Định danh VNeID", "Hạn mức tài khoản"],
            "suggested_action": {"label": "Xác thực Căn cước / VNeID", "route": "/profile/nfc-reader"},
            "sources": ["Đề án 06/CP của Chính phủ & C06 Bộ Công An", "Luật Căn cước số 26/2023/QH15", "Quy chế định danh VNeID"]
        }

    # =========================================================================
    # KỊCH BẢN 10: ĐIỀU KHOẢN DỊCH VỤ APP & BẢO VỆ DỮ LIỆU CÁ NHÂN (NĐ 13/2023/NĐ-CP)
    # Ví dụ: "Điều khoản sử dụng app Sen Hồng và chính sách bảo vệ dữ liệu theo Nghị định 13 quy định những gì?"
    # =========================================================================
    has_terms_keyword = any(k in q_lower for k in [
        "điều khoản", "dieu khoan", "thỏa thuận", "thoa thuan", "chính sách sử dụng", "chinh sach su dung",
        "nghị định 13", "nghi dinh 13", "nd 13", "bảo vệ dữ liệu", "bao ve du lieu", "xóa dữ liệu", "xoa du lieu"
    ])
    if has_terms_keyword:
        answer = (
            "Dạ theo bản **Thỏa thuận Điều khoản & Điều kiện Sử dụng Dịch vụ Ngân hàng Số Sen Hồng** "
            "(Phiên bản 2.4) và **Nghị định 13/2023/NĐ-CP** của Chính phủ về bảo vệ dữ liệu cá nhân:\n\n"
            "1. 📋 **Điều kiện Khách hàng & Mở Tài khoản:**\n"
            "  - Áp dụng cho cá nhân từ **đủ 15 tuổi trở lên**, có đầy đủ năng lực hành vi dân sự và sở hữu Căn cước/CCCD gắn chip chính chủ.\n"
            "  - Bằng việc đăng ký tài khoản, khách hàng cam kết sử dụng dịch vụ đúng mục đích hợp pháp, không chuyển giao tài khoản cho người khác.\n\n"
            "2. 🛡️ **Bảo vệ Dữ liệu Cá nhân theo Nghị định 13/2023/NĐ-CP:**\n"
            "  - **Mục đích thu thập:** Chỉ sử dụng dữ liệu để định danh eKYC, xác thực sinh trắc học theo QĐ 2345/QĐ-NHNN, phòng chống rửa tiền và bảo vệ tài khoản khách hàng.\n"
            "  - **Cam kết không mua bán:** Sen Hồng Bank **cam kết tuyệt đối không mua bán, trao đổi hoặc cung cấp dữ liệu cá nhân cho bên thứ ba** vì mục đích thương mại/quảng cáo.\n"
            "  - **Quyền của khách hàng:** Có quyền xem, chỉnh sửa dữ liệu tại mục Hồ sơ cá nhân; hoặc gửi yêu cầu rút lại sự đồng ý / xóa dữ liệu qua email pháp chế: `legal@senhongbank.vn`.\n\n"
            "3. ⚖️ **Điều khoản Miễn trừ Trách nhiệm & Xử lý Khiếu nại:**\n"
            "  - Ngân hàng được miễn trừ trách nhiệm nếu khách hàng tự ý tiết lộ mã OTP/PIN, hoặc tự ý cài đặt phần mềm gián điệp (file APK lạ ngoài chợ ứng dụng).\n"
            "  - **Thời hạn giải quyết khiếu nại (SLA):** Trong 24h đối với giao dịch nội bộ, từ 3 - 5 ngày đối với Napas 24/7. Tranh chấp không thể hòa giải sẽ giải quyết tại Trọng tài Quốc tế Việt Nam (VIAC).\n\n"
            "Quý khách có thể bấm **[Xem toàn bộ Điều khoản]** bên dưới để đọc văn bản pháp lý đầy đủ ạ!\n\n"
            "👉 Quý khách có thể bấm chọn nhanh các gợi ý bên dưới để xem tiếp câu trả lời chi tiết nhé ạ!"
        )
        return {
            "answer": answer,
            "quick_replies": ["Xem toàn bộ điều khoản", "Bảo vệ dữ liệu NĐ 13", "Quy trình tra soát"],
            "suggested_action": {"label": "Xem toàn bộ Điều khoản", "route": "/auth/terms"},
            "sources": ["Bản Thỏa thuận Điều khoản Dịch vụ Sen Hồng Bank (v2.4)", "Nghị định 13/2023/NĐ-CP của Chính phủ"]
        }

    # =========================================================================
    # KỊCH BẢN 11: CHẾ TÀI MUA BÁN TÀI KHOẢN (ĐIỀU 291 BLHS) & CẢNH BÁO MẠO DANH BỘ CÔNG AN
    # Ví dụ: "Cho người khác mượn hoặc bán tài khoản ngân hàng có bị đi tù không? Công an có bao giờ gọi điện yêu cầu chuyển tiền không?"
    # =========================================================================
    has_selling_account = any(k in q_lower for k in [
        "bán tài khoản", "ban tai khoan", "cho thuê tài khoản", "cho thue tai khoan",
        "cho mượn tài khoản", "cho muon tai khoan", "đi tù", "di tu", "điều 291", "dieu 291"
    ])
    has_impersonation_scam = any(k in q_lower for k in [
        "mạo danh công an", "mao danh cong an", "công an gọi điện", "cong an goi dien",
        "tài khoản an toàn", "tai khoan an toan", "đe dọa lệnh bắt", "de doa lenh bat"
    ])

    if has_selling_account or has_impersonation_scam:
        answer = (
            "Dạ Bộ Công An và Ngân hàng Số Sen Hồng đưa ra **Cảnh báo khẩn cấp và Chế tài pháp luật nghiêm khắc** như sau ạ:\n\n"
            "1. ⚖️ **Chế Tài Hình Sự Về Tội Mua Bán, Cho Thuê Tài Khoản (Điều 291 BLHS):**\n"
            "  - **Xử phạt hành chính:** Phạt tiền từ **40.000.000 VNĐ đến 100.000.000 VNĐ** (Nghị định 88/2019/NĐ-CP).\n"
            "  - **Truy cứu trách nhiệm hình sự:** Hành vi thu thập, tàng trữ, mua bán, cho thuê tài khoản ngân hàng có thể bị **phạt tù từ 03 tháng đến 07 năm tù giam** theo Điều 291 Bộ luật Hình sự.\n"
            "  - **Hậu quả lâu dài:** Toàn bộ tài khoản vi phạm bị phong tỏa vĩnh viễn và bị đưa vào **Danh sách đen (Blacklist) liên ngân hàng của NHNN và Bộ Công An**, cấm mở tài khoản tại toàn bộ hệ thống ngân hàng Việt Nam.\n\n"
            "2. 🚨 **Cảnh Báo Thủ Đoạn Mạo Danh Cán Bộ Công An Lừa Đảo:**\n"
            "  - **Không bao giờ làm việc qua điện thoại:** Cơ quan Công an (C06, A05, Công an các tỉnh/thành phố), Viện Kiểm sát, Tòa án **tuyệt đối không làm việc, không lấy lời khai, không tống đạt lệnh bắt qua điện thoại hoặc mạng xã hội** (Zalo, Telegram).\n"
            "  - **Không có 'Tài khoản an toàn':** Cơ quan Công an không bao giờ yêu cầu người dân chuyển tiền vào bất kỳ tài khoản cá nhân nào để 'chứng minh vô tội'. Đây là **100% lừa đảo chiếm đoạt tài sản**.\n"
            "  - **Bảo mật tuyệt đối:** Không cung cấp mã OTP, mã PIN, không bấm link lạ tải file APK giả mạo cổng dịch vụ công.\n\n"
            "Nếu gặp cuộc gọi đe dọa, Quý khách hãy cúp máy ngay lập tức và báo cho cơ quan Công an gần nhất hoặc gọi hotline Sen Hồng **1900-SENHONG** để được hỗ trợ khóa tài khoản khẩn cấp ạ!\n\n"
            "👉 Quý khách có thể bấm chọn nhanh các gợi ý bên dưới để xem tiếp câu trả lời chi tiết nhé ạ!"
        )
        return {
            "answer": answer,
            "quick_replies": ["Cài đặt bảo mật", "Khóa thẻ khẩn cấp", "Quy định QĐ 2345"],
            "suggested_action": {"label": "Cài đặt bảo mật", "route": "/settings/security"},
            "sources": ["Điều 291 Bộ luật Hình sự Việt Nam", "Khuyến cáo an ninh C06 & A05 Bộ Công An", "Cẩm nang An toàn Bảo mật Sen Hồng"]
        }

    # =========================================================================
    # KỊCH BẢN 15: SỔ TIẾT KIỆM SẮP ĐÁO HẠN KẸT TIỀN: VAY THẤU CHI / CẦM CỐ VS TẤT TOÁN SỚM
    # Ví dụ: "Tôi đang có sổ tiết kiệm 12 tháng còn 2 tháng nữa đáo hạn, giờ kẹt tiền thì nên vay thấu chi hay tất toán sổ tiết kiệm?"
    # =========================================================================
    has_savings_term = any(k in q_lower for k in ["sổ tiết kiệm", "so tiet kiem", "tiết kiệm 12 tháng", "đáo hạn", "dao han"])
    has_emergency_need = any(k in q_lower for k in [
        "thấu chi", "thau chi", "tất toán", "tat toan", "kẹt tiền", "ket tien", "cần tiền gấp", "can tien gap",
        "nên vay hay", "nen vay hay", "rút trước hạn", "rut truoc han", "vay cầm cố", "vay cam co"
    ])

    if has_savings_term and has_emergency_need:
        answer = (
            "Dạ đây là bài toán tài chính rất phổ biến và Sen Hồng Bank xin tư vấn giải pháp tối ưu lợi ích cho Quý khách như sau ạ:\n\n"
            "1. ❌ **Không nên tất toán toàn bộ sổ tiết kiệm:**\n"
            "  - Nếu tất toán sớm, Quý khách sẽ bị hạ toàn bộ lãi suất 10 tháng vừa qua về **lãi suất không kỳ hạn (chỉ 0.2%/năm)**, mất gần như toàn bộ số tiền lãi đã tích lũy.\n\n"
            "2. 💡 **Giải pháp 1 - Rút một phần gốc theo Thông tư 04/2022/TT-NHNN:**\n"
            f"  - Nếu Quý khách chỉ cần một khoản tiền nhỏ: Quý khách có quyền **rút một phần gốc**. Phần rút ra chịu lãi 0.2%/năm, nhưng **toàn bộ phần tiền gốc còn lại vẫn được giữ nguyên lãi suất {rate_config.SAVINGS_RATES[12]:.1f}%/năm** đến ngày đáo hạn!\n\n"
            "3. ⚡ **Giải pháp 2 - Vay Thấu Chi / Cầm Cố Sổ Tiết Kiệm (Tối ưu nhất nếu cần nhiều tiền):**\n"
            "  - Sen Hồng hỗ trợ vay cầm cố online đến **90% giá trị sổ**, duyệt và giải ngân vào ví trong **1 phút**.\n"
            "  - Quý khách chỉ phải trả lãi vay cho **2 tháng ngắn ngủi còn lại**. Khi sổ tiết kiệm đáo hạn sau 2 tháng, tiền lãi 12 tháng nhận được sẽ dư sức bù đắp tiền lãi vay và Quý khách vẫn có lợi nhuận ròng cao hơn hẳn việc tất toán sớm!\n\n"
            "Quý khách có thể bấm **[Vay cầm cố sổ tiết kiệm]** bên dưới để nhận tiền ngay mà không mất khoản tiền lãi 10 tháng qua ạ!\n\n"
            "👉 Quý khách có thể bấm chọn nhanh các gợi ý bên dưới để xem tiếp câu trả lời chi tiết nhé ạ!"
        )
        return {
            "answer": answer,
            "quick_replies": ["Vay nhanh Quick Loan", "Rút một phần theo TT 04", "Bảng tính lãi tiết kiệm"],
            "suggested_action": {"label": "Vay nhanh Quick Loan", "route": "/bills/quick-loan"},
            "sources": ["Thông tư 04/2022/TT-NHNN về tiền gửi rút trước hạn", "Quy chế cho vay cầm cố sổ tiết kiệm Sen Hồng Bank"]
        }

    # =========================================================================
    # KỊCH BẢN 16: THẨM ĐỊNH TÍN DỤNG CIC & 5 NHÓM NỢ THEO THÔNG TƯ 11/2021/TT-NHNN
    # Ví dụ: "Nợ xấu nhóm 3 nhóm 4 trên CIC bao lâu thì được xóa và ngân hàng phân loại 5 nhóm nợ thế nào?"
    # =========================================================================
    has_cic_term = any(k in q_lower for k in ["cic", "nhóm nợ", "nhom no", "nợ xấu", "no xau", "xóa nợ xấu", "xoa no xau"])
    if has_cic_term and any(k in q_lower for k in ["nhóm 3", "nhóm 4", "nhóm 5", "5 nhóm", "bao lâu", "bao lau", "thế nào", "the nao", "thông tư 11", "thong tu 11"]):
        answer = (
            "Dạ theo quy định của Ngân hàng Nhà nước tại **Thông tư 11/2021/TT-NHNN** và Trung tâm Thông tin Tín dụng Quốc gia (CIC), "
            "Sen Hồng Bank xin giải đáp chi tiết về 5 nhóm nợ và thời hạn xóa nợ xấu như sau ạ:\n\n"
            "1. 📊 **Hệ Thống Phân Loại 5 Nhóm Nợ CIC:**\n"
            "  - **Nhóm 1 (Nợ đủ tiêu chuẩn):** Quá hạn dưới 10 ngày. Khách hàng được xét duyệt vay vốn siêu tốc.\n"
            "  - **Nhóm 2 (Nợ cần chú ý):** Quá hạn từ 10 - 90 ngày. Sẽ tự động xóa sạch khỏi CIC sau **12 tháng** kể từ khi tất toán hết nợ.\n"
            "  - **Nhóm 3 (Nợ dưới tiêu chuẩn):** Quá hạn từ 91 - 180 ngày (Bắt đầu tính là nợ xấu).\n"
            "  - **Nhóm 4 (Nợ nghi ngờ):** Quá hạn từ 181 - 360 ngày (Nợ xấu có nguy cơ mất vốn).\n"
            "  - **Nhóm 5 (Nợ có khả năng mất vốn):** Quá hạn trên 360 ngày (Nợ xấu nặng nhất).\n\n"
            "2. ⏳ **Quy Định Xóa Lịch Sử Nợ Xấu (Nhóm 3, Nhóm 4, Nhóm 5):**\n"
            "  - Sau khi khách hàng đã **thanh toán toàn bộ gốc, lãi và phí phạt**, dữ liệu nợ xấu sẽ được lưu trữ trên hệ thống CIC trong vòng đúng **05 năm (60 tháng)**.\n"
            "  - Sau 5 năm, hệ thống CIC sẽ tự động xóa sạch lịch sử nợ xấu, khách hàng được khôi phục quyền tiếp cận tín dụng bình thường.\n"
            "  - ⚠️ **Cảnh báo:** Tuyệt đối không có cá nhân hay dịch vụ nào có thể 'xóa nợ xấu CIC' trước hạn. Mọi quảng cáo nhận tiền xóa nợ xấu đều là lừa đảo.\n\n"
            "👉 Quý khách có thể bấm chọn nhanh các gợi ý bên dưới để xem tiếp câu trả lời chi tiết nhé ạ!"
        )
        return {
            "answer": answer,
            "quick_replies": ["Vay thế chấp BĐS", "Tra cứu CIC cá nhân", "Điều kiện vay tiêu dùng"],
            "suggested_action": {"label": "Kiểm tra hạn mức vay", "route": "/bills/quick-loan"},
            "sources": ["Thông tư 11/2021/TT-NHNN của Ngân hàng Nhà nước", "Quy chế phân loại nợ Trung tâm Thông tin Tín dụng Quốc gia CIC"]
        }

    # =========================================================================
    # KỊCH BẢN 17: CHUYỂN TIỀN QUỐC TẾ SWIFT & HỒ SƠ DU HỌC / NGOẠI HỐI
    # Ví dụ: "Mã SWIFT code của ngân hàng Sen Hồng là gì và hồ sơ chuyển tiền du học cần những gì?"
    # =========================================================================
    has_swift_term = any(k in q_lower for k in ["swift", "bic code", "chuyển tiền quốc tế", "chuyen tien quoc te", "du học", "du hoc", "ngoại tệ", "ngoai te"])
    if has_swift_term and any(k in q_lower for k in ["mã", "ma", "code", "hồ sơ", "ho so", "giấy tờ", "giay to", "cần những gì", "can nhung gi"]):
        answer = (
            "Dạ Sen Hồng Bank là thành viên chính thức của mạng lưới chuyển tiền toàn cầu SWIFT. Thông tin chuyển tiền quốc tế như sau ạ:\n\n"
            "1. 🌐 **Mã SWIFT Code / BIC Của Sen Hồng Bank:**\n"
            "  - Mã chuẩn quốc tế: **`SENHVNVX`** (Áp dụng cho mọi giao dịch chuyển/nhận ngoại tệ toàn cầu).\n\n"
            "2. 🎓 **Hồ Sơ Chuyển Tiền Du Học Hợp Pháp (Theo Pháp Lệnh Ngoại Hối):**\n"
            "  - **Hộ chiếu** còn hạn và **Visa du học** (hoặc Giấy phép cư trú hợp lệ).\n"
            "  - **Thông báo tiếp nhận** của trường nước ngoài (I-20 / CoE / Letter of Acceptance).\n"
            "  - **Thông báo nộp học phí** và sinh hoạt phí (Invoice / Bill).\n"
            "  - **Giấy tờ chứng minh quan hệ nhân thân** nếu thân nhân chuyển thay (Giấy khai sinh / Đăng ký kết hôn).\n\n"
            "3. ⚡ **Thời Gian & Chi Phí Chuyển Tiền:**\n"
            "  - Chuyển qua mạng **SWIFT GPI**, tiền vào tài khoản người nhận trong **2 - 24 giờ làm việc**.\n"
            "  - Hỗ trợ theo dõi hành trình dòng tiền trực tuyến 24/7 trên App Sen Hồng.\n\n"
            "👉 Quý khách có thể bấm chọn nhanh các gợi ý bên dưới để xem tiếp câu trả lời chi tiết nhé ạ!"
        )
        return {
            "answer": answer,
            "quick_replies": ["Mã SWIFT SENHVNVX", "Chuyển tiền du học", "Nhận kiều hối 0đ"],
            "suggested_action": {"label": "Chuyển tiền quốc tế", "route": "/international-transfer"},
            "sources": ["Pháp lệnh Ngoại hối số 28/2005/PL-UBTVQH11", "Quy chế mạng chuyển tiền quốc tế SWIFT GPI Sen Hồng Bank"]
        }

    # =========================================================================
    # KỊCH BẢN 18: THẺ TÍN DỤNG HOÀN TIỀN CASHBACK, MIỄN LÃI 55 NGÀY & TRẢ GÓP 0%
    # Ví dụ: "Thẻ tín dụng hoàn tiền Cashback được miễn lãi bao nhiêu ngày và làm sao để chuyển đổi trả góp 0%?"
    # =========================================================================
    has_card_adv_term = any(k in q_lower for k in ["cashback", "hoàn tiền", "hoan tien", "trả góp 0%", "tra gop 0", "miễn lãi", "mien lai"])
    if has_card_adv_term and any(k in q_lower for k in ["thẻ", "the", "bao nhiêu ngày", "bao nhieu ngay", "làm sao", "chuyển đổi"]):
        answer = (
            "Dạ dòng thẻ tín dụng **Sen Hồng Cashback Visa Platinum** mang lại đặc quyền chi tiêu vượt trội cho Quý khách:\n\n"
            "1. 🎁 **Chính Sách Hoàn Tiền (Cashback):**\n"
            "  - **Hoàn tiền 10%:** Cho chi tiêu ẩm thực, nhà hàng cuối tuần.\n"
            "  - **Hoàn tiền 5%:** Cho mua sắm siêu thị và thanh toán hóa đơn điện nước trên App.\n"
            "  - **Hoàn tiền 1%:** Cho toàn bộ các chi tiêu mua sắm online và quốc tế khác.\n\n"
            "2. 🗓️ **Thời Hạn Miễn Lãi Tối Đa Lên Đến 55 Ngày:**\n"
            "  - Ngày chốt sao kê: **Ngày 20 hàng tháng**.\n"
            "  - Ngày đến hạn thanh toán: **Ngày 15 tháng kế tiếp** (25 ngày sau sao kê).\n"
            "  - Thanh toán tối thiểu chỉ **5% tổng dư nợ** để không bị ghi nhận nợ chú ý.\n\n"
            "3. 💳 **Chuyển Đổi Trả Góp 0% Lãi Suất Trong 30 Giây:**\n"
            "  - Áp dụng cho mọi giao dịch chi tiêu từ **3.000.000 VNĐ trở lên**.\n"
            "  - Kỳ hạn linh hoạt: 3, 6, 9 hoặc 12 tháng với **0% lãi suất**.\n"
            "  - Thao tác: Vào **Quản lý Thẻ** $\rightarrow$ Chọn giao dịch $\rightarrow$ Bấm nút **[Chuyển đổi trả góp 0%]**.\n\n"
            "👉 Quý khách có thể bấm chọn nhanh các gợi ý bên dưới để xem tiếp câu trả lời chi tiết nhé ạ!"
        )
        return {
            "answer": answer,
            "quick_replies": ["Thẻ hoàn tiền Cashback", "Trả góp 0% lãi suất", "Biểu phí & Hạn mức"],
            "suggested_action": {"label": "Quản lý thẻ", "route": "/cards"},
            "sources": ["Quy chế phát hành Thẻ tín dụng Sen Hồng Cashback Visa Platinum", "Chính sách trả góp 0% lãi suất Core Banking"]
        }

    # =========================================================================
    # KỊCH BẢN 19: NỘP THUẾ ĐIỆN TỬ ETAX MOBILE & NỘP PHẠT NGUỘI GIAO THÔNG C08
    # Ví dụ: "Làm thế nào để nộp thuế qua app eTax Mobile và nộp phạt nguội giao thông bằng tài khoản Sen Hồng?"
    # =========================================================================
    has_tax_term = any(k in q_lower for k in ["etax", "thuế", "thue", "phạt nguội", "phat nguoi", "dịch vụ công", "dich vu cong"])
    if has_tax_term and any(k in q_lower for k in ["nộp", "nop", "làm thế nào", "lam the nao", "bằng tài khoản", "giao thông"]):
        answer = (
            "Dạ Sen Hồng Bank kết nối trực tiếp với Tổng cục Thuế và Cổng Dịch vụ công Quốc gia, hỗ trợ thanh toán 24/7 tức thì:\n\n"
            "1. 🏛️ **Nộp Thuế Điện Tử Qua eTax Mobile (Tổng cục Thuế):**\n"
            "  - **Bước 1:** Đăng nhập app **eTax Mobile** $\rightarrow$ Chọn mục **Nộp thuế** và tra cứu theo Mã số thuế cá nhân.\n"
            "  - **Bước 2:** Chọn ngân hàng thanh toán: **Ngân hàng Số Sen Hồng**.\n"
            "  - **Bước 3:** Hệ thống liên kết an toàn sang App Sen Hồng, xác nhận số tiền thuế và ký số bằng **Smart OTP**.\n"
            "  - **Gạch nợ tức thì:** Tiền thuế được hạch toán sang Kho bạc Nhà nước trong **5 giây**, cấp biên lai điện tử ngay.\n\n"
            "2. 🚗 **Nộp Phạt Nguội Giao Thông (C08 - Bộ Công An):**\n"
            "  - Truy cập Cổng Dịch vụ công Quốc gia (`dichvucong.gov.vn`) $\rightarrow$ Tra cứu theo Số biên bản vi phạm hoặc Biển số xe.\n"
            "  - Chọn thanh toán qua Sen Hồng Bank $\rightarrow$ Quét mã VietQR để hoàn tất.\n"
            "  - Trạng thái nộp phạt được đồng bộ tức thì sang hệ thống Cảnh sát Giao thông để hoàn trả giấy tờ.\n\n"
            "👉 Quý khách có thể bấm chọn nhanh các gợi ý bên dưới để xem tiếp câu trả lời chi tiết nhé ạ!"
        )
        return {
            "answer": answer,
            "quick_replies": ["Nộp thuế eTax Mobile", "Nộp phạt nguội C08", "Hóa đơn điện nước"],
            "suggested_action": {"label": "Nộp thuế & Dịch vụ công", "route": "/bills"},
            "sources": ["Quy chế phối hợp thu ngân sách Tổng cục Thuế & Kho bạc Nhà nước", "Cổng Dịch vụ công Quốc gia dichvucong.gov.vn"]
        }

    # =========================================================================
    # KỊCH BẢN 20: CÂY NẠP/RÚT TIỀN TỰ ĐỘNG CRM 24/7 & KIOSK SMART LOUNGE
    # Ví dụ: "Cây CRM của ngân hàng có nạp được tiền mặt không cần thẻ không và hạn mức nạp một lần là bao nhiêu?"
    # =========================================================================
    has_crm_term = any(k in q_lower for k in ["crm", "cây nạp", "cay nap", "nạp tiền mặt", "nap tien mat", "smart lounge", "in thẻ", "in the"])
    if has_crm_term and any(k in q_lower for k in ["hạn mức", "han muc", "không cần thẻ", "khong can the", "bao nhiêu", "bao nhieu", "thế nào", "the nao"]):
        answer = (
            "Dạ hệ thống **Cây nạp/rút tiền thông minh CRM 24/7** và Kiosk Smart Lounge của Sen Hồng Bank phục vụ khách hàng xuyên suốt ngày đêm:\n\n"
            "1. 💵 **Nạp Tiền Mặt Không Cần Thẻ Vật Lý Tại Cây CRM:**\n"
            "  - Hỗ trợ nạp tiền mặt trực tiếp **không cần thẻ**: Chỉ cần bấm **[Nạp tiền VietQR]** trên màn hình CRM rồi dùng App quét mã, hoặc chọn **Xác thực khuôn mặt eKYC**.\n"
            "  - **Hạn mức nạp:** Lên tới **100.000.000 VNĐ/lần giao dịch** (tối đa 200 tờ tiền polymer), không giới hạn số lần nạp trong ngày.\n"
            "  - **Tốc độ:** Tiền nổi ngay trên số dư ví/tài khoản chỉ sau **10 giây**, phí **miễn phí 100% (0đ)**.\n\n"
            "2. 🖨️ **Kiosk Tự Động In Thẻ Vật Lý Lấy Ngay Trong 2 Phút:**\n"
            "  - Đặt CCCD gắn chip vào khay $\rightarrow$ Quét khuôn mặt xác thực $\rightarrow$ Máy tự in và dập nổi thẻ Visa lấy ngay tại chỗ trong **120 giây** mà không cần gặp giao dịch viên.\n\n"
            "👉 Quý khách có thể bấm chọn nhanh các gợi ý bên dưới để xem tiếp câu trả lời chi tiết nhé ạ!"
        )
        return {
            "answer": answer,
            "quick_replies": ["Cây nạp tiền CRM 24/7", "Kiosk in thẻ Smart Lounge", "Mạng lưới ATM"],
            "suggested_action": {"label": "Điểm giao dịch CRM", "route": "/deposit"},
            "sources": ["Quy chế vận hành máy nạp rút tiền tự động CRM Core Banking", "Tiêu chuẩn Kiosk giao dịch tự động Smart Lounge Sen Hồng"]
        }

    # =========================================================================
    # KỊCH BẢN 21: KHÁCH HÀNG ƯU TIÊN SEN HONG PRIORITY BANKING & PHÒNG CHỜ LOUNGEKEY
    # Ví dụ: "Điều kiện để trở thành khách hàng ưu tiên Priority là gì và có được dùng phòng chờ sân bay không?"
    # =========================================================================
    has_prio_term = any(k in q_lower for k in ["priority", "khách hàng ưu tiên", "khach hang uu tien", "private wealth", "diamond", "loungekey"])
    if has_prio_term and any(k in q_lower for k in ["điều kiện", "dieu kien", "tiêu chuẩn", "tieu chuan", "phòng chờ", "phong cho", "sân bay", "san bay", "là gì", "la gi"]):
        answer = (
            "Dạ chương trình **Sen Hong Priority Banking** mang lại hệ sinh thái đặc quyền đẳng cấp cho Quý khách:\n\n"
            "1. 💎 **Tiêu Chuẩn Định Danh Khách Hàng Ưu Tiên:**\n"
            "  - **Hạng Bạch Kim (Priority Platinum):** Số dư bình quân tiền gửi từ **1.000.000.000 VNĐ (1 tỷ đồng)** trong 3 tháng, HOẶC tổng tài sản quản lý (AUM) từ **2 tỷ đồng**.\n"
            "  - **Hạng Kim Cương (Private Diamond):** Tổng tài sản quản lý từ **5 tỷ đồng** trở lên.\n\n"
            "2. ✈️ **Đặc Quyền Phòng Chờ Thương Gia Toàn Cầu (LoungeKey):**\n"
            "  - Miễn phí sử dụng không giới hạn **hơn 1.000 phòng chờ thương gia** tại các sân bay trong nước (Nội Bài, Tân Sơn Nhất, Đà Nẵng...) và quốc tế.\n"
            "  - Tặng thêm suất phòng chờ cho người thân đi kèm tùy theo hạng thẻ hội viên.\n\n"
            "3. 👑 **Đặc Quyền Tài Chính & Chăm Sóc Riêng Biệt:**\n"
            "  - Phục vụ bởi **Giám đốc Quản lý Tài sản (Private Banker)** 1-kèm-1, khu vực đón tiếp Priority Lounge riêng không phải xếp hàng.\n"
            "  - **Cộng thêm +0.3% đến +0.5%/năm** lãi suất tiết kiệm, giảm 0.5% - 1.0%/năm lãi suất vay.\n"
            "  - Miễn phí 100% mọi dịch vụ chuyển tiền quốc tế và phí thường niên thẻ VIP.\n\n"
            "👉 Quý khách có thể bấm chọn nhanh các gợi ý bên dưới để xem tiếp câu trả lời chi tiết nhé ạ!"
        )
        return {
            "answer": answer,
            "quick_replies": ["Hội viên Sen Hong Priority", "Phòng chờ LoungeKey", "Private Banker"],
            "suggested_action": {"label": "Khách hàng ưu tiên", "route": "/profile"},
            "sources": ["Chính sách Khách hàng Ưu tiên Sen Hong Priority Banking", "Đặc quyền phòng chờ sân bay quốc tế LoungeKey"]
        }

    # =========================================================================
    # KỊCH BẢN 22: QUY TRÌNH 4 BƯỚC HÀNH ĐỘNG KHẨN CẤP KHI NGHI NGỜ BỊ LỪA ĐẢO / LỘ THÔNG TIN
    # Ví dụ: "Nếu nghi ngờ bị lừa đảo hoặc lỡ bấm link lạ thì 4 bước xử lý khẩn cấp cần làm ngay là gì?"
    # =========================================================================
    has_emergency_guide = any(k in q_lower for k in ["lừa đảo", "lua dao", "lộ thông tin", "lo thong tin", "bấm link lạ", "bam link la", "bị hack", "bi hack"])
    if has_emergency_guide and any(k in q_lower for k in ["4 bước", "cac buoc", "các bước", "cần làm gì", "can lam gi", "xử lý khẩn cấp", "xu ly khan cap", "là gì", "la gi"]):
        answer = (
            "Dạ nếu nghi ngờ tài khoản bị lộ thông tin hoặc lỡ bấm link lạ, Quý khách hãy bình tĩnh thực hiện ngay **4 bước hành động khẩn cấp** sau ạ:\n\n"
            "1. 🛑 **Bước 1 - Khóa Tài Khoản & Khóa Toàn Bộ Thẻ Ngay Lập Tức:**\n"
            "  - Mở App Sen Hồng $\rightarrow$ Vào **Cài đặt An toàn Bảo mật** $\rightarrow$ Gạt công tắc **[Khóa tài khoản khẩn cấp]** để đóng băng mọi giao dịch rút/chuyển tiền trong 3 giây.\n"
            "  - HOẶC gọi ngay Hotline 24/7 **1900-SENHONG (1900 736 466)** bấm phím 1 để hệ thống tự động khóa băng tức thì.\n\n"
            "2. 🔌 **Bước 2 - Ngắt Kết Nối Mạng & Tắt Nguồn Thiết Bị (Nếu Lỡ Cài File APK Lạ):**\n"
            "  - Tắt ngay Wi-Fi/4G hoặc tắt nguồn điện thoại để ngăn chặn mã độc gián điệp chiếm quyền điều khiển Accessibility từ xa.\n"
            "  - Khôi phục cài đặt gốc (Factory Reset) thiết bị để xóa sạch mã độc.\n\n"
            "3. 🔑 **Bước 3 - Đổi Toàn Bộ Mật Khẩu Trên Một Thiết Bị Sạch Khác:**\n"
            "  - Dùng máy tính hoặc thiết bị an toàn khác để đổi Mật khẩu Ngân hàng, Mật khẩu Email, Zalo/Facebook và mã PIN Smart OTP.\n\n"
            "4. 👮 **Bước 4 - Trình Báo Cơ Quan Công An:**\n"
            "  - Đến ngay Công an phường/xã gần nhất hoặc nộp đơn tố giác tội phạm qua Cổng Dịch vụ công Bộ Công An kèm sao kê giao dịch để cơ quan công an phối hợp cùng ngân hàng phong tỏa dòng tiền kịp thời.\n\n"
            "👉 Quý khách có thể bấm chọn nhanh các gợi ý bên dưới để xem tiếp câu trả lời chi tiết nhé ạ!"
        )
        return {
            "answer": answer,
            "quick_replies": ["Khóa tài khoản khẩn cấp", "Cài đặt an toàn bảo mật", "Hotline 1900-SENHONG"],
            "suggested_action": {"label": "Khóa tài khoản khẩn cấp", "route": "/settings/security"},
            "sources": ["Khuyến cáo an ninh mạng C06 & A05 Bộ Công An", "Cẩm nang phản ứng sự cố an toàn thông tin Sen Hồng Bank"]
        }

    # =========================================================================
    # KỊCH BẢN 24: HỆ THỐNG 6 LOẠI NHẮC NHỞ TÀI CHÍNH THÔNG MINH (SMART REMINDERS)
    # Ví dụ: "Hệ thống nhắc nhở thông minh của app", "Các loại nhắc nhở tài chính", "Nhắc nhở người dùng", "Nhắc lịch thanh toán"
    # =========================================================================
    is_personal_reminder_query = any(k in q_lower for k in [
        "của tôi", "cua toi", "của mình", "cua minh", "của em", "cua em", "nhắc tôi", "nhac toi", "nhắc nhở tôi", "nhac nho toi"
    ])
    has_reminder_term = (not is_personal_reminder_query) and any(k in q_lower for k in [
        "nhắc nhở", "nhac nho", "lời nhắc", "loi nhac",
        "lịch tài chính", "lich tai chinh", "lịch thanh toán", "lich thanh toan",
        "nhắc nợ", "nhac no", "nhắc thẻ", "nhac the", "nhắc đáo hạn", "nhac dao han",
        "cảnh báo chi tiêu", "canh bao chi tieu", "hóa đơn định kỳ", "hoa don dinh ky",
        "auto-savings", "tích lũy tự động", "tich luy tu dong", "nhắc người dùng", "nhac nguoi dung"
    ])
    if has_reminder_term:
        answer = (
            "Dạ Sen Hồng Bank xin gửi Quý khách bản tóm lược **Hệ Thống 6 Loại Nhắc Nhở Tài Chính Thông Minh (Smart Reminders)** "
            "giúp Quý khách an tâm quản lý dòng tiền, không lo trễ hạn:\n\n"
            "1. 🔔 **Nhắc Lịch Thanh Toán Hóa Đơn Định Kỳ (Điện, Nước, Internet):**\n"
            "  - Chu kỳ phát sinh: Từ ngày **10 đến 15 hàng tháng**.\n"
            "  - Hệ thống tự động quét và gửi thông báo cước trước **3 ngày** và **1 ngày** trước hạn chót. Quý khách có thể bật tính năng **Auto-Debit (Trích nợ tự động 0đ phí)** để gạch nợ tức thì.\n\n"
            "2. 💳 **Nhắc Sao Kê & Hạn Chót Thanh Toán Thẻ Tín Dụng:**\n"
            "  - Báo sao kê ngày 20 - 25 và nhắc hạn thanh toán trước ngày **15 tháng sau** (trước hạn 5 ngày & 2 ngày).\n"
            "  - Hướng dẫn thanh toán 100% dư nợ sao kê để bảo toàn trọn vẹn đặc quyền **45 - 55 ngày miễn lãi**, tránh phí phạt chậm trả **4% - 5%** và lãi suất 20% - 28%/năm.\n\n"
            "3. 📑 **Nhắc Lịch Trả Nợ Vay Quick Loan Định Kỳ:**\n"
            "  - Nhắc trước ngày đến hạn **3 ngày** số tiền gốc + lãi của kỳ thanh toán.\n"
            "  - Bảo vệ lịch sử tín dụng CIC tuyệt đối tránh rơi vào **Nhóm 2 (Cần chú ý)** hoặc **Nhóm 3-5 (Nợ xấu)**; Hỗ trợ **tất toán trước hạn miễn phí 100%**.\n\n"
            "4. 📈 **Nhắc Ngày Đáo Hạn Sổ Tiết Kiệm Trực Tuyến (Core Savings):**\n"
            f"  - Gửi thông báo trước **2 ngày** khi sổ đến hạn. Quý khách có thể chọn: Tự động tái tục cả gốc và lãi (hưởng lãi kép đến **{rate_config.SAVINGS_RATES[24]:.1f}%/năm**), Tái tục gốc chuyển lãi về ví, hoặc rút một phần gốc linh hoạt bảo toàn lãi suất theo **Thông tư 04/2022/TT-NHNN**.\n\n"
            "5. ⚠️ **Cảnh Báo Vượt 80% Ngân Sách Chi Tiêu Sinh Hoạt:**\n"
            "  - Trợ lý AI PFM tự động phát cảnh báo tức thì khi tổng chi tiêu hoặc một nhóm mua sắm chạm mốc **80% hạn mức tháng** trước ngày 20 để kịp thời cân đối dòng tiền.\n\n"
            "6. 💰 **Nhắc Tích Lũy Tự Động Định Kỳ (Auto-Savings / Pay Yourself First):**\n"
            "  - Cài đặt trích tự động **10% - 20%** lương vào ngày 05 hoặc 10 hàng tháng chuyển thẳng vào sổ tiết kiệm tích lũy để hình thành kỷ luật tài chính vững chắc.\n\n"
            "👉 Quý khách có thể bấm chọn nhanh các gợi ý bên dưới để xem tiếp câu trả lời chi tiết nhé ạ!"
        )
        return {
            "answer": answer,
            "quick_replies": ["Cài đặt Auto-Debit hóa đơn", "Xem lịch trả nợ vay", "Thiết lập hạn mức ngân sách"],
            "suggested_action": {"label": "Lịch tài chính & Nhắc nhở", "route": "/profile"},
            "sources": ["Hệ thống Nhắc nhở Thông minh Sen Hồng Bank", "Cẩm nang Quản trị Tài chính Cá nhân"]
        }

    # =========================================================================
    # KỊCH BẢN 25: CÁ NHÂN HÓA CHI TIÊU SINH HOẠT THEO HỒ SƠ NGƯỜI DÙNG & TỪNG PHÂN KHÚC
    # Ví dụ: "Cá nhân hóa chi tiêu", "Chi tiết sinh hoạt", "Cá nhân hóa cho người dùng", "Chi tiêu sinh hoạt cho sinh viên/văn phòng/gia đình"
    # =========================================================================
    has_personal_lifestyle = any(k in q_lower for k in [
        "cá nhân hóa", "ca nhan hoa", "chi tiết sinh hoạt", "chi tiet sinh hoat",
        "sinh viên chi tiêu", "người mới đi làm chi tiêu", "dân văn phòng chi tiêu",
        "gia đình chi tiêu", "hộ kinh doanh chi tiêu", "lối sống sinh hoạt",
        "tôi nên chi tiêu sinh hoạt thế nào", "tư vấn chi tiết sinh hoạt"
    ]) or (
        any(k in q_lower for k in ["chi tiêu", "sinh hoạt", "ngân sách"]) and
        any(k in q_lower for k in ["sinh viên", "văn phòng", "gia đình", "cá nhân", "từng người", "cho tôi"])
    )
    if has_personal_lifestyle:
        answer = (
            "Dạ Sen Hồng Bank xin gửi Quý khách bản **Cá Nhân Hóa Chi Tiêu Sinh Hoạt Chi Tiết** "
            "được thiết kế chuyên biệt theo từng phân khúc người dùng:\n\n"
            "1. 🎓 **Học Sinh - Sinh Viên & Người Mới Đi Làm (Thu nhập 8 - 12 triệu/tháng):**\n"
            "  - 🏠 **Tiền trọ / Ký túc xá:** **2.000.000 – 3.000.000 VNĐ** (nên ở ghép 2 - 3 bạn để tối ưu chi phí).\n"
            "  - 🍲 **Ăn uống sinh hoạt tự nấu:** **2.000.000 – 3.000.000 VNĐ** (hạn chế ăn ngoài và trà sữa hàng ngày).\n"
            "  - 💡 **Hóa đơn điện nước, mạng:** **400.000 – 700.000 VNĐ**; Xăng xe/Bus: **400.000 – 500.000 VNĐ**.\n"
            "  - 📚 **Học tập & Nâng cao kỹ năng:** **1.000.000 – 1.500.000 VNĐ** (đầu tư sinh lời lớn nhất giai đoạn này).\n"
            "  - 💰 **Tích lũy khẩn cấp:** tối thiểu **1.200.000 – 1.800.000 VNĐ/tháng** (15% thu nhập) để tạo quỹ an toàn 10 - 20 triệu.\n\n"
            "2. 💼 **Dân Văn Phòng Độc Thân (Thu nhập 15 - 25 triệu/tháng):**\n"
            "  - 🏠 **Thuê căn hộ mini / studio:** **4.500.000 – 6.500.000 VNĐ**.\n"
            "  - 🍲 **Thực phẩm nấu ăn tại nhà:** **3.000.000 – 4.000.000 VNĐ**; Ăn ngoài giao lưu: **2.500.000 – 4.000.000 VNĐ**.\n"
            "  - 💡 **Điện lạnh EVN, nước, 4G/5G:** **1.000.000 – 1.500.000 VNĐ**.\n"
            f"  - 💰 **Tích lũy tài sản (Auto-Savings):** trích ngay **3.000.000 – 5.000.000 VNĐ/tháng** (20% thu nhập) gửi tiết kiệm online kỳ hạn 12 - 24 tháng (lãi suất **{rate_config.SAVINGS_RATES[12]:.1f}% – {rate_config.SAVINGS_RATES[24]:.1f}%/năm**).\n\n"
            "3. 👨‍👩‍👧 **Hộ Gia Đình Trẻ Có Con Nhỏ (Thu nhập 30 - 50 triệu/tháng):**\n"
            "  - 🏠 **Trả góp mua nhà / thuê nhà:** không vượt quá **30% – 35%** thu nhập (**9.000.000 – 15.000.000 VNĐ**).\n"
            "  - 👶 **Học phí, bỉm sữa, khám sức khỏe cho con:** **5.000.000 – 8.000.000 VNĐ/cháu**.\n"
            "  - 🍲 **Thực phẩm dinh dưỡng cả nhà:** **6.000.000 – 9.000.000 VNĐ**; Điện nước gia đình: **1.500.000 – 2.500.000 VNĐ**.\n"
            "  - 🛡️ **Quỹ khẩn cấp & Bảo hiểm sức khỏe:** **4.500.000 – 7.500.000 VNĐ** (duy trì quỹ khẩn cấp 6 tháng ~**100 – 150 triệu**).\n\n"
            "4. 🏪 **Hộ Kinh Doanh Cá Thể & Freelancer:**\n"
            "  - Bắt buộc tách bạch tài khoản kinh doanh VietQR Pro và tài khoản sinh hoạt cá nhân; Tự trả lương cố định hàng tháng; Xây dựng quỹ dự phòng sinh hoạt **6 – 12 tháng**.\n\n"
            "👉 Quý khách có thể bấm chọn nhanh các gợi ý bên dưới để xem tiếp câu trả lời chi tiết nhé ạ!"
        )
        return {
            "answer": answer,
            "quick_replies": ["Lập ngân sách 50/30/20", "Mở sổ tích lũy tự động", "Bật cảnh báo hạn mức 80%"],
            "suggested_action": {"label": "Phân tích chi tiêu cá nhân", "route": "/profile"},
            "sources": ["Cẩm nang Cá nhân hóa Chi tiêu Sinh hoạt Sen Hồng Bank", "Chuẩn mực Quản trị Tài chính PFM"]
        }

    # =========================================================================
    # KỊCH BẢN 23: PHÂN TÍCH TIỀN CHI TIÊU SINH HOẠT, QUẢN TRỊ TÀI CHÍNH CÁ NHÂN & QUY TẮC 50/30/20
    # Ví dụ: "Hướng dẫn phân tích tiền chi tiêu sinh hoạt hàng tháng và cách lập ngân sách theo quy tắc 50/30/20"
    # =========================================================================
    has_expense_term = any(k in q_lower for k in [
        "chi tiêu sinh hoạt", "chi tieu sinh hoat", "tiền sinh hoạt", "tien sinh hoat",
        "phân tích chi tiêu", "phan tich chi tieu", "quản lý chi tiêu", "quan ly chi tieu",
        "lập ngân sách", "lap ngan sach", "50/30/20", "6 chiếc lọ", "6 chiec lo", "sổ thu chi", "so thu chi"
    ])
    if has_expense_term:
        answer = (
            "Dạ Sen Hồng Bank xin gửi Quý khách bản **Phân tích Chi tiêu Sinh hoạt & Kế hoạch Quản lý Tài chính Thông minh** "
            "theo chuẩn mực quốc tế như sau ạ:\n\n"
            "1. 📊 **Phân Bổ Ngân Sách Sinh Hoạt Theo Quy Tắc Vàng 50/30/20:**\n"
            "  - 🏠 **50% - Nhu Cầu Thiết Yếu (Needs):** Chi phí cố định bắt buộc gồm tiền thuê nhà/trả góp, tiền ăn uống nấu nướng tại nhà, hóa đơn điện nước internet và xăng xe đi lại. (Khuyến nghị: Không để vượt quá 50% thu nhập).\n"
            "  - ☕ **30% - Mong Muốn & Sở Thích (Wants):** Cà phê giao lưu bạn bè, ăn ngoài cuối tuần, mua sắm thời trang, xem phim, du lịch. (Đây là khoản dễ gây bội chi nhất, cần kiểm soát bằng quy tắc cân nhắc 48 giờ trước khi mua).\n"
            f"  - 💰 **20% - Tiết Kiệm & Tích Lũy (Savings):** Gửi Tiết kiệm online Sen Hồng (lãi suất đến **{rate_config.SAVINGS_RATES[24]:.1f}%/năm**) để xây dựng **Quỹ dự phòng khẩn cấp 3 - 6 tháng** và đầu tư sinh lời.\n\n"
            "2. 🏺 **Mô Hình 6 Chiếc Lọ (Jars System):**\n"
            "  - Thiết yếu (55%) • Tiết kiệm dài hạn (10%) • Tự do tài chính (10%) • Giáo dục & Học tập (10%) • Hưởng thụ (10%) • Cho đi (5%).\n\n"
            "3. 💡 **Cảnh Báo 3 Lỗ Rò Rỉ Tài Chính Thường Gặp:**\n"
            "  - Tiền trà sữa / cà phê hàng ngày (50k/ngày $\rightarrow$ mất **18 triệu/năm**).\n"
            "  - Các gói dịch vụ định kỳ bị quên (Subscription Ghost).\n"
            "  - Đặt đồ ăn giao tận nơi thường xuyên chịu phụ phí 20% - 30%.\n\n"
            "4. 📱 **Tính Năng Quản Lý Chi Tiêu Tự Động (Smart PFM) Trên App Sen Hồng:**\n"
            "  - Tự động gắn thẻ phân loại mọi giao dịch thẻ/VietQR thành các nhóm trực quan.\n"
            "  - Cài đặt hạn mức ngân sách từng nhóm, cảnh báo khi chi chạm mốc 80%.\n\n"
            "👉 Quý khách có thể bấm chọn nhanh các gợi ý bên dưới để xem tiếp câu trả lời chi tiết nhé ạ!"
        )
        return {
            "answer": answer,
            "quick_replies": ["Xem biểu đồ chi tiêu", "Thiết lập hạn mức ngân sách", "Mở sổ tiết kiệm tích lũy"],
            "suggested_action": {"label": "Quản lý chi tiêu", "route": "/profile"},
            "sources": ["Cẩm nang Quản trị Tài chính Cá nhân Sen Hồng Bank", "Quy tắc phân bổ ngân sách 50/30/20 & 6 Chiếc Lọ"]
        }

    # =========================================================================
    # KỊCH BẢN 27: BIỂU PHÍ & HẠN MỨC CHI TIẾT THEO CẤP ĐỘ ĐỊNH DANH (PHI_HAN_MUC)
    # Ví dụ: "cho em hỏi biểu phí và hạn mức chuyển tiền theo từng cấp độ eKYC như thế nào?"
    # =========================================================================
    has_fee_limit_topic = any(k in q_lower for k in [
        "biểu phí", "bieu phi", "hạn mức", "han muc", "phí giao dịch", "phi giao dich",
        "miễn phí", "mien phi", "phí thường niên", "phi thuong nien"
    ])
    has_tier_context = any(k in q_lower for k in [
        "ekyc", "cấp độ", "cap do", "định danh", "dinh danh", "smart otp",
        "hạn mức ngày", "han muc ngay", "giao dịch trên", "giao dich tren", "cấp 1", "cấp 2"
    ])
    if has_fee_limit_topic and (has_tier_context or len(words) >= 12):
        answer = (
            "Dạ Sen Hồng Bank xin trình bày **Biểu Phí & Hạn Mức chi tiết theo cấp độ định danh** "
            "để Quý khách nắm trọn hệ thống phí và hạn mức của mình ạ:\n\n"
            "⚡ **1. Hạn Mức Theo Cấp Độ eKYC:**\n"
            "  - **eKYC Cấp 1 (SĐT + OTP):** chuyển/chi tiêu tối đa **5.000.000 VNĐ/ngày**, tổng dư nợ ví **5.000.000 VNĐ**.\n"
            "  - **eKYC Cấp 2 (CCCD gắn chip + quét khuôn mặt):** tối đa **50.000.000 VNĐ/ngày**.\n"
            "  - **Kích hoạt Smart OTP / chữ ký số:** nâng trần lên **500.000.000 VNĐ/ngày**.\n"
            "  - Theo **Quyết định 2345/QĐ-NHNN**: giao dịch trên **10 triệu/lần** hoặc **20 triệu/ngày** bắt buộc xác thực khuôn mặt khớp chip CCCD.\n\n"
            "💳 **2. Biểu Phí Zero-Fee Banking:**\n"
            "  - Chuyển tiền Napas 24/7 nội bộ và liên ngân hàng: **miễn phí 100% trọn đời**.\n"
            "  - Nạp/rút tiền ví, phí quản lý tài khoản, thông báo biến động số dư: **miễn phí hoàn toàn**.\n"
            "  - Thẻ ảo Visa Platinum Virtual: **0đ phát hành + 0đ thường niên trọn đời**, phí ngoại tệ **1.5%**.\n\n"
            "💼 **3. Hạn Mức Vay & Thẻ:**\n"
            f"  - Vay Quick Loan: từ **{format_vnd(rate_config.QUICK_LOAN_MIN)}** đến **{format_vnd(rate_config.QUICK_LOAN_MAX)}**, lãi suất **{rate_config.DEFAULT_LOAN_MONTHLY_RATE:.1f}% - {rate_config.LOAN_RATE_MAX_MONTHLY:.1f}%/tháng** dư nợ giảm dần.\n"
            "  - Hạn mức thanh toán thẻ Visa: lên đến **100.000.000 VNĐ/giao dịch**.\n\n"
            "👉 Quý khách có thể bấm chọn nhanh các gợi ý bên dưới để xem tiếp câu trả lời chi tiết nhé ạ!"
        )
        return {
            "answer": answer,
            "quick_replies": ["Nâng hạn mức Smart OTP", "Biểu phí thẻ Visa", "Xác thực sinh trắc học QĐ 2345"],
            "suggested_action": {"label": "Cấp độ tài khoản & Hạn mức", "route": "/profile/kyc-level"},
            "sources": ["Biểu phí & Hạn mức chi tiết Sen Hồng Bank", "Quyết định 2345/QĐ-NHNN"]
        }

    # =========================================================================
    # KỊCH BẢN 28: BẢO HIỂM LIÊN KẾT TOÀN DIỆN (INSURANCE)
    # Ví dụ: "sen hồng có bán bảo hiểm nhân thọ và bảo hiểm sức khỏe không, quyền lợi thế nào?"
    # =========================================================================
    has_insurance_topic = any(k in q_lower for k in [
        "bảo hiểm", "bao hiem", "nhân thọ", "nhan tho", "sức khỏe", "suc khoe",
        "bảo hiểm du lịch", "bao hiem du lich", "bồi thường", "boi thuong"
    ])
    has_insurance_depth = any(k in q_lower for k in [
        "quyền lợi", "quyen loi", "phí bảo hiểm", "phi bao hiem", "mua bảo hiểm",
        "mua bao hiem", "bồi thường thế nào", "hủy hợp đồng", "huu hop dong", "bảo hiểm gì", "gói bảo hiểm"
    ])
    if has_insurance_topic and (has_insurance_depth or len(words) >= 12):
        answer = (
            "Dạ Sen Hồng Bank liên kết các công ty bảo hiểm uy tín phân phối **3 dòng sản phẩm bảo hiểm** "
            "mua trực tiếp trên app trong 2 phút, duyệt tự động ạ:\n\n"
            "🛡️ **1. Bảo Hiểm Nhân Thọ An Tâm:**\n"
            "  - Phí từ **500.000 VNĐ/năm**, số tiền bảo vệ đến **500.000.000 VNĐ** (tử vong/thương tật toàn bộ).\n"
            "  - Gói Toàn diện bổ sung bệnh lý nghiêm trọng: ung thư, nhồi máu cơ tim, đột quỵ.\n\n"
            "🏥 **2. Bảo Hiểm Sức Khỏe Chăm Sóc Plus:**\n"
            "  - Phí từ **800.000 VNĐ/năm**, chi trả viện phí nội trú đến **100.000.000 VNĐ/năm**.\n"
            "  - Bảo lãnh thanh toán trực tiếp tại bệnh viện liên kết, không phải ứng trước tiền.\n\n"
            "✈️ **3. Bảo Hiểm Du Lịch Toàn Cầu:**\n"
            "  - Phí từ **150.000 VNĐ/chuyến** (nội địa) hoặc **350.000 VNĐ/chuyến** (quốc tế).\n"
            "  - Chi phí y tế nước ngoài đến **1 tỷ VNĐ**, hoàn vé hủy chuyến, hành lý thất lạc.\n\n"
            "⚖️ **Lưu ý pháp lý quan trọng:**\n"
            "  - Hợp đồng do **công ty bảo hiểm đối tác phát hành và chi trả**, Sen Hồng đóng vai trò phân phối bancassurance.\n"
            "  - Quý khách có quyền **hủy miễn phí trong 21 ngày** (free-look period) kể từ ngày hiệu lực.\n"
            "  - Bồi thường online: tải hóa đơn → xác nhận eKYC → nhận tiền về ví trong **3 - 5 ngày làm việc**.\n\n"
            "👉 Quý khách có thể bấm chọn nhanh các gợi ý bên dưới để xem tiếp câu trả lời chi tiết nhé ạ!"
        )
        return {
            "answer": answer,
            "quick_replies": ["Mua bảo hiểm nhân thọ", "Bảo hiểm sức khỏe Plus", "Bảo hiểm du lịch quốc tế"],
            "suggested_action": {"label": "Bảo hiểm liên kết", "route": "/more"},
            "sources": ["Bảo hiểm nhân thọ, sức khỏe & du lịch liên kết Sen Hồng Bank"]
        }

    # =========================================================================
    # KỊCH BẢN 29: NGÂN HÀNG SỐ DOANH NGHIỆP SME - PAYROLL & VIETQR PRO (SME_BUSINESS)
    # Ví dụ: "công ty tôi muốn chi trả lương tự động và dùng VietQR Pro để bán hàng thì làm sao?"
    # =========================================================================
    has_sme_topic = any(k in q_lower for k in [
        "doanh nghiệp", "doanh nghiep", "sme", "công ty", "cong ty", "hộ kinh doanh",
        "ho kinh doanh", "chi trả lương", "chi tra luong", "payroll", "tiểu thương", "tieu thuong"
    ])
    has_sme_depth = any(k in q_lower for k in [
        "vietqr pro", "webhook", "đối soát", "doi soat", "mở tài khoản doanh nghiệp",
        "mo tai khoan doanh nghiep", "vay doanh nghiệp", "vay doanh nghiep", "phân quyền", "phan quyen"
    ])
    if has_sme_topic and (has_sme_depth or len(words) >= 12):
        answer = (
            "Dạ Sen Hồng Bank xin giới thiệu trọn bộ giải pháp **Ngân hàng số Doanh nghiệp SME** cho công ty/hộ kinh doanh của Quý khách ạ:\n\n"
            "🏦 **1. Mở Tài Khoản Doanh Nghiệp Online:**\n"
            "  - eKYC đại diện pháp luật (CCCD chip + VNeID Mức 2) kèm giấy phép kinh doanh, duyệt trong **4 giờ làm việc**.\n"
            "  - **Miễn phí năm đầu tiên**, năm sau 300.000 VNĐ/năm.\n\n"
            "💼 **2. Chi Trả Lương Tự Động (Payroll):**\n"
            "  - Tải file danh sách nhận lương (XLSX/CSV) → chi trả hàng loạt **1 lượt duyệt**, giải ngân Napas 24/7 vài giây.\n"
            "  - **Miễn phí 100%** giao dịch chi lương; nhân viên nhận lương qua Sen Hồng được **+0.3%/năm** lãi suất tiết kiệm online.\n\n"
            "🏪 **3. VietQR Pro Bán Hàng & Đối Soát:**\n"
            "  - Mã QR theo từng đơn hàng, cố định số tiền — quét là đúng, hạn chế chuyển nhầm.\n"
            "  - Webhook realtime đẩy về POS/website; **miễn phí 1.000 giao dịch/tháng**, sau đó 500 VNĐ/giao dịch.\n\n"
            "📈 **4. Tín Dụng Doanh Nghiệp:**\n"
            "  - Vay vốn lưu động **50 - 500 triệu**, lãi từ 1.2%/tháng dư nợ giảm dần, giải ngân trong **24 giờ**.\n"
            "  - Thẩm định theo doanh thu điện tử 3 tháng, không cần tài sản bảo đảm dưới 200 triệu.\n\n"
            "🔐 **5. Bảo Mật Maker-Checker:** kế toán tạo lệnh → giám đốc duyệt (2 cấp), Smart OTP bắt buộc cho lệnh trên 10 triệu theo QĐ 2345.\n\n"
            "👉 Quý khách có thể bấm chọn nhanh các gợi ý bên dưới để xem tiếp câu trả lời chi tiết nhé ạ!"
        )
        return {
            "answer": answer,
            "quick_replies": ["Mở TK doanh nghiệp online", "Cài đặt Payroll chi lương", "Đăng ký VietQR Pro"],
            "suggested_action": {"label": "Ngân hàng số doanh nghiệp", "route": "/more"},
            "sources": ["Ngân hàng số Doanh nghiệp SME Sen Hồng Bank", "Vay hộ kinh doanh tiểu thương Vimo"]
        }

    return None
