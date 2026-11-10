"""
Financial ReAct Agent with Tool Use / Function Calling
Kiến trúc Agent Ngân Hàng Tự Quyết (Autonomous Tool-Using Financial Agent):
1. Nhận thức người dùng (Pre-loaded User Context: số dư, KYC, sản phẩm)
2. Viết lại câu truy vấn (Query Rewriter & Ambiguity Resolver)
3. Vòng lặp ReAct Loop (Suy nghĩ -> Gọi công cụ -> Đọc kết quả -> Trả lời)
4. Bảo mật cấp ngân hàng: user_id do backend quản lý, tool chỉ đọc, deterministic math
"""

import json
import logging
import time
from typing import List, Dict, Any, Optional, Tuple

from app.schemas import MessageItem, ChatResponse, ActionItem, VALID_APP_ROUTES
from app import rate_config
from app.financial_calculator import (
    calculate_savings_compound,
    calculate_loan_amortization,
    calculate_target_goal_savings,
    format_vnd,
    extract_amount_from_text,
    extract_term_years_from_text,
    generate_comprehensive_financial_analysis
)
from app.vietnamese_nlp import normalize_vietnamese_query, enrich_smart_quick_replies, detect_query_topic
from app.output_validator import sanitize_and_validate_output

logger = logging.getLogger("banking_agent")

# ==============================================================================
# 1. KHAI BÁO CÔNG CỤ (BANKING TOOLS SPECIFICATION - OPENAI / GEMINI SCHEMA)
# ==============================================================================

BANKING_TOOLS = [
    {
        "type": "function",
        "function": {
            "name": "get_account_summary",
            "description": "Lấy thông tin tài chính người dùng hiện tại gồm số dư ví khả dụng, trạng thái định danh eKYC, hạn mức giao dịch trong ngày và danh sách các sản phẩm đang sở hữu. Công cụ này chỉ đọc dữ liệu của khách hàng đang đăng nhập.",
            "parameters": {
                "type": "object",
                "properties": {},
                "required": []
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "get_recent_transactions",
            "description": "Lấy lịch sử các giao dịch gần đây của người dùng hiện tại (chuyển tiền, nhận tiền, thanh toán, nạp rút).",
            "parameters": {
                "type": "object",
                "properties": {
                    "limit": {
                        "type": "integer",
                        "description": "Số lượng giao dịch cần tra cứu (mặc định 5, tối đa 10)",
                        "default": 5
                    }
                },
                "required": []
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "get_financial_reminders",
            "description": "Lấy danh sách các lời nhắc tài chính thông minh (hóa đơn điện nước, hạn thẻ tín dụng, lịch trả nợ vay, ngày đáo hạn sổ tiết kiệm, cảnh báo hạn mức chi tiêu 80%) của người dùng hiện tại.",
            "parameters": {
                "type": "object",
                "properties": {},
                "required": []
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "get_interest_rates",
            "description": "Tra cứu bảng lãi suất niêm yết chính thức hiện hành của Ngân hàng Số Sen Hồng cho sản phẩm Tiết kiệm có kỳ hạn (1, 3, 6, 12, 24, 36 tháng) hoặc gói Vay tiêu dùng tín chấp Quick Loan.",
            "parameters": {
                "type": "object",
                "properties": {
                    "product_type": {
                        "type": "string",
                        "enum": ["SAVINGS", "LOAN"],
                        "description": "Loại sản phẩm cần tra cứu: 'SAVINGS' (tiết kiệm) hoặc 'LOAN' (vay tiêu dùng)"
                    },
                    "term_months": {
                        "type": "integer",
                        "description": "Kỳ hạn tính theo tháng (ví dụ: 1, 3, 6, 12, 24, 36). Nếu để trống sẽ trả về bảng lãi suất của toàn bộ các kỳ hạn."
                    }
                },
                "required": ["product_type"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "calculate_interest",
            "description": "Động cơ tính toán tài chính chuẩn xác 100% bằng code số học thuần túy (Deterministic Math Calculator): tính lãi kép tiết kiệm tái tục cả gốc và lãi, tính lịch trả nợ vay theo dư nợ giảm dần, hoặc tính kế hoạch gửi góp mục tiêu hàng tháng.",
            "parameters": {
                "type": "object",
                "properties": {
                    "calculation_type": {
                        "type": "string",
                        "enum": ["SAVINGS_COMPOUND", "LOAN_DECLINING", "SAVINGS_GOAL"],
                        "description": "Loại nghiệp vụ tính toán: 'SAVINGS_COMPOUND' (tiết kiệm sinh lời lãi kép 1-10 năm), 'LOAN_DECLINING' (vay Quick Loan dư nợ giảm dần), hoặc 'SAVINGS_GOAL' (gửi góp tích lũy mục tiêu)"
                    },
                    "amount": {
                        "type": "number",
                        "description": "Số tiền gốc hoặc số tiền mục tiêu cần tính (đơn vị: VNĐ, ví dụ: 50000000 cho 50 triệu)"
                    },
                    "term_months": {
                        "type": "integer",
                        "description": "Thời hạn tính theo tháng (ví dụ: 12 cho 1 năm, 60 cho 5 năm, 120 cho 10 năm)"
                    },
                    "annual_rate": {
                        "type": "number",
                        "description": "Lãi suất năm (%/năm). Nếu không truyền sẽ tự động áp dụng lãi suất niêm yết chuẩn của Sen Hồng Bank (SSOT app/rate_config.py)."
                    }
                },
                "required": ["calculation_type", "amount", "term_months"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "search_knowledge_base",
            "description": "Tra cứu cơ sở tri thức chính thức của Ngân hàng Sen Hồng (biểu phí Napas 24/7, hạn mức giao dịch, điều khoản sản phẩm, bảo mật eKYC, quy định thẻ Visa, chương trình ưu đãi voucher). Hãy viết lại câu hỏi rõ ràng trước khi tra cứu.",
            "parameters": {
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "Câu hỏi hoặc từ khóa tìm kiếm đã được viết lại đầy đủ ngữ cảnh"
                    }
                },
                "required": ["query"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "handoff_to_agent",
            "description": "Chuyển tiếp yêu cầu khiếu nại, sự cố giao dịch treo, tranh chấp hoặc thắc mắc vượt quá thẩm quyền của bot sang chuyên viên chăm sóc khách hàng 24/7 và tổng đài 1900-SENHONG.",
            "parameters": {
                "type": "object",
                "properties": {
                    "reason": {
                        "type": "string",
                        "description": "Lý do cần chuyển tiếp sang chuyên viên (ví dụ: giao dịch bị trừ tiền nhưng người nhận chưa có, khóa tài khoản)"
                    },
                    "summary": {
                        "type": "string",
                        "description": "Tóm tắt ngắn gọn vấn đề của khách hàng"
                    }
                },
                "required": ["reason"]
            }
        }
    }
]

# ==============================================================================
# 2. BỘ THỰC THI CÔNG CỤ (SECURE DETERMINISTIC TOOL EXECUTOR)
# ==============================================================================

class BankingToolExecutor:
    """
    Thực thi các công cụ với nguyên tắc bảo mật ngân hàng cốt lõi:
    - user_id được backend quản lý tuyệt đối (Anti-Spoofing)
    - Chỉ đọc dữ liệu từ microservices nội bộ
    - Tính toán số học chuẩn xác 100% bằng Python math
    """
    def __init__(self, rag_engine_instance):
        self.rag = rag_engine_instance

    def execute_tool(self, tool_name: str, arguments: Dict[str, Any], user_id: Optional[str]) -> Dict[str, Any]:
        """Thực thi tool theo tên và trả về dictionary kết quả"""
        try:
            if tool_name == "get_account_summary":
                return self._get_account_summary(user_id)
            elif tool_name == "get_recent_transactions":
                limit = int(arguments.get("limit", 5))
                return self._get_recent_transactions(user_id, limit)
            elif tool_name == "get_financial_reminders":
                return self._get_financial_reminders(user_id)
            elif tool_name == "get_interest_rates":
                prod = arguments.get("product_type", "SAVINGS")
                term = arguments.get("term_months")
                return self._get_interest_rates(prod, term)
            elif tool_name == "calculate_interest":
                calc_type = arguments.get("calculation_type", "SAVINGS_COMPOUND")
                amount = float(arguments.get("amount", 0))
                term_months = int(arguments.get("term_months", 12))
                rate = arguments.get("annual_rate")
                rate_val = float(rate) if rate is not None else None
                return self._calculate_interest(calc_type, amount, term_months, rate_val)
            elif tool_name == "search_knowledge_base":
                query = arguments.get("query", "")
                return self._search_knowledge_base(query)
            elif tool_name == "handoff_to_agent":
                reason = arguments.get("reason", "")
                summary = arguments.get("summary", "")
                return self._handoff_to_agent(reason, summary)
            else:
                return {"error": f"Tool '{tool_name}' không tồn tại trong hệ thống."}
        except Exception as e:
            logger.error("Error executing tool %s: %s", tool_name, e)
            return {"error": f"Lỗi khi thực thi {tool_name}: {str(e)}"}

    def _get_account_summary(self, user_id: Optional[str]) -> Dict[str, Any]:
        """Lấy thông tin tài khoản người dùng từ wallet-service và identity-service"""
        if not user_id:
            return {
                "status": "ANONYMOUS",
                "message": "Khách hàng chưa đăng nhập tài khoản. Hướng dẫn khách hàng đăng nhập để xem số dư thực tế.",
                "default_simulation_balance": 50000000,
                "fmt_default_balance": "50.000.000 VNĐ"
            }

        wallet_info = self.rag._fetch_user_wallet_balance(user_id)
        profile_info = self.rag._fetch_user_profile(user_id)
        cards_info = self.rag._fetch_user_cards(user_id)

        balance = 50000000.0
        currency = "VND"
        wallet_status = "ACTIVE"
        if wallet_info:
            balance = float(wallet_info.get("balance", 50000000.0))
            currency = wallet_info.get("currency", "VND")
            wallet_status = wallet_info.get("status", "ACTIVE")

        kyc_level = "LEVEL_2_EKYC"
        full_name = "Quý khách"
        if profile_info:
            full_name = profile_info.get("fullName") or profile_info.get("name") or "Quý khách"
            kyc_level = profile_info.get("kycStatus") or "LEVEL_2_EKYC"

        has_visa = any(c.get("cardType") == "VISA" for c in (cards_info or []))

        return {
            "status": "AUTHENTICATED",
            "full_name": full_name,
            "balance": balance,
            "formatted_balance": format_vnd(balance),
            "currency": currency,
            "wallet_status": wallet_status,
            "kyc_level": kyc_level,
            "daily_transfer_limit": "500.000.000 VNĐ" if "LEVEL_2" in str(kyc_level) else "5.000.000 VNĐ",
            "active_products": ["Ví Sen Hồng", "Tiết kiệm Online"] + (["Thẻ ảo Visa Platinum Virtual"] if has_visa else [])
        }

    def _get_recent_transactions(self, user_id: Optional[str], limit: int) -> Dict[str, Any]:
        """Lấy danh sách giao dịch gần đây của người dùng"""
        if not user_id:
            return {
                "status": "ANONYMOUS",
                "message": "Khách hàng chưa đăng nhập. Không có lịch sử giao dịch."
            }

        txs = self.rag._fetch_user_recent_transactions(user_id, limit=min(limit, 10))
        if not txs:
            return {
                "status": "EMPTY",
                "message": "Quý khách chưa có giao dịch nào phát sinh gần đây.",
                "transactions": []
            }

        formatted_txs = []
        for t in txs:
            amt = t.get("amount", 0)
            formatted_txs.append({
                "transaction_id": t.get("id") or t.get("transactionId"),
                "type": t.get("type", "TRANSFER"),
                "amount": amt,
                "formatted_amount": format_vnd(amt),
                "created_at": t.get("createdAt") or t.get("timestamp"),
                "status": t.get("status", "COMPLETED"),
                "description": t.get("description", "Giao dịch thanh toán")
            })

        return {
            "status": "SUCCESS",
            "count": len(formatted_txs),
            "transactions": formatted_txs
        }

    def _get_financial_reminders(self, user_id: Optional[str]) -> Dict[str, Any]:
        """Lấy lịch nhắc nhở tài chính cá nhân hóa từ các microservices"""
        if not user_id:
            return {
                "status": "ANONYMOUS",
                "message": "Khách hàng chưa đăng nhập tài khoản. Vui lòng đăng nhập để nhận lời nhắc tài chính cá nhân hóa.",
                "general_reminders": [
                    "Hóa đơn sinh hoạt (Điện/Nước/Internet): Ngày 10 - 15 hàng tháng",
                    "Hạn thanh toán thẻ tín dụng: Ngày 15 hàng tháng (miễn lãi 55 ngày)",
                    "Lịch trả nợ vay Quick Loan: Định kỳ hàng tháng",
                    "Ngày đáo hạn sổ tiết kiệm: Thông báo trước 2 ngày",
                    "Cảnh báo vượt 80% ngân sách chi tiêu tháng",
                    "Tích lũy tự động (Auto-Savings): Ngày nhận lương 05 hoặc 10 hàng tháng"
                ]
            }

        profile_info = self.rag._fetch_user_profile(user_id)
        wallet_info = self.rag._fetch_user_wallet_balance(user_id)
        cards_info = self.rag._fetch_user_cards(user_id)
        savings_info = self.rag._fetch_user_savings(user_id)
        loans_info = self.rag._fetch_user_loans(user_id)

        bal = float(wallet_info.get("balance", 0)) if wallet_info else 0.0
        full_name = profile_info.get("fullName", "Quý khách") if profile_info else "Quý khách"

        return {
            "status": "AUTHENTICATED",
            "full_name": full_name,
            "wallet_balance": bal,
            "formatted_balance": format_vnd(bal),
            "bill_status": "Đủ số dư thanh toán tự động Auto-Debit" if bal >= 2000000 else "Cần nạp thêm tiền vào ví",
            "active_cards_count": len(cards_info or []),
            "active_loans_count": len(loans_info or []),
            "active_savings_count": len(savings_info or []),
            "monthly_bill_window": "Ngày 10 - 15 hàng tháng",
            "credit_card_due_date": "Ngày 15 hàng tháng",
            "spending_budget_alert_threshold": "80% ngân sách tháng"
        }

    def _get_interest_rates(self, product_type: str, term_months: Optional[int]) -> Dict[str, Any]:
        """Tra cứu biểu lãi suất chuẩn của Sen Hồng Bank"""
        if product_type.upper() == "SAVINGS":
            # Biểu lãi suất đọc từ SSOT app/rate_config.py (khớp data/lai_suat_tiet_kiem.md)
            term_descs = {
                0: "Không kỳ hạn / Tiền để trong ví (CASA)",
                1: "Kỳ hạn 1 tháng",
                3: "Kỳ hạn 3 tháng",
                6: "Kỳ hạn 6 tháng (Linh hoạt thanh khoản)",
                9: "Kỳ hạn 9 tháng",
                12: "Kỳ hạn 12 tháng (Gói ưu đãi tích lũy tương lai)",
                18: "Kỳ hạn 18 tháng",
                24: "Kỳ hạn 24 tháng (Tối đa hóa lợi nhuận)",
                36: "Kỳ hạn 36 tháng",
            }
            rates = {
                term: {"rate": rate_val, "unit": "%/năm", "desc": term_descs.get(term, f"Kỳ hạn {term} tháng")}
                for term, rate_val in sorted(rate_config.SAVINGS_RATES.items())
            }
            if term_months and term_months in rates:
                return {
                    "product": "Tiết kiệm Online Sen Hồng",
                    "term_months": term_months,
                    "interest_rate": rates[term_months]["rate"],
                    "unit": rates[term_months]["unit"],
                    "policy": "Lãi nhập gốc tự động khi tái tục. Rút trước hạn hưởng lãi không kỳ hạn 0.2%/năm, phần tiền còn lại vẫn bảo toàn lãi suất theo TT 04/2022/TT-NHNN."
                }
            return {
                "product": "Tiết kiệm Online Sen Hồng",
                "interest_rates_table": rates,
                "policy": "Lãi nhập gốc tự động khi tái tục. Rút trước hạn hưởng lãi không kỳ hạn 0.2%/năm, phần tiền còn lại vẫn bảo toàn lãi suất theo TT 04/2022/TT-NHNN."
            }
        else:
            return {
                "product": "Khoản vay tiêu dùng Quick Loan",
                "interest_rate_monthly": rate_config.DEFAULT_LOAN_MONTHLY_RATE,
                "interest_rate_range": rate_config.LOAN_RATE_RANGE_TEXT,
                "calculation_method": "Dư nợ giảm dần (Tiền lãi giảm dần đều qua từng tháng)",
                "limit_range": f"Từ {format_vnd(rate_config.QUICK_LOAN_MIN)} đến {format_vnd(rate_config.QUICK_LOAN_MAX)}",
                "term_options": [3, 6, 12, 24],
                "disbursement_time": "Giải ngân tự động trong 1 phút sau khi duyệt online",
                "prepayment_penalty": "Miễn phí tất toán trước hạn 100%"
            }

    def _calculate_interest(
        self, 
        calculation_type: str, 
        amount: float, 
        term_months: int, 
        annual_rate: Optional[float]
    ) -> Dict[str, Any]:
        """Tính toán lãi suất chuẩn xác 100% bằng code toán học"""
        if amount <= 0:
            return {"error": "Số tiền tính toán phải lớn hơn 0."}

        term_years = max(1, round(term_months / 12)) if term_months >= 12 else 1

        if calculation_type == "SAVINGS_COMPOUND":
            rate = annual_rate if annual_rate is not None else rate_config.SAVINGS_RATES[12]
            # Anti-hallucination: kẹp lãi suất về biểu chuẩn SSOT — LLM truyền 6.5%/năm (bịa) → về 6.0%
            legit_rates = set(rate_config.SAVINGS_RATES.values())
            if rate not in legit_rates:
                logger.warning("LLM passed non-standard savings rate %.2f%% — clamped to SSOT table.", rate)
                rate = min(legit_rates, key=lambda r: abs(r - rate))
            calc = calculate_savings_compound(amount, term_years=term_years, rate_annual=rate)
            t_data = calc["target_data"]
            return {
                "calculation_type": "SAVINGS_COMPOUND",
                "principal_amount": amount,
                "fmt_principal_amount": format_vnd(amount),
                "term_months": term_months,
                "term_years": term_years,
                "annual_rate_pct": rate,
                "total_savings_interest": t_data["interest_savings"],
                "fmt_total_savings_interest": t_data["fmt_interest_savings"],
                "final_balance": t_data["total_savings"],
                "fmt_final_balance": t_data["fmt_total_savings"],
                "casa_interest_comparison": t_data["interest_casa"],
                "fmt_casa_interest": t_data["fmt_interest_casa"],
                "extra_profit_vs_wallet": t_data["difference"],
                "fmt_extra_profit": t_data["fmt_difference"],
                "yearly_breakdown": calc["yearly_breakdown"],
                "markdown_growth_table": calc["markdown_table"]
            }
        elif calculation_type == "LOAN_DECLINING":
            monthly_rate = (annual_rate / 12.0) if annual_rate is not None else rate_config.DEFAULT_LOAN_MONTHLY_RATE
            # Kẹp lãi vay vào khoảng chuẩn 1.2% - 1.5%/tháng
            monthly_rate = min(max(monthly_rate, rate_config.LOAN_RATE_MIN_MONTHLY), rate_config.LOAN_RATE_MAX_MONTHLY)
            loan = calculate_loan_amortization(amount, term_months=term_months, rate_monthly=monthly_rate)
            return {
                "calculation_type": "LOAN_DECLINING",
                "loan_amount": amount,
                "fmt_loan_amount": format_vnd(amount),
                "term_months": term_months,
                "monthly_rate_pct": monthly_rate,
                "monthly_principal": loan["monthly_principal"],
                "fmt_monthly_principal": loan["fmt_monthly_principal"],
                "first_month_payment": loan["first_month_payment"],
                "fmt_first_month_payment": loan["fmt_first_month_payment"],
                "last_month_payment": loan["last_month_payment"],
                "fmt_last_month_payment": loan["fmt_last_month_payment"],
                "total_interest": loan["total_interest"],
                "fmt_total_interest": loan["fmt_total_interest"],
                "total_repayment": loan["total_payment"],
                "fmt_total_repayment": loan["fmt_total_payment"]
            }
        elif calculation_type == "SAVINGS_GOAL":
            rate = annual_rate if annual_rate is not None else rate_config.SAVINGS_RATES[36]
            legit_rates = set(rate_config.SAVINGS_RATES.values())
            if rate not in legit_rates:
                rate = min(legit_rates, key=lambda r: abs(r - rate))
            goal = calculate_target_goal_savings(amount, term_months=term_months, rate_annual=rate)
            return {
                "calculation_type": "SAVINGS_GOAL",
                "target_amount": amount,
                "fmt_target_amount": format_vnd(amount),
                "term_months": term_months,
                "monthly_deposit_needed": goal["monthly_deposit"],
                "fmt_monthly_deposit": goal["fmt_monthly_deposit"],
                "total_deposit_by_user": goal["total_deposit"],
                "fmt_total_deposit": goal["fmt_total_deposit"],
                "bank_interest_earned": goal["earned_interest"],
                "fmt_bank_interest_earned": goal["fmt_earned_interest"]
            }
        else:
            return {"error": f"Loại tính toán '{calculation_type}' không được hỗ trợ."}

    def _search_knowledge_base(self, query: str) -> Dict[str, Any]:
        """Tra cứu Hybrid Search trên PostgreSQL pgvector (có lọc domain theo ý định câu hỏi)"""
        if not query:
            return {"results": "Không có từ khóa tìm kiếm."}

        model = self.rag._get_embed_model()
        norm_q = normalize_vietnamese_query(query)
        q_vec = model.encode(f"query: {norm_q}", normalize_embeddings=True).tolist()
        # Thu hẹp không gian tìm kiếm trước, rồi mới tìm: lọc domain như luồng RAG chính
        detected_domain = detect_query_topic(norm_q)
        domain = detected_domain if detected_domain != "GENERAL_ACCOUNT" else None
        combined_context, sources = self.rag._hybrid_search_rrf(norm_q, q_vec, top_k=3, domain=domain)
        if not sources and domain is not None:
            combined_context, sources = self.rag._hybrid_search_rrf(norm_q, q_vec, top_k=3, domain=None)

        return {
            "search_query": query,
            "relevant_documents": combined_context,
            "sources": sources
        }

    def _handoff_to_agent(self, reason: str, summary: str) -> Dict[str, Any]:
        """Tạo chỉ dẫn bàn giao cho chuyên viên tra soát"""
        return {
            "action": "HANDOFF_TO_AGENT",
            "hotline": "1900-SENHONG (1900 736 466)",
            "operating_hours": "24/7 toàn quốc",
            "support_route": "/support/help-center",
            "reason": reason,
            "summary": summary,
            "ticket_guidance": "Quý khách có thể bấm nút bên dưới để gửi phiếu tra soát trực tiếp tới ban chuyên môn."
        }

# ==============================================================================
# 3. BỘ ĐIỀU KHIỂN AGENT RE-ACT (AUTONOMOUS REACT CONTROLLER)
# ==============================================================================

class BankingReActAgent:
    """
    Financial ReAct Agent loop:
    1. Pre-load Context (biết sẵn khách hàng là ai, số dư bao nhiêu)
    2. Viết lại câu truy vấn nếu mơ hồ hoặc phụ thuộc ngữ cảnh
    3. Loop: Suy nghĩ -> Chọn tool -> Nhận kết quả -> Trả lời hoàn chỉnh
    """
    def __init__(self, rag_engine_instance):
        self.rag = rag_engine_instance
        self.tool_executor = BankingToolExecutor(rag_engine_instance)
        self.max_steps = 4

    def build_system_prompt_with_profile(self, user_id: Optional[str]) -> str:
        """Nạp sẵn ngữ cảnh khách hàng để bot không phải hỏi lại những thứ đã biết"""
        profile_summary = self.tool_executor._get_account_summary(user_id)
        rate_table = rate_config.rate_table_text()
        routes_list = ", ".join(sorted(VALID_APP_ROUTES))

        user_info_block = ""
        if profile_summary.get("status") == "AUTHENTICATED":
            user_info_block = f"""
THÔNG TIN KHÁCH HÀNG HIỆN TẠI (ĐÃ ĐƯỢC XÁC THỰC TỪ CORE BANKING):
- Tên khách hàng: **{profile_summary.get('full_name', 'Quý khách')}**
- Số dư ví khả dụng hiện tại: **{profile_summary.get('formatted_balance')}** ({profile_summary.get('balance'):,.0f} VNĐ)
- Cấp độ tài khoản: **{profile_summary.get('kyc_level')}** (Hạn mức giao dịch: {profile_summary.get('daily_transfer_limit')})
- Sản phẩm đang sở hữu: {", ".join(profile_summary.get('active_products', []))}
=> QUY TẮC QUAN TRỌNG: Bạn ĐÃ BIẾT khách có số dư này trong tài khoản. Khi khách hỏi ngắn gọn "tính lãi" hoặc "tôi có tiền gửi tiết kiệm", hãy chủ động sử dụng số dư {profile_summary.get('formatted_balance')} này để hỏi và tư vấn cụ thể!
"""
        else:
            user_info_block = """
THÔNG TIN KHÁCH HÀNG:
- Trạng thái: Khách hàng chưa đăng nhập (Khách vãng lai).
- Nếu khách hỏi về số dư của họ, hãy nhắc khách đăng nhập hoặc sử dụng số vốn giả định phổ biến (50 triệu đồng) để tính toán minh họa.
"""

        prompt = f"""
Bạn là Trợ lý Tài chính AI Thông minh 24/7 của Ngân hàng Số Sen Hồng (Sen Hồng Core Banking).
Bạn là một AGENT CÓ CÔNG CỤ (Autonomous Agent with Tools / Function Calling): Bạn có khả năng tự suy nghĩ, tự gọi công cụ để tra cứu hoặc tính toán số liệu, xem kết quả rồi mới trả lời khách hàng.

{user_info_block}

VAI TRÒ & PHONG CÁCH PHỤC VỤ:
- Xưng hô "em" và gọi khách hàng là "quý khách" lịch sự, chu đáo, chuẩn mực phong cách ngân hàng số cao cấp.
- NGUYÊN TẮC: CHUẨN XÁC, NGẮN GỌN, ĐÚNG TRỌNG TÂM, TUYỆT ĐỐI KHÔNG LAN MAN. Trực diện vào số liệu và giải pháp, không giải thích dông dài.
- Luôn in đậm số liệu tài chính quan trọng bằng cú pháp markdown `**...**` (ví dụ: `**5.6%/năm**`, `**50.000.000 VNĐ**`, `**miễn phí 100%**`).
- CẦU NỐI DẪN HƯỚNG GỢI Ý: Luôn kết thúc bằng câu dẫn hướng khách hàng chọn các gợi ý bên dưới để xem tiếp câu trả lời chi tiết:
  "👉 Quý khách có thể bấm chọn nhanh các gợi ý bên dưới để xem tiếp câu trả lời chi tiết nhé ạ!"

NGUYÊN TẮC HOẠT ĐỘNG VỚI CÔNG CỤ (TOOLS):
1. ĐỘNG CƠ TÍNH TOÁN CHUẨN XÁC (DETERMINISTIC):
   - Tuyệt đối KHÔNG tự tính nhẩm lũy thừa kép hay tính lịch trả nợ trong đầu. BẮT BUỘC gọi tool `calculate_interest` để có số liệu chính xác 100% rồi trích xuất nguyên văn số liệu đó vào câu trả lời.
2. TRA CỨU BIỂU PHÍ & LÃI SUẤT CHÍNH THỨC:
   - Gọi tool `get_interest_rates` để lấy lãi suất mới nhất theo kỳ hạn.
   - Gọi tool `search_knowledge_base` để tra cứu biểu phí, quy định thẻ, cẩm nang tính năng.
3. HỎI LẠI KHI MƠ HỒ:
   - Nếu câu hỏi quá ngắn ("tính lãi", "phí") mà chưa rõ nhu cầu (tiết kiệm, vay, thẻ), hãy lịch sự hỏi lại kèm 2-3 lựa chọn nhanh. Nếu khách đã có số dư ví khả dụng, hãy chủ động gắn số dư đó vào câu gợi ý.
4. BẢO MẬT & PHÂN QUYỀN (BANKING SAFETY):
   - Bạn chỉ có các công cụ ĐỌC và TÍNH TOÁN. Bạn KHÔNG có quyền tự ý chuyển tiền hay trích nợ ví của khách. Mọi thao tác giao dịch tài chính phải hướng dẫn khách tự thực hiện trên ứng dụng kèm mã PIN/OTP xác thực.
5. ANTI-HALLUCINATION SỐ LIỆU (BẮT BUỘC):
   - MỌI lãi suất (%/năm, %/tháng) và phí bạn nêu PHẢI nằm trong biểu chuẩn dưới đây hoặc do tool trả về. TUYỆT ĐỐI KHÔNG bịa con số khác (ví dụ 6.5%/năm là SAI).
   - Nếu tool/ngữ cảnh KHÔNG chứa số liệu cần thiết (hạn mức, phí mới, sản phẩm lạ): trả lời TRUNG THỰC "Sen Hồng chưa có thông tin chính thức về [X]" — TUYỆT ĐỐI KHÔNG suy đoán theo "hạng thẻ phổ biến", "kinh nghiệm ngân hàng chung" hay bảng hạn mức tự chế.
{rate_table}
6. ROUTE ĐIỀU HƯỚNG HỢP LỆ (suggested_action):
   - "route" PHẢI thuộc chính xác một đường dẫn trong danh sách sau: {routes_list}
   - Route ngoài danh sách sẽ bị hệ thống chặn.
7. ĐỊNH DẠNG ĐẦU RA JSON:
   Trả về JSON gồm 3 trường:
   - "answer": Câu trả lời chi tiết, ấm áp, có cấu trúc rõ ràng.
   - "quick_replies": Mảng gồm 2-3 câu hỏi gợi ý liên quan mật thiết (10-45 ký tự) để khách bấm nhanh.
   - "suggested_action": Object điều hướng {{"label": "...", "route": "..."}} nếu có màn hình liên quan trên App, ngược lại null.
"""
        return prompt.strip()

    def run_agent_loop(
        self, 
        user_question: str, 
        history: Optional[List[MessageItem]] = None, 
        user_id: Optional[str] = None
    ) -> ChatResponse:
        """
        Vòng lặp ReAct Agent chính:
        step 1 -> LLM (tools=BANKING_TOOLS) -> tool_calls -> execute -> messages.append -> step 2 -> final answer
        """
        start_time = time.time()
        norm_question = normalize_vietnamese_query(user_question.strip())

        # Anti-hallucination số học: câu hỏi YÊU CẦU TÍNH TOÁN rõ ràng (tính lãi/lãi kép/trả góp/
        # lịch trả nợ) → trả lời bằng động cơ deterministic NGAY LẬP TỨC, không cho LLM tự nhẩm
        # (LLM nhẩm lũy thừa sai đến từng triệu — đã đo được).
        q_low = norm_question.lower()
        if any(k in q_low for k in [
            "tính lãi", "tinh lai", "tính toán lãi", "bao nhiêu lãi", "bao nhieu lai",
            "lãi kép", "lai kep", "trả góp", "tra gop", "lịch trả nợ", "lich tra no",
            "sinh lời", "sinh loi", "tiền lãi", "tien lai", "được bao nhiêu", "duoc bao nhieu"
        ]):
            fin_pre = generate_comprehensive_financial_analysis(
                norm_question,
                user_wallet=self.rag._fetch_user_wallet_balance(user_id) if user_id else None
            )
            if fin_pre:
                logger.info("Deterministic fin-engine BEFORE agent loop for query: '%s'", norm_question)
                fin_resp = self.rag._build_financial_advisory_answer(fin_pre)
                action_item = None
                if fin_resp.get("suggested_action"):
                    action_item = ActionItem(
                        type="NAVIGATE",
                        label=fin_resp["suggested_action"]["label"],
                        route=fin_resp["suggested_action"]["route"]
                    )
                return ChatResponse(
                    answer=sanitize_and_validate_output(fin_resp["answer"], user_question),
                    sources=fin_resp.get("sources", ["Động cơ Tính toán Tài chính Sen Hồng"]),
                    quick_replies=enrich_smart_quick_replies(user_question, fin_resp.get("quick_replies", []), max_items=3, history=history),
                    suggested_action=action_item,
                    latency_ms=round((time.time() - start_time) * 1000, 2)
                )

        system_prompt = self.build_system_prompt_with_profile(user_id)
        messages: List[Dict[str, Any]] = [
            {"role": "system", "content": system_prompt}
        ]

        # Nạp lịch sử hội thoại 4 lượt gần nhất
        if history:
            for item in history[-4:]:
                messages.append({"role": item.role, "content": item.content})

        messages.append({"role": "user", "content": norm_question})

        # Chuẩn bị danh sách client LLM failover
        client_items = list(self.rag.llm_clients.items())
        if not client_items:
            # Fallback nếu không có client
            fallback_res = self.rag._extractive_fallback_answer(None, user_question, history=history)
            return ChatResponse(
                answer=sanitize_and_validate_output(fallback_res["answer"], user_question),
                sources=["Cẩm nang Sen Hồng"],
                quick_replies=fallback_res.get("quick_replies", []),
                suggested_action=None,
                latency_ms=round((time.time() - start_time) * 1000, 2)
            )

        used_sources = set()
        suggested_action_obj = None
        wall_budget_seconds = 12.0  # budget wall-clock: single-pass RAG là 7s, ReAct nhiều bước cần dải rộng hơn

        for step in range(self.max_steps):
            # Bảo vệ độ trễ: vượt budget → dừng vòng lặp, trả về bằng fallback chain phía dưới
            if time.time() - start_time > wall_budget_seconds:
                logger.warning("[AGENT BUDGET] Vượt %.0fs sau %d bước — dừng vòng lặp ReAct.", wall_budget_seconds, step)
                break
            try:
                # Failover luân phiên TOÀN BỘ API key (không còn phụ thuộc 1 client duy nhất)
                key, client = client_items[step % len(client_items)]
                logger.info("[AGENT STEP %d] Gửi yêu cầu tới LLM (key ...%s) với %d tools...",
                            step + 1, str(key)[-4:], len(BANKING_TOOLS))
                try:
                    response = client.chat.completions.create(
                        model="gemini-3.5-flash-lite",
                        messages=messages,
                        tools=BANKING_TOOLS,
                        tool_choice="auto",
                        temperature=0.1,
                        response_format={"type": "json_object"}
                    )
                except Exception as fmt_err:
                    # Một số backend không chấp nhận json_object cùng tool_choice -> thử lại không ép format
                    if "response_format" in str(fmt_err).lower() or "json" in str(fmt_err).lower():
                        logger.warning("[AGENT STEP %d] Backend từ chối json_object với tools, thử lại không ép format.", step + 1)
                        response = client.chat.completions.create(
                            model="gemini-3.5-flash-lite",
                            messages=messages,
                            tools=BANKING_TOOLS,
                            tool_choice="auto",
                            temperature=0.1
                        )
                    else:
                        raise
                choice = response.choices[0]
                message = choice.message

                # Nếu LLM quyết định gọi công cụ
                if message.tool_calls:
                    logger.info("[AGENT STEP %d] LLM generated %d tool call(s): %s", 
                                step + 1, len(message.tool_calls), 
                                [tc.function.name for tc in message.tool_calls])
                    
                    # Thêm phản hồi assistant mang tool_calls vào lịch sử hội thoại
                    messages.append(message.model_dump())

                    for tool_call in message.tool_calls:
                        func_name = tool_call.function.name
                        try:
                            func_args = json.loads(tool_call.function.arguments or "{}")
                        except Exception:
                            func_args = {}

                        logger.info("Executing Tool: %s with args: %s", func_name, func_args)
                        tool_result = self.tool_executor.execute_tool(func_name, func_args, user_id=user_id)

                        # Thu thập nguồn trích dẫn nếu có
                        if func_name == "search_knowledge_base" and "sources" in tool_result:
                            for s in tool_result["sources"]:
                                used_sources.add(str(s))
                        elif func_name == "calculate_interest":
                            used_sources.add("Động cơ Tính toán Tài chính Sen Hồng")
                        elif func_name == "get_interest_rates":
                            used_sources.add("Biểu Lãi Suất Chính Thức Sen Hồng")

                        # Bắt action từ handoff nếu có
                        if func_name == "handoff_to_agent":
                            suggested_action_obj = ActionItem(type="NAVIGATE", label="Hỗ trợ tra soát", route="/support/help-center")

                        # Gửi kết quả tool về cho LLM
                        messages.append({
                            "role": "tool",
                            "tool_call_id": tool_call.id,
                            "content": json.dumps(tool_result, ensure_ascii=False)
                        })

                    # Tiếp tục vòng lặp để LLM đọc kết quả và quyết định tiếp
                    continue

                else:
                    # LLM đã có đủ thông tin và trả lời câu hỏi
                    content = message.content or ""
                    parsed = self.rag._safe_parse_llm_json(content)
                    final_answer = ""
                    quick_replies = []

                    if parsed and isinstance(parsed, dict) and parsed.get("answer"):
                        final_answer = parsed.get("answer", "")
                        quick_replies = parsed.get("quick_replies", [])
                        if parsed.get("suggested_action") and not suggested_action_obj:
                            act = parsed["suggested_action"]
                            if isinstance(act, dict) and act.get("route"):
                                route = str(act.get("route")).strip()
                                # Chặn route không tồn tại trên app (LLM tự bịa) → fallback /more
                                if route not in VALID_APP_ROUTES:
                                    logger.warning("LLM suggested invalid route '%s' -> /more", route)
                                    route = "/more"
                                suggested_action_obj = ActionItem(
                                    type="NAVIGATE",
                                    label=act.get("label", "Xem chi tiết"),
                                    route=route
                                )
                    else:
                        final_answer = content
                        quick_replies = ["Mở sổ tiết kiệm online", "Lãi suất vay Quick Loan", "Biểu phí & Hạn mức"]

                    # Chặn câu trả lời "hứa tra cứu rồi thôi" (dưới 180 ký tự, chỉ loanh quanh
                    # announce) — đẩy LLM trả lời hoàn chỉnh ngay bằng dữ liệu tool đã có.
                    announce_only = (
                        len(final_answer) < 180
                        and any(k in final_answer.lower() for k in [
                            "tra cứu", "tra cuu", "xin chờ", "xin cho", "chờ em",
                            "vui lòng chờ", "đang kiểm tra", "đang tra cứu"
                        ])
                    )
                    if announce_only and step < self.max_steps - 1:
                        logger.info("[AGENT STEP %d] Câu trả lời chỉ announce (%d ký tự) — ép trả lời hoàn chỉnh.", step + 1, len(final_answer))
                        messages.append({"role": "assistant", "content": content})
                        messages.append({
                            "role": "user",
                            "content": ("Kết quả các tool đã có trong hội thoại phía trên. "
                                        "TRẢ LỜI HOÀN CHỈNH NGAY bằng JSON {answer, quick_replies, suggested_action} "
                                        "dựa trên dữ liệu đã tra cứu, KHÔNG nói sẽ tra cứu thêm nữa.")
                        })
                        continue

                    # Fallback action dựa trên từ khóa nếu chưa có
                    if not suggested_action_obj:
                        q_low = user_question.lower()
                        if any(k in q_low for k in ["tiết kiệm", "tiet kiem", "gửi tiền", "gui tien"]):
                            suggested_action_obj = ActionItem(type="NAVIGATE", label="Mở sổ tiết kiệm", route="/bills/savings")
                        elif any(k in q_low for k in ["vay", "quick loan", "vay tiêu dùng"]):
                            suggested_action_obj = ActionItem(type="NAVIGATE", label="Vay nhanh", route="/bills/quick-loan")
                        elif any(k in q_low for k in ["pin", "mã pin", "quên pin"]):
                            suggested_action_obj = ActionItem(type="NAVIGATE", label="Lấy lại mã PIN", route="/auth/forgot-pin")

                    clean_ans = sanitize_and_validate_output(final_answer, user_question)
                    latency = round((time.time() - start_time) * 1000, 2)

                    return ChatResponse(
                        answer=clean_ans,
                        sources=list(used_sources) or ["Ngân Hàng Số Sen Hồng"],
                        quick_replies=enrich_smart_quick_replies(user_question, quick_replies, max_items=3, history=history),
                        suggested_action=suggested_action_obj,
                        latency_ms=latency
                    )

            except Exception as e:
                err_str = str(e)
                # Key lỗi/không hợp lệ: xoay sang key kế tiếp (rotation) thay vì bỏ cả vòng agent
                if any(sig in err_str for sig in ["API key", "401", "403", "UNAUTHENTICATED", "INVALID_ARGUMENT", "PERMISSION_DENIED"]):
                    logger.warning("[AGENT STEP %d] LLM key lỗi (400/401/403) — thử key kế tiếp.", step + 1)
                    continue
                err_detail = getattr(e, "response", None)
                err_body = getattr(err_detail, "text", str(e)) if err_detail else str(e)
                logger.error("[AGENT STEP %d ERROR] %s | Detail: %s. Fallback to extractive answer.", step + 1, e, err_body)
                break

        # Nếu vòng lặp kết thúc mà chưa có câu trả lời từ LLM (ví dụ không có API Key hoặc lỗi mạng)
        # Tự động thực thi Động cơ Tính toán Tài chính Siêu Chuẩn Xác (Deterministic Robo-Advisor Engine)
        fin_analysis = generate_comprehensive_financial_analysis(
            user_question, 
            user_wallet=self.rag._fetch_user_wallet_balance(user_id) if user_id else None
        )
        if fin_analysis:
            logger.info("Executing Deterministic Financial Advisory Engine for query: '%s'", user_question)
            fin_resp = self.rag._build_financial_advisory_answer(fin_analysis)
            action_item = None
            if fin_resp.get("suggested_action"):
                action_item = ActionItem(
                    type="NAVIGATE",
                    label=fin_resp["suggested_action"]["label"],
                    route=fin_resp["suggested_action"]["route"]
                )
            clean_fin_ans = sanitize_and_validate_output(fin_resp["answer"], user_question)
            latency = round((time.time() - start_time) * 1000, 2)
            return ChatResponse(
                answer=clean_fin_ans,
                sources=fin_resp.get("sources", ["Động cơ Tính toán Tài chính Sen Hồng"]),
                quick_replies=enrich_smart_quick_replies(user_question, fin_resp.get("quick_replies", []), max_items=3, history=history),
                suggested_action=action_item,
                latency_ms=latency
            )

        # Truy vấn Hybrid Search RRF trên PostgreSQL pgvector để cung cấp ngữ cảnh tài liệu chuyên sâu
        auto_sources = []
        ctx = None
        try:
            model = self.rag._get_embed_model()
            q_vec = model.encode(f"query: {user_question}", normalize_embeddings=True).tolist()
            ctx, auto_sources = self.rag._hybrid_search_rrf(user_question, q_vec, top_k=4)
        except Exception as err:
            logger.warning("Could not retrieve hybrid context for fallback in agent: %s", err)

        fallback_res = self.rag._extractive_fallback_answer(ctx, user_question, history=history)
        clean_fallback = sanitize_and_validate_output(fallback_res["answer"], user_question)
        latency = round((time.time() - start_time) * 1000, 2)

        final_action = suggested_action_obj
        if not final_action and fallback_res.get("suggested_action"):
            act = fallback_res["suggested_action"]
            if isinstance(act, dict) and act.get("route"):
                final_action = ActionItem(
                    type="NAVIGATE",
                    label=act.get("label", "Xem chi tiết"),
                    route=act.get("route", "/more")
                )

        merged_sources = list(used_sources) or auto_sources or ["Cẩm nang Sen Hồng"]
        return ChatResponse(
            answer=clean_fallback,
            sources=merged_sources,
            quick_replies=enrich_smart_quick_replies(user_question, fallback_res.get("quick_replies", []), max_items=3, history=history),
            suggested_action=final_action,
            latency_ms=latency
        )
