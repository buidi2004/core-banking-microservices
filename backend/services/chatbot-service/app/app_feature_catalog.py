"""
App Feature Catalog & Deep-link Directory
Danh Bạ Tính Năng & Hướng Dẫn Từng Bước Ứng Dụng Sen Hồng Bank:
- Lưu trữ danh mục toàn bộ tính năng trên ứng dụng Mobile Flutter
- Hướng dẫn thao tác theo từng bước đánh số (Bước 1, Bước 2, Bước 3...)
- Mapping chính xác đường dẫn điều hướng (Deep-link Route)
- Từ khóa tìm kiếm dân gian (có dấu, không dấu, viết tắt)
- Trả lời chính xác câu hỏi "App có tính năng X không?" (Không bịa đặt)
"""

import re
from typing import Dict, Any, List, Optional, Tuple
from app import rate_config
from app.vietnamese_nlp import normalize_vietnamese_query, strip_vietnamese_accents

# Danh bạ tính năng chính thức của Ứng dụng Ngân Hàng Số Sen Hồng (Sen Hồng Bank)
APP_FEATURES: List[Dict[str, Any]] = [
    {
        "id": "rut_tien_atm_khong_the",
        "ten": "Rút tiền ATM không cần thẻ",
        "mo_ta": "Rút tiền mặt tại cây ATM của các ngân hàng liên minh Napas bằng mã QR trên ứng dụng Sen Hồng mà không cần mang theo thẻ vật lý.",
        "vi_tri": "Trang chủ > Tiện ích > Rút tiền ATM (hoặc Quét QR tại cây ATM)",
        "route": "/atm-withdrawal",
        "can_dang_nhap": True,
        "cac_buoc": [
            "Mở app Sen Hồng, tại Trang chủ chọn **Tiện ích** -> Chọn **Rút tiền ATM** (hoặc bấm nút mở màn hình bên dưới).",
            "Chọn hoặc nhập số tiền cần rút -> Bấm **Xác nhận** và nhập mã PIN 6 số hoặc xác thực Face ID để hệ thống tạo mã QR rút tiền bí mật.",
            "Đến cây ATM của ngân hàng đối tác Napas (Vietcombank, MB, BIDV, Techcombank...), tại màn hình cây ATM bấm nút **'Rút tiền không dùng thẻ'** hoặc **'Quét QR'**.",
            "Dùng ứng dụng Sen Hồng quét mã QR hiển thị trên màn hình cây ATM và nhận tiền mặt tại khe máy."
        ],
        "keywords": [
            "rút tiền atm không cần thẻ", "rut tien atm khong can the",
            "rút tiền atm không thẻ", "rut tien atm khong the", 
            "rút tiền không cần thẻ", "rut tien khong can the", 
            "rút tiền không thẻ", "rut tien khong the",
            "rút atm không cần thẻ", "rut atm khong can the",
            "rút atm không thẻ", "rut atm khong the",
            "rút tiền bằng qr", "rut tien bang qr",
            "cardless", "atm qr", "rút atm", "rut atm"
        ],
        "khong_ho_tro": "Không hỗ trợ rút tại các cây ATM chưa trang bị tính năng quét VietQR/Napas QR; không hỗ trợ rút ngoại tệ USD."
    },
    {
        "id": "vay_quick_loan",
        "ten": "Vay tiêu dùng tín chấp Quick Loan",
        "mo_ta": "Gói vay tín chấp tiêu dùng từ 5 triệu đến 50 triệu đồng, giải ngân tự động trong 1 phút về ví sau khi duyệt eKYC, lãi suất ưu đãi từ 1.2%/tháng theo dư nợ giảm dần, miễn 100% phí trả nợ trước hạn.",
        "vi_tri": "Trang chủ > Dịch vụ tài chính > Vay nhanh Quick Loan",
        "route": "/bills/quick-loan",
        "can_dang_nhap": True,
        "cac_buoc": [
            "Mở ứng dụng Sen Hồng, tại Trang chủ chọn **Vay nhanh Quick Loan** (hoặc bấm nút bên dưới).",
            "Chọn số tiền muốn vay (từ 5 triệu đến 50 triệu) và kỳ hạn trả góp linh hoạt (3, 6, 12 hoặc 24 tháng).",
            "Kiểm tra bảng lịch trả nợ dự kiến (gốc, lãi tháng đầu, tổng lãi toàn kỳ) và xác nhận thông tin cá nhân.",
            "Xác thực sinh trắc học khuôn mặt Face ID và nhập mã Smart OTP để ký hợp đồng điện tử.",
            "Hệ thống tự động phê duyệt trong 30 giây và giải ngân tiền vào ví Sen Hồng chỉ trong 1 phút."
        ],
        "keywords": [
            "vay", "vay tien", "vay tiền", "quick loan", "vay tieu dung", "vay tiêu dùng",
            "vay tin chap", "vay tín chấp", "vay nhanh", "vay 50 trieu", "vay 50 triệu",
            "khoan vay", "khoản vay", "vay online"
        ],
        "khong_ho_tro": "Không hỗ trợ vay thế chấp bất động sản, vay mua ô tô qua app (chỉ hỗ trợ vay tín chấp tiêu dùng tối đa 50 triệu)."
    },
    {
        "id": "lich_tra_no_vay",
        "ten": "Lịch trả nợ khoản vay",
        "mo_ta": "Tra cứu chi tiết dư nợ gốc còn lại, số tiền gốc và lãi từng kỳ, lịch thanh toán hàng tháng và tất toán trước hạn khoản vay Quick Loan.",
        "vi_tri": "Trang chủ > Tiện ích > Lịch trả nợ vay (hoặc trong chi tiết khoản vay)",
        "route": "/loan/schedule",
        "can_dang_nhap": True,
        "cac_buoc": [
            "Mở App Sen Hồng, vào mục **Tiện ích** -> Chọn **Lịch trả nợ vay** (hoặc mở chi tiết khoản vay hiện có).",
            "Xem chi tiết dư nợ gốc còn lại, số tiền gốc và lãi đến hạn theo từng kỳ thanh toán.",
            "Quý khách có thể bấm **Thanh toán kỳ này** để trả nợ đúng hạn, hoặc bấm **Tất toán trước hạn** để thanh toán dứt điểm toàn bộ khoản vay (hoàn toàn miễn phí phạt)."
        ],
        "keywords": [
            "lịch trả nợ", "lich tra no", "lịch vay", "lich vay", "trả nợ vay", "tra no vay",
            "kỳ hạn trả nợ", "ky han tra no", "dư nợ gốc", "du no goc", "tất toán nợ", "tat toan no"
        ],
        "khong_ho_tro": "Không hỗ trợ hoãn nợ quá 3 kỳ liên tiếp mà không có lý do bất khả kháng."
    },
    {
        "id": "tiet_kiem_online",
        "ten": "Gửi tiết kiệm Online lãi kép",
        "mo_ta": f"Mở sổ tiết kiệm trực tuyến sinh lời vượt trội lên đến {rate_config.SAVINGS_RATES[24]:.1f}%/năm, kỳ hạn từ 1 tháng đến 36 tháng, lãi nhập gốc tự động khi tái tục, bảo toàn lãi suất theo Thông tư 04/2022/TT-NHNN khi rút một phần gốc trước hạn.",
        "vi_tri": "Trang chủ > Dịch vụ tài chính > Mở sổ tiết kiệm",
        "route": "/bills/savings",
        "can_dang_nhap": True,
        "cac_buoc": [
            "Mở app Sen Hồng, tại Trang chủ chọn **Mở sổ tiết kiệm** (hoặc bấm nút mở màn hình bên dưới).",
            f"Chọn kỳ hạn gửi mong muốn (1, 3, 6, 12, 24 hoặc 36 tháng để nhận lãi suất ưu đãi lên đến {rate_config.SAVINGS_RATES[24]:.1f}%/năm).",
            "Nhập số tiền muốn gửi tiết kiệm (tối thiểu từ 1.000.000 VNĐ).",
            "Chọn phương thức nhận lãi: **Lãi nhập gốc tự động** (để hưởng lãi kép tăng trưởng tài sản) hoặc **Lãi trả về ví hàng tháng**.",
            "Kiểm tra số tiền lãi dự kiến nhận được, nhập mã PIN để xác nhận mở sổ tức thì trong 30 giây."
        ],
        "keywords": [
            "tiết kiệm", "tiet kiem", "gửi tiết kiệm", "gui tiet kiem", "mở sổ tiết kiệm",
            "mo so tiet kiem", "sổ tiết kiệm", "so tiet kiem", "lãi suất tiết kiệm",
            "lai suat tiet kiem", "tích lũy", "tich luy", "gửi góp", "gui gop"
        ],
        "khong_ho_tro": "Không hỗ trợ mở sổ tiết kiệm bằng ngoại tệ USD/EUR (chỉ áp dụng tiền đồng VNĐ)."
    },
    {
        "id": "chi_tiet_so_tiet_kiem",
        "ten": "Chi tiết & Tất toán sổ tiết kiệm",
        "mo_ta": "Theo dõi số dư, ngày đáo hạn, tiền lãi tích lũy và thực hiện tất toán toàn phần hoặc rút gốc từng phần online 24/7.",
        "vi_tri": "Trang chủ > Tiết kiệm > Chi tiết sổ tiết kiệm",
        "route": "/savings/detail",
        "can_dang_nhap": True,
        "cac_buoc": [
            "Mở app Sen Hồng, vào mục **Tiết kiệm** -> Chọn sổ tiết kiệm Quý khách muốn quản lý.",
            "Xem chi tiết số tiền gốc, tiền lãi tạm tính đã sinh ra và ngày đáo hạn của sổ.",
            "Nếu cần rút tiền: Bấm **Rút gốc từng phần** (phần tiền còn lại vẫn giữ nguyên lãi suất có kỳ hạn ban đầu theo TT 04/2022/TT-NHNN), hoặc bấm **Tất toán sổ** để nhận toàn bộ gốc và lãi về ví ngay lập tức."
        ],
        "keywords": [
            "tất toán sổ", "tat toan so", "rút sổ tiết kiệm", "rut so tiet kiem",
            "chi tiết sổ", "chi tiet so", "đáo hạn sổ", "dao han so"
        ],
        "khong_ho_tro": "Rút trước hạn hưởng lãi suất không kỳ hạn 0.2%/năm đối với số tiền rút ra."
    },
    {
        "id": "the_visa_platinum",
        "ten": "Thẻ ảo quốc tế Visa Platinum Virtual",
        "mo_ta": "Phát hành thẻ ảo Visa trong 30 giây ngay trên ứng dụng, miễn 100% phí phát hành và thường niên năm đầu, bảo mật mã CVV động thay đổi theo phiên, miễn lãi tối đa 45 ngày, thanh toán online toàn cầu.",
        "vi_tri": "Trang chủ > Quản lý Thẻ > Thẻ Visa",
        "route": "/cards",
        "can_dang_nhap": True,
        "cac_buoc": [
            "Mở app Sen Hồng, vào mục **Quản lý Thẻ** -> Chọn **Thẻ ảo Visa Platinum Virtual**.",
            "Kiểm tra hạn mức chi tiêu được cấp và các quyền lợi ưu đãi miễn phí thường niên.",
            "Nhập mã PIN giao dịch hoặc xác thực Face ID để kích hoạt phát hành thẻ.",
            "Thẻ ảo được kích hoạt ngay sau 30 giây kèm dãy 16 số thẻ, ngày hết hạn và mã CVV động sẵn sàng thanh toán online toàn cầu (Shopee, Netflix, Spotify, Grab...)."
        ],
        "keywords": [
            "thẻ visa", "the visa", "mở thẻ visa", "mo the visa", "thẻ ảo", "the ao",
            "visa platinum", "thẻ tín dụng", "the tin dung", "thẻ quốc tế", "the quoc te",
            "khóa thẻ", "khoa the", "mở khóa thẻ", "mo khoa the", "cvv"
        ],
        "khong_ho_tro": "Thẻ ảo không rút trực tiếp tại khe nuốt thẻ ATM truyền thống (dùng tính năng Rút tiền QR ATM)."
    },
    {
        "id": "chuyen_tien_napas247",
        "ten": "Chuyển tiền Napas 24/7",
        "mo_ta": "Chuyển tiền tức thì 24/7 qua số tài khoản, số thẻ, số điện thoại hoặc mã VietQR đến hơn 40 ngân hàng thành viên Napas, miễn phí 100% trọn đời, tiền nhận sau 1-3 giây.",
        "vi_tri": "Trang chủ > Chuyển tiền (nút tròn nổi bật giữa màn hình)",
        "route": "/transfer",
        "can_dang_nhap": True,
        "cac_buoc": [
            "Tại màn hình Trang chủ, bấm nút tròn **Chuyển tiền**.",
            "Chọn hình thức chuyển: Chuyển qua Số tài khoản ngân hàng, Số thẻ Napas, hoặc chọn Người nhận trong Danh bạ.",
            "Chọn ngân hàng thụ hưởng và nhập số tài khoản (hệ thống tự động tra cứu tên chủ tài khoản thụ hưởng chuẩn xác 100%).",
            "Nhập số tiền và nội dung chuyển tiền -> Bấm **Tiếp tục**.",
            "Xác thực bằng mã PIN hoặc Face ID sinh trắc học (với giao dịch từ 10 triệu đồng trở lên) để hoàn tất chuyển tiền trong 1 đến 3 giây."
        ],
        "keywords": [
            "chuyển tiền", "chuyen tien", "chuyển khoản", "chuyen khoan", "napas",
            "bắn tiền", "ban tien", "gửi tiền cho bạn", "gui tien cho ban", "stk", "số tài khoản"
        ],
        "khong_ho_tro": "Giao dịch trên 10 triệu đồng/lần hoặc trên 20 triệu đồng/ngày bắt buộc xác thực khuôn mặt eKYC theo QĐ 2345/QĐ-NHNN."
    },
    {
        "id": "quet_vietqr",
        "ten": "Quét mã VietQR thanh toán",
        "mo_ta": "Quét mọi mã QR thanh toán chuẩn VietQR, Napas247, VNPAY-QR tại cửa hàng, siêu thị, nhà hàng chỉ trong 1 chạm.",
        "vi_tri": "Góc trên thanh tìm kiếm hoặc Bottom Bar > Nút Quét QR",
        "route": "/scan-qr",
        "can_dang_nhap": True,
        "cac_buoc": [
            "Tại màn hình chính ứng dụng, chạm vào biểu tượng **Quét mã QR** ở thanh tìm kiếm trên cùng hoặc nút QR ở giữa thanh Bottom Bar.",
            "Hướng camera điện thoại về phía mã VietQR / Napas247 / VNPAY-QR tại quầy thu ngân.",
            "Ứng dụng tự động nhận diện thông tin đơn hàng, số tiền và tên người nhận.",
            "Kiểm tra lại số tiền và nhấn **Xác nhận thanh toán** bằng mã PIN hoặc Face ID."
        ],
        "keywords": [
            "quét qr", "quet qr", "quét mã", "quet ma", "scan qr", "qr pay", "thanh toán qr",
            "thanh toan qr", "chụp mã qr", "chup ma qr"
        ],
        "khong_ho_tro": "Không quét được các mã QR của ví điện tử nước ngoài (WeChat Pay, Alipay) chưa liên kết Napas."
    },
    {
        "id": "ma_qr_cua_toi",
        "ten": "Mã QR nhận tiền của tôi",
        "mo_ta": "Tạo mã VietQR nhận tiền cá nhân gắn sẵn số tài khoản và tùy chọn số tiền cố định để người khác quét chuyển tiền nhanh.",
        "vi_tri": "Trang chủ > Nút 'Mã QR của tôi' (cạnh số dư ví)",
        "route": "/my-qr",
        "can_dang_nhap": True,
        "cac_buoc": [
            "Tại Trang chủ, nhấn vào nút **Mã QR của tôi** (nằm cạnh số dư ví).",
            "Mã VietQR cá nhân hiển thị trên màn hình kèm đầy đủ Tên chủ tài khoản và Số tài khoản ngân hàng.",
            "Quý khách có thể tùy chọn bấm **'Nhập số tiền cố định'** nếu muốn người quét chuyển đúng số tiền đó.",
            "Đưa mã QR cho người chuyển quét hoặc nhấn **Lưu mã QR** vào thư viện ảnh để gửi qua Zalo/Facebook."
        ],
        "keywords": [
            "mã qr của tôi", "ma qr cua toi", "tạo mã qr", "tao ma qr", "qr nhận tiền",
            "qr nhan tien", "my qr", "nhận tiền bằng qr"
        ],
        "khong_ho_tro": "Không hỗ trợ tạo mã QR nhận ngoại tệ USD."
    },
    {
        "id": "chia_tien_split_bill",
        "ten": "Chia tiền nhóm & Nhắc nợ (Split Bill)",
        "mo_ta": "Tạo nhóm ăn uống, du lịch, tự động tính đều số tiền mỗi người và gửi thông báo nhắc nợ thông minh kèm mã QR chuyển khoản.",
        "vi_tri": "Trang chủ > Chuyển tiền > Chia tiền nhóm",
        "route": "/transfer/request",
        "can_dang_nhap": True,
        "cac_buoc": [
            "Tại Trang chủ, bấm **Chuyển tiền** -> Chọn **Chia tiền nhóm**.",
            "Nhập tên hoạt động (ví dụ: 'Ăn trưa', 'Tiền phòng du lịch') và nhập Tổng số tiền hóa đơn.",
            "Chọn bạn bè trong danh bạ hoặc nhập số điện thoại của các thành viên trong nhóm.",
            "Ứng dụng tự động chia đều số tiền mỗi người và gửi thông báo nhắc nợ kèm mã QR thanh toán đến từng thành viên."
        ],
        "keywords": [
            "chia tiền", "chia tien", "nhắc nợ", "nhac no", "split bill", "chia bill",
            "góp tiền", "gop tien", "chia tiền ăn", "chia tien an"
        ],
        "khong_ho_tro": "Chỉ gửi thông báo nhắc nợ, không tự ý trừ tiền tài khoản của người khác khi chưa xác nhận."
    },
    {
        "id": "nap_tien_vao_vi",
        "ten": "Nạp tiền vào ví Sen Hồng",
        "mo_ta": "Nạp tiền tức thì từ tài khoản ngân hàng liên kết (Vietcombank, MB, BIDV, Techcombank...) hoặc thẻ ATM nội địa Napas, miễn phí 100%.",
        "vi_tri": "Trang chủ > Nút Nạp tiền (+)",
        "route": "/deposit",
        "can_dang_nhap": True,
        "cac_buoc": [
            "Tại Trang chủ, nhấn nút **Nạp tiền** (+).",
            "Chọn tài khoản ngân hàng liên kết chính chủ (Vietcombank, MB, BIDV, Techcombank...).",
            "Nhập số tiền muốn nạp vào ví (tối thiểu 10.000 VNĐ).",
            "Xác nhận giao dịch bằng mã PIN hoặc Face ID. Tiền sẽ vào ví ngay lập tức hoàn toàn miễn phí 100%."
        ],
        "keywords": [
            "nạp tiền", "nap tien", "nạp ví", "nap vi", "bơm tiền", "bom tien",
            "nạp từ ngân hàng", "nap tu ngan hang", "nạp thêm tiền", "nap them tien"
        ],
        "khong_ho_tro": "Không hỗ trợ nạp tiền bằng thẻ cào điện thoại giấy."
    },
    {
        "id": "rut_tien_ve_ngan_hang",
        "ten": "Rút tiền về tài khoản ngân hàng",
        "mo_ta": "Rút tiền từ số dư ví Sen Hồng về tài khoản ngân hàng chính chủ đã liên kết, tiền về tức thì 24/7, miễn phí giao dịch.",
        "vi_tri": "Trang chủ > Nút Rút tiền (-)",
        "route": "/withdraw",
        "can_dang_nhap": True,
        "cac_buoc": [
            "Tại Trang chủ, nhấn nút **Rút tiền** (-).",
            "Chọn tài khoản ngân hàng chính chủ thụ hưởng muốn rút tiền về.",
            "Nhập số tiền muốn rút từ số dư ví.",
            "Nhập mã PIN giao dịch để xác nhận. Tiền chuyển về tài khoản ngân hàng 24/7 chỉ sau 1 phút."
        ],
        "keywords": [
            "rút tiền", "rut tien", "rút về ngân hàng", "rut ve ngan hang",
            "rút tiền về tài khoản", "rut tien ve tai khoan", "rút về vcb", "rút về mb"
        ],
        "khong_ho_tro": "Chỉ rút về tài khoản ngân hàng chính chủ trùng họ tên trên giấy tờ eKYC."
    },
    {
        "id": "thanh_toan_hoa_don",
        "ten": "Thanh toán hóa đơn Điện, Nước, Internet",
        "mo_ta": "Tra cứu và thanh toán hóa đơn sinh hoạt điện EVN toàn quốc, nước sinh hoạt, mạng Internet FPT/VNPT/Viettel, truyền hình cáp tự động nhắc nợ khi có kỳ cước mới.",
        "vi_tri": "Trang chủ > Dịch vụ đời sống > Hóa đơn & Tiện ích",
        "route": "/bills",
        "can_dang_nhap": True,
        "cac_buoc": [
            "Tại Trang chủ, chọn mục **Hóa đơn & Tiện ích** (hoặc chọn thẳng Điện / Nước / Internet).",
            "Chọn loại dịch vụ cần thanh toán và chọn khu vực nhà cung cấp (ví dụ: Điện lực EVN Miền Bắc / EVN Miền Nam / EVN Hà Nội).",
            "Nhập **Mã khách hàng** ghi trên giấy báo tiền điện hoặc tin nhắn của nhà mạng.",
            "Kiểm tra số tiền cước đến hạn, họ tên chủ hộ và nhấn **Thanh toán ngay** bằng nguồn tiền ví Sen Hồng."
        ],
        "keywords": [
            "hóa đơn", "hoa don", "tiền điện", "tien dien", "tiền nước", "tien nuoc",
            "tiền mạng", "tien mang", "internet", "evn", "thanh toán điện nước"
        ],
        "khong_ho_tro": "Không hỗ trợ gạch cước cho các mã khách hàng điện lực sai định dạng hoặc đã tất toán."
    },
    {
        "id": "nap_dien_thoai_topup",
        "ten": "Nạp tiền điện thoại & Mua thẻ cào",
        "mo_ta": "Nạp tiền điện thoại trực tiếp cho thuê bao trả trước/trả sau các mạng Viettel, Mobifone, Vinaphone, Wintel chiết khấu đến 3 - 5%.",
        "vi_tri": "Trang chủ > Tiện ích > Nạp điện thoại",
        "route": "/bills/phone-recharge",
        "can_dang_nhap": True,
        "cac_buoc": [
            "Tại Trang chủ, chọn mục **Nạp điện thoại**.",
            "Nhập số điện thoại cần nạp hoặc chọn từ danh bạ máy.",
            "Chọn mệnh giá muốn nạp (từ 10.000đ đến 500.000đ, chiết khấu lên đến 3-5%).",
            "Chọn nguồn tiền thanh toán và nhập mã PIN xác nhận nạp tiền tức thì."
        ],
        "keywords": [
            "nạp điện thoại", "nap dien thoai", "bắn tiền điện thoại", "ban tien dien thoai",
            "mua thẻ cào", "mua the cao", "topup", "viettel", "vinaphone", "mobifone"
        ],
        "khong_ho_tro": "Không hoàn tiền nếu khách nhập nhầm số điện thoại người nhận đã nạp thành công."
    },
    {
        "id": "nap_data_4g_5g",
        "ten": "Nạp gói cước Data 4G/5G",
        "mo_ta": "Đăng ký các gói cước Data 1 ngày, 3 ngày, 7 ngày, 30 ngày (ST15K, SD135, D15, BIG90...) cộng dung lượng ngay sau 3 giây.",
        "vi_tri": "Trang chủ > Tiện ích > Nạp Data 4G/5G",
        "route": "/data-topup",
        "can_dang_nhap": True,
        "cac_buoc": [
            "Tại Trang chủ, chọn mục **Nạp Data 4G/5G**.",
            "Chọn nhà mạng (Viettel, Vinaphone, Mobifone) và nhập số thuê bao.",
            "Chọn gói cước theo ngày hoặc theo tháng (ví dụ: ST15K 3GB/3 ngày, SD135 5GB/ngày/tháng).",
            "Bấm **Thanh toán ngay**, dung lượng data được cộng vào tài khoản sau 3 giây."
        ],
        "keywords": [
            "data", "4g", "5g", "gói cước", "goi cuoc", "nạp data", "nap data",
            "mua dung lượng", "mua dung luong", "st15k", "sd135"
        ],
        "khong_ho_tro": "Không hủy được gói data sau khi nhà mạng đã kích hoạt dung lượng thành công."
    },
    {
        "id": "dat_ve_may_bay",
        "ten": "Đặt vé máy bay trực tuyến iMedia",
        "mo_ta": "Tìm kiếm, so sánh giá vé và đặt vé máy bay nội địa & quốc tế của Vietnam Airlines, Vietjet Air, Bamboo Airways với vé điện tử gửi về email.",
        "vi_tri": "Trang chủ > Đời sống > Đặt vé máy bay",
        "route": "/flight-booking",
        "can_dang_nhap": True,
        "cac_buoc": [
            "Tại Trang chủ, vào mục **Đời sống** -> Chọn **Đặt vé máy bay**.",
            "Chọn điểm đi, điểm đến, ngày bay và số lượng hành khách (Người lớn, Trẻ em).",
            "So sánh giá vé giữa các hãng Vietnam Airlines, Vietjet Air, Bamboo Airways và chọn chuyến bay phù hợp.",
            "Nhập thông tin hành khách chính xác theo CCCD/Hộ chiếu.",
            "Thanh toán trực tiếp bằng ví Sen Hồng và nhận mã đặt chỗ (PNR) cùng vé điện tử gửi về email."
        ],
        "keywords": [
            "vé máy bay", "ve may bay", "đặt vé", "dat ve", "chuyến bay", "chuyen bay",
            "vietjet", "vietnam airlines", "bamboo", "flight"
        ],
        "khong_ho_tro": "Chính sách đổi trả/hoàn vé tuân theo điều kiện cụ thể của từng hãng hàng không."
    },
    {
        "id": "the_game",
        "ten": "Mua thẻ Game Garena, Zing, VTC",
        "mo_ta": "Mua mã thẻ nạp game Garena (Liên Quân, FIFA Online), Zing Xu, Vcoin, Gate chiết khấu đến 5%, nhận mã thẻ và số seri tức thì.",
        "vi_tri": "Trang chủ > Tiện ích > Thẻ Game",
        "route": "/game-cards",
        "can_dang_nhap": True,
        "cac_buoc": [
            "Tại Trang chủ, chọn mục **Thẻ Game**.",
            "Chọn loại thẻ nạp: Garena, Zing Xu, Vcoin, Gate, Funcard.",
            "Chọn mệnh giá thẻ (từ 20.000đ đến 2.000.000đ).",
            "Xác nhận thanh toán bằng mã PIN ví Sen Hồng. Mã thẻ và số seri được hiển thị trên màn hình và lưu trong mục Lịch sử."
        ],
        "keywords": [
            "thẻ game", "the game", "garena", "zing", "vcoin", "liên quân", "lien quan",
            "nạp game", "nap game", "mua sò", "mua so"
        ],
        "khong_ho_tro": "Không đổi trả sau khi mã thẻ game đã hiển thị và xuất kho thành công."
    },
    {
        "id": "bao_hiem_xa_hoi_vssid",
        "ten": "Đóng bảo hiểm xã hội tự nguyện & BHYT",
        "mo_ta": "Tra cứu mã số BHXH và nộp tiền gia hạn bảo hiểm xã hội tự nguyện, bảo hiểm y tế hộ gia đình trực tuyến liên thông cơ quan BHXH Việt Nam.",
        "vi_tri": "Trang chủ > Đời sống > Bảo hiểm xã hội",
        "route": "/social-insurance",
        "can_dang_nhap": True,
        "cac_buoc": [
            "Tại Trang chủ, chọn mục **Bảo hiểm xã hội**.",
            "Nhập **Mã số BHXH** gồm 10 chữ số của người tham gia.",
            "Kiểm tra thông tin họ tên, kỳ gia hạn và số tiền đóng BHXH tự nguyện hoặc BHYT hộ gia đình.",
            "Bấm **Thanh toán ngay**, hệ thống tự động gạch nợ và đồng bộ trạng thái lên ứng dụng VssID."
        ],
        "keywords": [
            "bảo hiểm xã hội", "bao hiem xa hoi", "bhxh", "vssid", "đóng bảo hiểm",
            "dong bao hiem", "bhyt", "bảo hiểm y tế", "gia hạn bhxh"
        ],
        "khong_ho_tro": "Chỉ nộp tiền gia hạn theo mã số BHXH sẵn có, không hỗ trợ thủ tục cấp mới sổ BHXH lần đầu."
    },
    {
        "id": "ve_so_vietlott",
        "ten": "Mua vé số Vietlott & Vua Xổ Số",
        "mo_ta": "Đặt mua hộ vé số Vietlott (Power 6/55, Mega 6/45, Keno, Max 3D) và xổ số truyền thống, nhận hình ảnh vé thực tế và tự động trả thưởng vào ví.",
        "vi_tri": "Trang chủ > Tiện ích > Vé số Vietlott",
        "route": "/bills/lottery",
        "can_dang_nhap": True,
        "cac_buoc": [
            "Tại Trang chủ, chọn mục **Vé số Vietlott**.",
            "Chọn loại vé muốn chơi: Power 6/55, Mega 6/45, Keno hoặc Max 3D.",
            "Tự chọn dãy số may mắn của Quý khách hoặc chọn 'Máy tự chọn số'.",
            "Xác nhận đơn hàng và thanh toán bằng số dư ví.",
            "Điểm bán chụp ảnh vé thực tế gửi lên app. Nếu trúng thưởng, tiền thưởng tự động cộng thẳng vào ví Sen Hồng."
        ],
        "keywords": [
            "vietlott", "vé số", "ve so", "xổ số", "xo so", "keno", "mega", "power",
            "mua vé số", "mua ve so", "dò vé số", "do ve so"
        ],
        "khong_ho_tro": "Người tham gia mua vé số phải từ đủ 18 tuổi trở lên."
    },
    {
        "id": "tai_khoan_so_dep",
        "ten": "Chọn số tài khoản đẹp phong thủy",
        "mo_ta": "Chọn tài khoản số đẹp theo ngày sinh, số điện thoại, phong thủy Thần Tài, Tứ Quý, Lộc Phát, mở tài khoản online miễn phí hoặc ưu đãi đấu giá.",
        "vi_tri": "Trang chủ > Dịch vụ tài chính > Chọn số tài khoản đẹp",
        "route": "/lucky-account",
        "can_dang_nhap": True,
        "cac_buoc": [
            "Tại Trang chủ, chọn mục **Chọn số tài khoản đẹp**.",
            "Nhập đuôi số mong muốn: Ngày tháng năm sinh, số điện thoại, hoặc số phong thủy Thần Tài (79, 39), Tứ Quý (8888, 9999).",
            "Xem danh sách số tài khoản đẹp và mức phí niêm yết (nhiều dãy số miễn phí 100%).",
            "Chọn số tài khoản ưng ý và xác nhận mở tài khoản mới để nhận tiền ngay lập tức."
        ],
        "keywords": [
            "số đẹp", "so dep", "số tài khoản đẹp", "so tai khoan dep", "tứ quý", "tu quy",
            "thần tài", "than tai", "phong thủy", "phong thuy", "số ngày sinh", "so ngay sinh"
        ],
        "khong_ho_tro": "Số tài khoản VIP đặc biệt thuộc kho đấu giá ngân hàng phải trả phí niêm yết."
    },
    {
        "id": "chuyen_tien_quoc_te",
        "ten": "Chuyển tiền quốc tế & Nhận kiều hối",
        "mo_ta": "Chuyển tiền quốc tế qua hệ thống SWIFT/Western Union cho mục đích du học, trợ cấp thân nhân, khám chữa bệnh theo đúng quy định quản lý ngoại hối.",
        "vi_tri": "Trang chủ > Dịch vụ tài chính > Chuyển tiền quốc tế",
        "route": "/international-transfer",
        "can_dang_nhap": True,
        "cac_buoc": [
            "Tại Trang chủ, chọn mục **Chuyển tiền quốc tế**.",
            "Chọn quốc gia nhận tiền và loại ngoại tệ (USD, EUR, GBP, JPY, AUD...).",
            "Chọn mục đích chuyển tiền hợp pháp: Du học, Khám chữa bệnh, hoặc Trợ cấp thân nhân.",
            "Tải lên hình ảnh hồ sơ chứng từ theo yêu cầu (Hóa đơn học phí, Giấy báo nhập học...).",
            "Ngân hàng kiểm duyệt hồ sơ trực tuyến trong 2 giờ làm việc và thực hiện chuyển tiền điện tử qua mạng SWIFT."
        ],
        "keywords": [
            "chuyển tiền quốc tế", "chuyen tien quoc te", "kiều hối", "kieu hoi", "swift",
            "western union", "gửi tiền ra nước ngoài", "gui tien ra nuoc ngoai", "du học", "du hoc"
        ],
        "khong_ho_tro": "Bắt buộc cung cấp chứng từ mục đích chuyển tiền hợp pháp theo quy định của NHNN."
    },
    {
        "id": "gioi_thieu_ban_be",
        "ten": "Giới thiệu bạn bè nhận thưởng 50.000đ",
        "mo_ta": "Chia sẻ mã giới thiệu hoặc link tải app cho bạn bè, nhận ngay 50.000đ vào ví khi bạn bè đăng ký và hoàn tất định danh eKYC.",
        "vi_tri": "Trang chủ > Khám phá > Giới thiệu bạn bè",
        "route": "/referral",
        "can_dang_nhap": True,
        "cac_buoc": [
            "Tại Trang chủ, vào mục **Khám phá** -> Chọn **Giới thiệu bạn bè**.",
            "Sao chép **Mã giới thiệu** hoặc bấm nút **Chia sẻ link tải app** gửi cho bạn bè qua Zalo, Messenger, SMS.",
            "Hướng dẫn bạn bè tải app, nhập mã giới thiệu khi đăng ký và hoàn tất định danh eKYC Cấp 2.",
            "Ngay khi bạn bè hoàn tất, hệ thống tự động cộng **50.000 VNĐ** tiền mặt vào ví của Quý khách và tặng gói voucher 100.000đ cho bạn bè."
        ],
        "keywords": [
            "giới thiệu bạn bè", "gioi thieu ban be", "mã giới thiệu", "ma gioi thieu",
            "nhận 50k", "nhan 50k", "kiếm tiền", "kiem tien", "referral", "friend50k"
        ],
        "khong_ho_tro": "Không cộng thưởng cho các tài khoản ảo, trùng thiết bị hoặc bị khóa gian lận."
    },
    {
        "id": "kho_voucher_uu_dai",
        "ten": "Kho Voucher & Khuyến mãi",
        "mo_ta": "Thu thập mã giảm giá mua sắm Shopee/Lazada, voucher cà phê Highlands/Phúc Long, mã giảm cước Grab/Be, mã hoàn tiền nạp ví.",
        "vi_tri": "Trang chủ > Tab Ưu đãi (Thanh Bottom Bar)",
        "route": "/promotions",
        "can_dang_nhap": True,
        "cac_buoc": [
            "Tại thanh Bottom Bar dưới cùng, chọn tab **Ưu đãi** (biểu tượng hộp quà).",
            "Lướt xem danh mục voucher: Ăn uống, Mua sắm, Di chuyển, Nạp thẻ.",
            "Bấm **Lưu voucher** để đưa vào ví voucher cá nhân.",
            "Khi thanh toán hóa đơn hoặc mua sắm, chọn voucher để được giảm trừ tiền trực tiếp."
        ],
        "keywords": [
            "voucher", "khuyến mại", "khuyen mai", "khuyến mãi", "ưu đãi", "uu dai",
            "giảm giá", "giam gia", "mã quà tặng", "ma qua tang", "senpoint", "tích điểm"
        ],
        "khong_ho_tro": "Voucher có hạn sử dụng và số lượng nhất định theo từng đợt phát hành."
    },
    {
        "id": "quan_ly_thiet_bi",
        "ten": "Quản lý thiết bị & Đăng xuất từ xa",
        "mo_ta": "Xem danh sách các điện thoại đang đăng nhập tài khoản, đổi thiết bị tin cậy và thực hiện đăng xuất khẩn cấp từ xa.",
        "vi_tri": "Cài đặt > Bảo mật > Quản lý thiết bị",
        "route": "/settings/devices",
        "can_dang_nhap": True,
        "cac_buoc": [
            "Vào mục **Cài đặt** (biểu tượng bánh răng) -> Chọn **Cài đặt bảo mật** -> Chọn **Quản lý thiết bị**.",
            "Xem danh sách tên điện thoại, địa chỉ IP và thời gian đăng nhập gần nhất.",
            "Nếu phát hiện thiết bị lạ: Nhấn nút **Đăng xuất khỏi thiết bị này** để hủy quyền truy cập ngay lập tức."
        ],
        "keywords": [
            "quản lý thiết bị", "quan ly thiet bi", "đăng xuất từ xa", "dang xuat tu xa",
            "thiết bị đăng nhập", "thiet bi dang nhap", "đổi máy", "doi may"
        ],
        "khong_ho_tro": "Đổi sang điện thoại mới bắt buộc quét NFC căn cước công dân gắn chip để kích hoạt."
    },
    {
        "id": "doc_chip_nfc_cccd",
        "ten": "Đọc chip NFC Căn cước công dân",
        "mo_ta": "Áp thẻ CCCD gắn chip vào mặt lưng điện thoại để đọc dữ liệu sinh trắc học xác thực eKYC cấp cao theo Quyết định 2345/QĐ-NHNN.",
        "vi_tri": "Hồ sơ > Nâng cấp định danh > Quét NFC CCCD",
        "route": "/profile/nfc-reader",
        "can_dang_nhap": True,
        "cac_buoc": [
            "Đảm bảo điện thoại của Quý khách đã bật tính năng NFC trong phần Cài đặt máy.",
            "Mở app Sen Hồng, vào mục **Hồ sơ** -> Chọn **Nâng cấp eKYC Cấp 2** -> Chọn **Quét NFC CCCD**.",
            "Áp sát mặt sau thẻ Căn cước công dân gắn chip vào vị trí đầu đọc NFC (thường nằm cạnh cụm camera mặt lưng điện thoại).",
            "Giữ nguyên điện thoại và thẻ CCCD cố định trong khoảng 3 đến 5 giây cho đến khi ứng dụng báo 'Đọc dữ liệu chip CCCD thành công'."
        ],
        "keywords": [
            "nfc", "cccd gắn chip", "cccd gan chip", "quét nfc", "quet nfc", "đọc chip",
            "doc chip", "sinh trắc học", "sinh trac hoc", "căn cước", "can cuoc"
        ],
        "khong_ho_tro": "Điện thoại phải hỗ trợ phần cứng NFC và bật tính năng NFC trong cài đặt máy."
    },
    {
        "id": "chu_ky_so_smart_otp",
        "ten": "Chữ ký số Smart OTP",
        "mo_ta": "Phương thức xác thực giao dịch an toàn thế hệ mới tích hợp trực tiếp trong app, không phụ thuộc sóng viễn thông SMS, hạn mức giao dịch lên đến 500 triệu/ngày.",
        "vi_tri": "Cài đặt > Bảo mật > Chữ ký số Smart OTP",
        "route": "/profile/digital-signature",
        "can_dang_nhap": True,
        "cac_buoc": [
            "Mở app Sen Hồng, vào mục **Cài đặt** -> Chọn **Bảo mật** -> Chọn **Chữ ký số Smart OTP**.",
            "Nhấn nút **Kích hoạt Smart OTP** và nhập mã xác thực OTP gửi về SMS điện thoại.",
            "Thiết lập mã mở khóa Smart OTP riêng biệt (4 hoặc 6 chữ số).",
            "Từ nay mọi giao dịch chuyển tiền hạn mức lớn sẽ tự động sinh mã xác thực an toàn ngay trên app mà không cần chờ tin nhắn SMS."
        ],
        "keywords": [
            "smart otp", "chữ ký số", "chu ky so", "mã otp", "ma otp", "cài smart otp",
            "cai smart otp", "kích hoạt smart otp", "nang han muc"
        ],
        "khong_ho_tro": "Mã Smart OTP gắn liền với thiết bị duy nhất đã xác thực eKYC."
    },
    {
        "id": "cai_dat_email_sao_ke",
        "ten": "Cài đặt Email nhận sao kê định kỳ",
        "mo_ta": "Đăng ký địa chỉ email chính chủ để nhận bảng sao kê tài khoản chi tiết hàng tháng và hóa đơn điện tử VAT miễn phí.",
        "vi_tri": "Hồ sơ > Cài đặt Email sao kê",
        "route": "/profile/email-settings",
        "can_dang_nhap": True,
        "cac_buoc": [
            "Mở app Sen Hồng, vào mục **Hồ sơ** -> Chọn **Cài đặt Email sao kê**.",
            "Nhập địa chỉ email chính chủ Quý khách muốn nhận sao kê.",
            "Nhập mã OTP gửi về email để xác thực quyền sở hữu hòm thư.",
            "Vào ngày mùng 1 hàng tháng, hệ thống tự động gửi file PDF sao kê toàn bộ giao dịch và biến động số dư có mật khẩu bảo mật về email của Quý khách."
        ],
        "keywords": [
            "sao kê", "sao ke", "sao kê email", "sao ke email", "email sao kê",
            "cài đặt email", "cai dat email", "hóa đơn vat", "sao kê tháng"
        ],
        "khong_ho_tro": "Sao kê bản cứng có mộc đỏ của ngân hàng phải đăng ký trực tiếp tại chi nhánh/phòng giao dịch."
    },
    {
        "id": "cap_do_tai_khoan_ekyc",
        "ten": "Cấp độ tài khoản & Hạn mức eKYC",
        "mo_ta": "Kiểm tra cấp độ định danh (Cấp 1 SĐT/OTP, Cấp 2 CCCD gắn chip, Cấp 3 Sinh trắc học Smart OTP) và hạn mức giao dịch tương ứng.",
        "vi_tri": "Hồ sơ > Cấp độ tài khoản eKYC",
        "route": "/profile/kyc-level",
        "can_dang_nhap": True,
        "cac_buoc": [
            "Vào mục **Hồ sơ** -> Chọn **Cấp độ tài khoản eKYC**.",
            "Xem cấp độ hiện tại của tài khoản và hạn mức giao dịch tương ứng.",
            "Để nâng lên Cấp 2 (50 triệu/ngày): Bấm **Xác thực CCCD gắn chip + Face ID**.",
            "Để nâng lên Cấp 3 (500 triệu/ngày): Bấm **Kích hoạt Chữ ký số Smart OTP**."
        ],
        "keywords": [
            "hạn mức ekyc", "han muc ekyc", "cấp độ tài khoản", "cap do tai khoan",
            "nâng hạn mức", "nang han muc", "định danh tài khoản", "dinh danh tai khoan"
        ],
        "khong_ho_tro": "Tài khoản chưa eKYC không thể giao dịch quá 5 triệu đồng/ngày."
    },
    {
        "id": "doi_ma_pin",
        "ten": "Đổi mã PIN giao dịch",
        "mo_ta": "Thay đổi mã PIN 6 số bảo vệ giao dịch khi vẫn nhớ mã PIN cũ, bảo mật thông tin tài khoản.",
        "vi_tri": "Cài đặt > Bảo mật > Đổi mã PIN giao dịch",
        "route": "/settings/change-pin",
        "can_dang_nhap": True,
        "cac_buoc": [
            "Mở app Sen Hồng, vào mục **Cài đặt** (biểu tượng bánh răng) -> Chọn **Cài đặt bảo mật** -> Chọn **Đổi mã PIN giao dịch**.",
            "Nhập mã PIN hiện tại gồm 6 chữ số.",
            "Nhập mã PIN mới 6 số và nhập lại mã PIN mới để xác nhận.",
            "Hệ thống thông báo đổi mã PIN thành công và áp dụng cho các giao dịch tiếp theo ngay lập tức."
        ],
        "keywords": [
            "đổi mã pin", "doi ma pin", "đổi pin", "doi pin", "thay đổi pin", "thay doi pin"
        ],
        "khong_ho_tro": "Nếu quên mã PIN cũ, vui lòng dùng tính năng 'Quên mã PIN' để lấy lại bằng eKYC."
    },
    {
        "id": "quen_ma_pin",
        "ten": "Lấy lại mã PIN giao dịch (Quên PIN)",
        "mo_ta": "Khôi phục và thiết lập mã PIN mới ngay trên app bằng xác thực khuôn mặt eKYC và mã Smart OTP/SMS mà không cần ra quầy giao dịch.",
        "vi_tri": "Màn hình nhập PIN > Bấm 'Quên mã PIN?' (hoặc Cài đặt > Quên mã PIN)",
        "route": "/auth/forgot-pin",
        "can_dang_nhap": False,
        "cac_buoc": [
            "Tại màn hình yêu cầu nhập mã PIN giao dịch, nhấn dòng chữ **'Quên mã PIN?'** (hoặc truy cập màn hình Lấy lại mã PIN bên dưới).",
            "Hệ thống gửi mã xác thực Smart OTP hoặc SMS về số điện thoại đăng ký tài khoản.",
            "Thực hiện quét sinh trắc học khuôn mặt eKYC (đối soát trực tiếp với dữ liệu chip CCCD).",
            "Thiết lập mã PIN 6 số mới và xác nhận lại mã PIN mới để kích hoạt lại giao dịch tức thì mà không cần ra quầy ngân hàng."
        ],
        "keywords": [
            "quên mã pin", "quen ma pin", "quên pin", "quen pin", "lấy lại mã pin",
            "lay lai ma pin", "khôi phục mã pin", "khoi phuc ma pin", "mất pin", "mat pin",
            "khóa pin", "khoa pin", "mở khóa pin", "mo khoa pin"
        ],
        "khong_ho_tro": "Không cấp lại mã PIN qua tổng đài viên điện thoại để đảm bảo an toàn tuyệt đối."
    },
    {
        "id": "quen_mat_khau",
        "ten": "Khôi phục mật khẩu đăng nhập",
        "mo_ta": "Lấy lại mật khẩu đăng nhập app khi bị quên qua số điện thoại chính chủ + mã OTP + quét khuôn mặt eKYC.",
        "vi_tri": "Màn hình đăng nhập > Bấm 'Quên mật khẩu?'",
        "route": "/auth/forgot-password",
        "can_dang_nhap": False,
        "cac_buoc": [
            "Tại màn hình Đăng nhập ứng dụng, bấm vào dòng chữ **'Quên mật khẩu?'**.",
            "Nhập Số điện thoại đã đăng ký tài khoản Sen Hồng và số CCCD gắn chip.",
            "Nhập mã xác thực OTP gửi về số điện thoại chính chủ.",
            "Quét khuôn mặt Face ID để hệ thống đối soát dữ liệu định danh.",
            "Nhập mật khẩu đăng nhập mới (tối thiểu 8 ký tự, gồm chữ hoa, chữ thường và số) và đăng nhập lại vào app."
        ],
        "keywords": [
            "quên mật khẩu", "quen mat khau", "mất mật khẩu", "mat mat khau",
            "lấy lại mật khẩu", "lay lai mat khau", "reset password", "khóa mật khẩu"
        ],
        "khong_ho_tro": "Tài khoản bị khóa sau 5 lần nhập sai mật khẩu liên tiếp để chống dò mật khẩu."
    },
    {
        "id": "lien_ket_ngan_hang",
        "ten": "Thẻ & Ngân hàng liên kết",
        "mo_ta": "Liên kết tài khoản hoặc thẻ ATM nội địa của hơn 40 ngân hàng Napas để nạp rút tiền tức thì 24/7 hoàn toàn miễn phí.",
        "vi_tri": "Trang chủ > Quản lý thẻ > Thẻ & Ngân hàng liên kết",
        "route": "/bank-cards",
        "can_dang_nhap": True,
        "cac_buoc": [
            "Mở app Sen Hồng, vào mục **Quản lý Thẻ** -> Chọn **Thẻ & Ngân hàng liên kết**.",
            "Bấm nút **Thêm liên kết mới (+)** và chọn ngân hàng của Quý khách trong danh sách hơn 40 ngân hàng Napas.",
            "Nhập Số tài khoản hoặc Số thẻ ngân hàng chính chủ (tên chủ tài khoản phải trùng với tài khoản Sen Hồng).",
            "Nhập mã OTP gửi từ ngân hàng liên kết để ủy quyền hoàn tất liên kết nạp rút miễn phí 100%."
        ],
        "keywords": [
            "liên kết ngân hàng", "lien ket ngan hang", "thêm ngân hàng", "them ngan hang",
            "liên kết thẻ", "lien ket the", "thẻ liên kết", "the lien ket", "napas liên kết"
        ],
        "khong_ho_tro": "Tên chủ tài khoản ngân hàng liên kết bắt buộc phải trùng khớp 100% với tên đăng ký tài khoản Sen Hồng."
    },
    {
        "id": "tra_soat_khieu_nai",
        "ten": "Trung tâm hỗ trợ & Gửi yêu cầu tra soát",
        "mo_ta": "Tạo phiếu yêu cầu tra soát khiếu nại trực tuyến khi gặp sự cố trừ tiền nhưng chưa nhận, chuyển nhầm tài khoản, kèm hotline 24/7 1900-SENHONG.",
        "vi_tri": "Cài đặt > Hỗ trợ & CSKH > Trung tâm hỗ trợ (hoặc chi tiết giao dịch lỗi)",
        "route": "/support/help-center",
        "can_dang_nhap": False,
        "cac_buoc": [
            "Vào mục **Cài đặt** -> Chọn **Hỗ trợ & CSKH** -> Chọn **Trung tâm hỗ trợ** (hoặc mở chi tiết giao dịch đang gặp sự cố và bấm **Yêu cầu tra soát**).",
            "Chọn loại sự cố: Chuyển tiền bị trừ nhưng người nhận chưa có, nạp tiền chưa nổi số dư, hoặc chuyển nhầm tài khoản.",
            "Điền mô tả ngắn gọn và đính kèm ảnh chụp màn hình giao dịch (nếu có).",
            "Bấm **Gửi yêu cầu tra soát** để hệ thống tạo mã Ticket tiếp nhận. Chuyên viên Sen Hồng sẽ xử lý và phản hồi trong 2 đến 24 giờ làm việc."
        ],
        "keywords": [
            "tra soát", "tra soat", "khiếu nại", "khieu nai", "sự cố giao dịch",
            "su co giao dich", "bị trừ tiền", "bi tru tien", "tiền bị treo", "tien bi treo",
            "hotline", "tổng đài", "tong dai", "cskh", "gặp nhân viên", "gap nhan vien"
        ],
        "khong_ho_tro": "Giao dịch liên ngân hàng ngoài giờ hành chính có thể cần 24 - 72 giờ làm việc để ngân hàng thụ hưởng đối soát."
    }
]


def find_feature_by_query(query: str) -> Optional[Dict[str, Any]]:
    """
    Tra cứu danh bạ tính năng ứng dụng dựa trên câu hỏi của người dùng:
    - Tìm kiếm theo từ khóa có dấu, không dấu, viết tắt
    - Phân biệt chính xác giữa Rút ATM không thẻ vs Rút tiền về ngân hàng
    - Trả về thông tin tính năng và Deep-link route chính xác
    """
    if not query:
        return None

    q_norm = normalize_vietnamese_query(query.strip()).lower()
    q_no_accent = strip_vietnamese_accents(q_norm).lower()

    # Ưu tiên trực tiếp các trường hợp đặc biệt dễ nhầm lẫn
    if any(k in q_norm for k in ["atm", "cây atm", "không thẻ", "khong the", "không cần thẻ", "khong can the"]):
        if any(r in q_norm for r in ["rút", "rut"]):
            for feat in APP_FEATURES:
                if feat["id"] == "rut_tien_atm_khong_the":
                    return feat

    if any(k in q_norm for k in ["về ngân hàng", "ve ngan hang", "về tài khoản", "ve tai khoan"]):
        if any(r in q_norm for r in ["rút", "rut"]):
            for feat in APP_FEATURES:
                if feat["id"] == "rut_tien_ve_ngan_hang":
                    return feat

    best_match = None
    max_len = 0

    for feat in APP_FEATURES:
        for kw in feat["keywords"]:
            kw_norm = kw.lower()
            kw_no_accent = strip_vietnamese_accents(kw_norm).lower()
            if kw_norm in q_norm or kw_no_accent in q_no_accent:
                if len(kw) > max_len:
                    max_len = len(kw)
                    best_match = feat

    return best_match


def check_app_has_feature(query: str) -> Tuple[bool, Optional[Dict[str, Any]], str]:
    """
    Kiểm tra xem Ứng dụng Sen Hồng có tính năng này hay không:
    - Trả về (True, feat, message) nếu có
    - Trả về (False, None, message) nếu không có (chống LLM bịa đặt!)
    """
    q_norm = normalize_vietnamese_query(query.strip()).lower()

    # Kiểm tra xem khách có đang hỏi câu dạng 'app có tính năng X không', 'có làm được X không'
    has_check_intent = any(k in q_norm for k in [
        "có tính năng", "co tinh nang", "có hỗ trợ", "co ho tro", "có làm được",
        "co lam duoc", "có mở được", "co mo duoc", "có bán", "co ban", "có dịch vụ", "co dich vu",
        "có thể", "co the"
    ]) and any(q in q_norm for q in ["không", "khong", "chưa", "chua", "được không", "duoc khong"])

    matched_feat = find_feature_by_query(query)

    if has_check_intent and matched_feat:
        msg = (
            f"Dạ ứng dụng **Sen Hồng Bank** hoàn toàn hỗ trợ tính năng **{matched_feat['ten']}** ạ!\n\n"
            f"- 📌 **Vị trí trên App:** {matched_feat['vi_tri']}\n"
            f"- ℹ️ **Mô tả:** {matched_feat['mo_ta']}\n"
            f"- ⚠️ **Lưu ý & Giới hạn:** {matched_feat['khong_ho_tro']}\n\n"
            f"Quý khách có thể bấm nút bên dưới để mở trực tiếp tính năng này trên ứng dụng ạ!"
        )
        return True, matched_feat, msg

    # Các tính năng phổ biến bên ngoài mà app NGÂN HÀNG SỐ SEN HỒNG CHƯA HỖ TRỢ (Khẳng định rõ ràng)
    unsupported_features = [
        ("mua vàng", "mua vang", "vàng miếng sjc", "kinh doanh vàng"),
        ("tiền ảo", "tien ao", "crypto", "bitcoin", "usdt", "tiền điện tử"),
        ("chứng khoán", "chung khoan", "cổ phiếu", "tra cứu chứng khoán"),
        ("vay mua nhà", "vay mua nha", "thế chấp sổ đỏ", "vay bất động sản"),
        ("vay mua ô tô", "vay mua o to", "thế chấp xe"),
        ("thẻ đen kim loại", "the den kim loai", "the vat ly", "thẻ vật lý lấy tại nhà"),
    ]

    for syns in unsupported_features:
        if any(s in q_norm for s in syns):
            feature_name = syns[0]
            msg = (
                f"Dạ hiện tại ứng dụng **Sen Hồng Bank** **chưa hỗ trợ** dịch vụ **{feature_name}** trực tiếp trên ứng dụng ạ.\n\n"
                f"Sen Hồng tập trung cung cấp các giải pháp tài chính số hiện đại như: "
                f"Gửi tiết kiệm online lãi kép đến **{rate_config.SAVINGS_RATES[24]:.1f}%/năm**, Vay tiêu dùng tín chấp **Quick Loan** (tối đa 50 triệu) "
                f"và Thẻ ảo quốc tế **Visa Platinum Virtual**.\n\n"
                f"Quý khách có thể tham khảo các tiện ích hiện có bằng nút bên dưới ạ!"
            )
            return False, None, msg

    if has_check_intent:
        msg = (
            "Dạ hiện tại ứng dụng **Sen Hồng Bank** chưa hỗ trợ tính năng này trong hệ sinh thái phiên bản hiện tại ạ. "
            "Quý khách có thể mở mục **Xem tất cả tiện ích** để khám phá các dịch vụ tài chính sẵn có của ngân hàng ạ!"
        )
        return False, None, msg

    return False, None, ""


def format_feature_howto_answer(feat: Dict[str, Any]) -> str:
    """Định dạng câu trả lời hướng dẫn thao tác theo từng bước đánh số chuẩn xác"""
    lines = [
        f"Dạ, để thực hiện tính năng **{feat['ten']}** trên ứng dụng Sen Hồng, Quý khách thực hiện theo các bước sau ạ:\n"
    ]
    if feat.get("cac_buoc"):
        for i, step in enumerate(feat["cac_buoc"], 1):
            lines.append(f"{i}. **Bước {i}:** {step}")
    else:
        lines.append(f"- ℹ️ **Hướng dẫn:** {feat['mo_ta']}")

    lines.append(f"\n- 📍 **Vị trí trên App:** {feat['vi_tri']}")
    if feat.get("khong_ho_tro"):
        lines.append(f"- ⚠️ **Lưu ý & Giới hạn:** {feat['khong_ho_tro']}")

    lines.append(f"\nQuý khách có thể bấm nút **[{feat['ten']}]** bên dưới để mở trực tiếp màn hình thao tác trên ứng dụng mà không cần tìm kiếm trong menu ạ!")
    return "\n".join(lines)
