#!/usr/bin/env bash
# ==============================================================================
# AGENT 2 - IDENTITY SERVICE (AUTH, KYC, USERS, RBAC TELLER/MANAGER)
# Script: generate-staff-tokens.sh
# Mục đích: Sinh JWT Access Token test demo (thời hạn 30 phút) cho 3 tài khoản cán bộ:
#   1. teller1:  Teller Nguyễn Văn A (ROLE_TELLER, BR_Q1)
#   2. teller2:  Teller Trần Thị B (ROLE_TELLER, BR_HK)
#   3. manager1: Manager Lê Hoàng C (ROLE_MANAGER, BR_Q1)
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JWT_SECRET="${JWT_SECRET:-SuperSecretKeyForFintechWalletAppShouldBeAtLeast32BytesLong!}"
EXPIRATION_SECONDS="${EXPIRATION_SECONDS:-1800}" # 30 phút = 1800 giây
OUTPUT_ENV="${OUTPUT_ENV:-${SCRIPT_DIR}/.staff_tokens.env}"

echo "======================================================================"
echo "🛡️  [AGENT 2 - IDENTITY SERVICE] STAFF JWT TOKEN GENERATOR"
echo "======================================================================"
echo "• Thời hạn hiệu lực: ${EXPIRATION_SECONDS}s (30 phút)"
echo "• Thuật toán ký:     HS256 (HMAC-SHA256)"
echo "• Token Type:        ACCESS (Tương thích JwtAuthenticationFilter & Identity Service)"
echo "• File xuất env:     ${OUTPUT_ENV}"
echo "======================================================================"
echo ""

# Sinh token qua python3 chuẩn hóa HS256 base64url
python3 - <<EOF
import json
import base64
import hmac
import hashlib
import time
import uuid
import os

secret = """${JWT_SECRET}"""
expiry_seconds = int("""${EXPIRATION_SECONDS}""")
output_file = """${OUTPUT_ENV}"""

now = int(time.time())
exp = now + expiry_seconds

staff_list = [
    {
        "key": "TELLER1",
        "id": "t0000001-0000-0000-0000-000000000001",
        "phone": "0911000001",
        "name": "Teller Nguyễn Văn A",
        "email": "teller1@banking.example.com",
        "role": "ROLE_TELLER",
        "kyc_tier": "VERIFIED",
        "branch_id": "BR_Q1",
        "branch_name": "Chi nhánh Quận 1 (TP.HCM)"
    },
    {
        "key": "TELLER2",
        "id": "t0000002-0000-0000-0000-000000000002",
        "phone": "0911000002",
        "name": "Teller Trần Thị B",
        "email": "teller2@banking.example.com",
        "role": "ROLE_TELLER",
        "kyc_tier": "VERIFIED",
        "branch_id": "BR_HK",
        "branch_name": "Chi nhánh Hoàn Kiếm (Hà Nội)"
    },
    {
        "key": "MANAGER1",
        "id": "m0000001-0000-0000-0000-000000000001",
        "phone": "0911000003",
        "name": "Manager Lê Hoàng C",
        "email": "manager1@banking.example.com",
        "role": "ROLE_MANAGER",
        "kyc_tier": "VERIFIED",
        "branch_id": "BR_Q1",
        "branch_name": "Kiểm soát viên Chi nhánh Quận 1"
    }
]

def base64url_encode(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).decode('utf-8').rstrip('=')

header = {
    "alg": "HS256",
    "typ": "JWT"
}
header_b64 = base64url_encode(json.dumps(header, separators=(',', ':')).encode('utf-8'))

env_lines = [
    f"# Auto-generated staff tokens at {time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(now))}",
    f"# Valid for {expiry_seconds}s (expires at {time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(exp))})\n"
]

for staff in staff_list:
    jti = str(uuid.uuid4())
    payload = {
        "jti": jti,
        "sub": staff["id"],
        "phone": staff["phone"],
        "role": staff["role"],
        "roles": [staff["role"]],
        "kycTier": staff["kyc_tier"],
        "branchId": staff["branch_id"],
        "branch_id": staff["branch_id"],
        "name": staff["name"],
        "full_name": staff["name"],
        "email": staff["email"],
        "type": "ACCESS",
        "iat": now,
        "exp": exp
    }
    
    payload_b64 = base64url_encode(json.dumps(payload, separators=(',', ':')).encode('utf-8'))
    signing_input = f"{header_b64}.{payload_b64}".encode('utf-8')
    sig = hmac.new(secret.encode('utf-8'), signing_input, hashlib.sha256).digest()
    sig_b64 = base64url_encode(sig)
    token = f"{header_b64}.{payload_b64}.{sig_b64}"
    
    env_lines.append(f"export {staff['key']}_TOKEN=\"{token}\"")
    env_lines.append(f"export {staff['key']}_USER_ID=\"{staff['id']}\"")
    env_lines.append(f"export {staff['key']}_PHONE=\"{staff['phone']}\"")
    env_lines.append(f"export {staff['key']}_ROLE=\"{staff['role']}\"")
    env_lines.append(f"export {staff['key']}_BRANCH=\"{staff['branch_id']}\"\n")
    
    print(f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print(f"👤 CÁN BỘ: {staff['name']} ({staff['key']})")
    print(f"   • User ID:   {staff['id']}")
    print(f"   • Số ĐT:     {staff['phone']}")
    print(f"   • Quyền hạn: {staff['role']}")
    print(f"   • Chi nhánh: {staff['branch_id']} - {staff['branch_name']}")
    print(f"   • KYC Tier:  {staff['kyc_tier']}")
    print(f"   • Hiệu lực:  {time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(now))} -> {time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(exp))}")
    print(f"\n🔑 JWT TOKEN (Bearer):\n{token}\n")
    print(f"📋 Header mẫu:")
    print(f"   Authorization: Bearer {token}")
    print()

with open(output_file, 'w', encoding='utf-8') as f:
    f.write("\n".join(env_lines) + "\n")

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print(f"✅ Đã lưu biến môi trường token vào: {output_file}")
print("   Sử dụng nhanh: source " + output_file)
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
EOF

echo ""
echo "🎉 [AGENT 2] Hoàn tất sinh JWT Access Tokens demo cho 3 cán bộ ngân hàng!"
