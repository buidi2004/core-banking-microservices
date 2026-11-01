#!/usr/bin/env python3
"""Sinh spec Archify cho sơ đồ backend 4 tầng từ inventory.json.

Output:
  docs/architecture/backend-4layer/specs/overview.architecture.json
  docs/architecture/backend-4layer/specs/dependencies.architecture.json
  docs/architecture/backend-4layer/specs/service-<name>.architecture.json
"""
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "docs" / "architecture" / "backend-4layer"
INV = json.loads((BASE / "inventory.json").read_text(encoding="utf-8"))
SPECS = BASE / "specs"

LAYER_LABEL = {
    "presentation": "Tầng 1 · Presentation",
    "application": "Tầng 2 · Application",
    "domain": "Tầng 3 · Domain",
    "infrastructure": "Tầng 4 · Infrastructure",
}

SERVICE_LABEL = {
    "identity-service": "Identity",
    "wallet-service": "Wallet",
    "payment-service": "Payment",
    "ledger-service": "Ledger",
    "notification-service": "Notification",
}


def classes_of(service: str, layer: str) -> list[dict]:
    return [c for c in INV["services"][service] if c["layer"] == layer]


def short(text: str, n: int = 72) -> str:
    text = re.sub(r"\s+", " ", text).strip()
    return text if len(text) <= n else text[: n - 1] + "…"


def layer_summary(service: str, layer: str) -> str:
    items = classes_of(service, layer)
    eps = sum(len(c["endpoints"]) for c in items)
    if layer == "presentation" and eps:
        return f"{len(items)} class · {eps} endpoint"
    methods = sum(len(c["methods"]) for c in items)
    return f"{len(items)} class · {methods} method" if methods else f"{len(items)} class"


def class_line(c: dict) -> str:
    name = c["name"]
    if c["kind"] == "interface":
        ms = ", ".join(c["methods"]) if c["methods"] else "interface"
        return f"{name} (interface): {short(ms, 200)}"
    if c["endpoints"]:
        eps = " · ".join(e.split(" -> ")[0] for e in c["endpoints"])
        return f"{name}: {short(eps, 220)}"
    if c["methods"]:
        return f"{name}: {short(', '.join(c['methods']), 220)}"
    if c["fields"]:
        return f"{name}: {short(', '.join(c['fields']), 220)}"
    return name


def dto_line(service: str, layer: str) -> list[str]:
    items = [c for c in classes_of(service, layer) if ".dto" in c["package"] or c["package"].endswith(".dto")]
    if not items:
        return []
    names = ", ".join(c["name"] for c in items)
    return [f"DTO ({len(items)}): {short(names, 260)}"]


def layer_card(service: str, layer: str, dot: str) -> dict:
    items = [class_line(c) for c in classes_of(service, layer)]
    # DTO gộp 1 dòng, bỏ khỏi danh sách class riêng
    dtos = dto_line(service, layer)
    items = [i for i in items if not any(i.startswith(c["name"] + ":") for c in classes_of(service, layer) if ".dto" in c["package"] or c["package"].endswith(".dto"))]
    items = dtos + items
    if not items:
        items = ["Không có class Java — cấu hình YAML / hạ tầng dùng chung"]
    return {"dot": dot, "title": f"{LAYER_LABEL[layer]} ({len(classes_of(service, layer))} class)", "items": items}


# ---------------------------------------------------------------------------
# Siêu dữ liệu phụ thuộc đã kiểm chứng từ source + application.yml
# ---------------------------------------------------------------------------
META = {
    "identity-service": {
        "title": "Identity Service — 4 tầng (Auth · KYC · OTP · Session)",
        "entry": ("entry", "external", "API Gateway :8080", "Client → /api/v1/auth, /users", "HTTP + JWT"),
        "port": ":8081 · ewallet_identity_db :5433",
        "externals": [
            ("db", "database", "PostgreSQL :5433", "ewallet_identity_db · Flyway V1-V*", "JPA"),
            ("redis", "database", "Redis :6379", "OTP · session · PIN lock", "TTL"),
            ("mq", "messagebus", "RabbitMQ :5672", "user.registered event", "AMQP"),
            ("smtp", "external", "Gmail SMTP", "OTP / reset password", "SMTP"),
        ],
        "edges": [
            ("entry", "entry-presentation", "presentation", "HTTPS · JWT", "emphasis"),
            ("presentation", "presentation-application", "application", "gọi use case", "default"),
            ("application", "application-domain", "domain", "domain model", "default"),
            ("infrastructure", "infra-domain", "domain", "implements port", "default"),
            ("infrastructure", "infra-db", "db", "JPA · Flyway", "default"),
            ("infrastructure", "infra-redis", "redis", "OTP · token", "default"),
            ("infrastructure", "infra-mq", "mq", "user.registered", "dashed"),
            ("application", "app-smtp", "smtp", "OTP email", "dashed"),
        ],
        "notes": [
            "AuthService: register, login, refresh, logout, changePassword, resetPassword",
            "OtpService: sendOtp, verifyOtp (Redis TTL) · EmailService: sendOtpMail",
            "JwtTokenProvider: access/refresh token · SecurityConfig: BCrypt(12) + filter chain",
            "IdentityEventPublisher → RabbitMQ user.registered → Wallet tự tạo ví",
        ],
    },
    "wallet-service": {
        "title": "Wallet Service — 4 tầng (Số dư · gRPC · Pessimistic Lock)",
        "entry": ("entry", "external", "API Gateway + Payment Service", "REST :8082 · gRPC :9090", "REST / gRPC"),
        "port": ":8082 · gRPC :9090 · ewallet_wallet_db :5434",
        "externals": [
            ("db", "database", "PostgreSQL :5434", "ewallet_wallet_db · wallets", "JPA"),
            ("redis", "database", "Redis :6379", "DistributedLockPort", "SETNX"),
            ("kafka", "messagebus", "Kafka :9092", "banking.wallet.balance-changed.v1", "producer"),
            ("mq", "messagebus", "RabbitMQ :5672", "wallet.user.registered.queue", "consumer"),
        ],
        "edges": [
            ("entry", "entry-presentation", "presentation", "REST + gRPC", "emphasis"),
            ("presentation", "presentation-application", "application", "gRPC / REST", "default"),
            ("application", "application-domain", "domain", "Wallet · Money", "default"),
            ("infrastructure", "infra-domain", "domain", "persistence port", "default"),
            ("infrastructure", "infra-db", "db", "FOR UPDATE", "default"),
            ("infrastructure", "infra-redis", "redis", "lock 30s", "default"),
            ("infrastructure", "infra-kafka", "kafka", "balance-changed", "dashed"),
            ("mq", "mq-infra", "infrastructure", "UserRegisteredConsumer", "dashed"),
        ],
        "notes": [
            "Hai đường code song song: WalletInternalGrpcService → WalletGrpcService (legacy, đang chạy) và WalletInternalApplicationService (hexagonal, REST dùng port)",
            "WalletGrpcService: debitWallet, creditWallet, reserveBalance, releaseBalance, checkLimit, getWalletByUserId",
            "Redis idempotency key: wallet:tx:processed:<key> (TTL 24h) + pessimistic lock DB",
            "Mọi biến động số dư → Kafka balance-changed; Ledger/Notification tiêu thụ",
        ],
    },
    "payment-service": {
        "title": "Payment Service — 4 tầng (Saga P2P · Outbox · Maker-Checker)",
        "entry": ("entry", "external", "API Gateway :8080", "18 controller · 59 endpoint", "HTTP + JWT"),
        "port": ":8083 · ewallet_payment_db :5435",
        "externals": [
            ("db", "database", "PostgreSQL :5435", "ewallet_payment_db · outbox_events", "JPA"),
            ("wallet", "external", "Wallet gRPC :9090", "RESERVE / DEBIT / CREDIT", "gRPC"),
            ("mq", "messagebus", "RabbitMQ :5672", "wallet.transaction.events", "transaction.*"),
            ("kafka", "messagebus", "Kafka :9092", "banking.payment.transaction-lifecycle.v1", "producer"),
        ],
        "edges": [
            ("entry", "entry-presentation", "presentation", "HTTPS · JWT", "emphasis"),
            ("presentation", "presentation-application", "application", "saga", "default"),
            ("application", "application-domain", "domain", "entity + rule", "default"),
            ("infrastructure", "infra-domain", "domain", "JPA repo", "default"),
            ("infrastructure", "infra-db", "db", "JPA · Flyway V1-V9", "default"),
            ("infrastructure", "infra-wallet", "wallet", "gRPC (<2ms)", "emphasis"),
            ("infrastructure", "infra-mq", "mq", "outbox relay", "dashed"),
            ("infrastructure", "infra-kafka", "kafka", "lifecycle", "dashed"),
        ],
        "notes": [
            "PaymentSagaOrchestrator: reserveBalance → debitWallet → creditWallet; lỗi bước 3 → releaseBalance/hoàn tiền",
            "OutboxRelay: poll 500ms, batch 50, ghi outbox_events cùng transaction DB rồi phát RabbitMQ + Kafka",
            "MakerCheckerRule + CashDepositController: Maker tạo lệnh, Manager duyệt; hạn mức 50tr tự duyệt, >50tr PENDING_APPROVAL",
            "PinTokenValidator: xác thực X-Pin-Token trước khi transfer",
        ],
    },
    "ledger-service": {
        "title": "Ledger Service — 4 tầng (Double-Entry · Kafka/Rabbit Consumer)",
        "entry": ("entry", "external", "API Gateway + Event Bus", "REST :8084 · Kafka/Rabbit", "HTTP + AMQP"),
        "port": ":8084 · ewallet_ledger_db :5436",
        "externals": [
            ("db", "database", "PostgreSQL :5436", "ewallet_ledger_db · journal/postings", "JPA"),
            ("mq", "messagebus", "RabbitMQ :5672", "ledger.transaction.events", "consumer"),
            ("kafka", "messagebus", "Kafka :9092", "balance-changed + lifecycle", "consumer"),
        ],
        "edges": [
            ("entry", "entry-presentation", "presentation", "REST query", "default"),
            ("presentation", "presentation-application", "application", "LedgerService", "emphasis"),
            ("application", "application-domain", "domain", "JournalEntry · Posting", "default"),
            ("infrastructure", "infra-domain", "domain", "ledger port", "default"),
            ("infrastructure", "infra-db", "db", "append-only", "default"),
            ("mq", "mq-infra", "infrastructure", "transaction", "dashed"),
            ("kafka", "kafka-infra", "infrastructure", "2 topics", "dashed"),
        ],
        "notes": [
            "Bất biến: Σ DEBIT = Σ CREDIT; lệch → LedgerUnbalancedException, chặn toàn bộ transaction",
            "KafkaLedgerEventTranslator: wallet balance-changed + payment lifecycle → JournalEntry + 2 posting",
            "Idempotency: chống duplicate posting giữa RabbitMQ và Kafka (EventIdempotency / unique key)",
            "LedgerController: summary, accounts, balance-check, statement/{walletId}, entries",
        ],
    },
    "notification-service": {
        "title": "Notification Service — 4 tầng (Kafka/Rabbit · WebSocket · FCM)",
        "entry": ("entry", "external", "API Gateway + Mobile", "REST :8085 · STOMP /ws-native", "HTTP / WS"),
        "port": ":8085 · ewallet_notification_db :5437",
        "externals": [
            ("db", "database", "PostgreSQL :5437", "ewallet_notification_db", "JPA"),
            ("mq", "messagebus", "RabbitMQ :5672", "notification.transaction.events", "consumer"),
            ("kafka", "messagebus", "Kafka :9092", "banking.payment.transaction-lifecycle.v1", "consumer"),
            ("fcm", "cloud", "Firebase FCM", "push notification", "HTTPS"),
        ],
        "edges": [
            ("entry", "entry-presentation", "presentation", "REST + STOMP", "emphasis"),
            ("presentation", "presentation-application", "application", "service", "default"),
            ("application", "application-domain", "domain", "entity", "default"),
            ("infrastructure", "infra-domain", "domain", "JPA repo", "default"),
            ("infrastructure", "infra-db", "db", "JPA · Flyway", "default"),
            ("mq", "mq-infra", "infrastructure", "onTransactionEvent", "dashed"),
            ("kafka", "kafka-infra", "infrastructure", "onTransactionEvent", "dashed"),
            ("infrastructure", "infra-fcm", "fcm", "push", "dashed"),
        ],
        "notes": [
            "Hai consumer song song: NotificationConsumer (Rabbit) + NotificationKafkaConsumer (Kafka lifecycle)",
            "NotificationService: lưu Notification + WebSocketNotifier (/topic/notifications) + FcmPushSender",
            "DeviceTokenService: register/unregister token; UserPhoneResolver: tra số điện thoại cho SMS format",
            "PromotionService + SupportService + Voucher: module khuyến mãi / hỗ trợ khách hàng",
        ],
    },
}


def build_service(service: str) -> dict:
    meta = META[service]
    entry_id, entry_type, entry_label, entry_sub, entry_tag = meta["entry"]
    components = [
        {
            "id": entry_id,
            "type": entry_type,
            "label": entry_label,
            "sublabel": entry_sub,
            "tag": entry_tag,
            "row": 1,
            "col": 0,
            "size": [206, 96],
        },
        {
            "id": "presentation",
            "type": "backend",
            "label": "Presentation",
            "sublabel": layer_summary(service, "presentation"),
            "tag": "Controller · DTO · Exception",
            "row": 1,
            "col": 1,
            "size": [206, 96],
        },
        {
            "id": "application",
            "type": "backend",
            "label": "Application",
            "sublabel": layer_summary(service, "application"),
            "tag": "Use case · Saga · Outbox",
            "row": 1,
            "col": 2,
            "size": [206, 96],
        },
        {
            "id": "domain",
            "type": "backend",
            "label": "Domain",
            "sublabel": layer_summary(service, "domain"),
            "tag": "Entity · Port · Rule",
            "row": 1,
            "col": 3,
            "size": [206, 96],
        },
        {
            "id": "infrastructure",
            "type": "backend",
            "label": "Infrastructure",
            "sublabel": layer_summary(service, "infrastructure"),
            "tag": "Adapter · Repository · Consumer",
            "row": 1,
            "col": 4,
            "size": [206, 96],
        },
    ]
    ext_rows = [0, 2, 3, 4]
    for i, (eid, etype, elabel, esub, etag) in enumerate(meta["externals"]):
        components.append(
            {
                "id": eid,
                "type": etype,
                "label": elabel,
                "sublabel": esub,
                "tag": etag,
                "row": ext_rows[i % len(ext_rows)],
                "col": 5,
                "size": [206, 96],
            }
        )
    ext_ids = {e[0] for e in meta["externals"]}
    connections = []
    for frm, cid, to, label, variant in meta["edges"]:
        # Cạnh nối tới hệ thống ngoài: bỏ label để tránh chồng chéo corridor,
        # ngữ nghĩa đã nằm trong sublabel/tag của node ngoài và trong cards.
        touches_external = frm in ext_ids or to in ext_ids
        conn = {"id": cid, "from": frm, "to": to, "variant": variant}
        if not touches_external:
            conn["label"] = label
        connections.append(conn)
    cards = [
        layer_card(service, "presentation", "cyan"),
        layer_card(service, "application", "emerald"),
        layer_card(service, "domain", "violet"),
        layer_card(service, "infrastructure", "amber"),
        {"dot": "rose", "title": "Phụ thuộc & luồng nghiệp vụ", "items": meta["notes"]},
    ]
    return {
        "schema_version": 1,
        "diagram_type": "architecture",
        "meta": {
            "title": meta["title"],
            "quality_profile": "showcase",
            "legend": {"mode": "auto"},
        },
        "layout": {"mode": "grid", "cols": 6, "cellW": 222, "cellH": 100, "gapX": 176, "gapY": 96},
        "components": components,
        "connections": connections,
        "cards": cards,
    }


# ---------------------------------------------------------------------------
# Overview: 5 service × 4 tầng + database-per-service
# ---------------------------------------------------------------------------
def build_overview() -> dict:
    services = ["identity-service", "wallet-service", "payment-service", "ledger-service", "notification-service"]
    components = []
    for row, layer in enumerate(("presentation", "application", "domain", "infrastructure")):
        for col, svc in enumerate(services):
            components.append(
                {
                    "id": f"{svc.split('-')[0]}-{layer}",
                    "type": "backend",
                    "label": SERVICE_LABEL[svc],
                    "sublabel": LAYER_LABEL[layer].split(" · ")[1],
                    "tag": layer_summary(svc, layer),
                    "row": row,
                    "col": col,
                    "size": [206, 96],
                }
            )
    dbs = [
        ("identity", "PostgreSQL :5433", "ewallet_identity_db", "JPA · Flyway"),
        ("wallet", "PostgreSQL :5434", "ewallet_wallet_db", "JPA · Flyway"),
        ("payment", "PostgreSQL :5435", "ewallet_payment_db", "outbox_events"),
        ("ledger", "PostgreSQL :5436", "ewallet_ledger_db", "append-only"),
        ("notification", "PostgreSQL :5437", "ewallet_notification_db", "JPA · Flyway"),
    ]
    for col, (sid, label, sub, tag) in enumerate(dbs):
        components.append(
            {
                "id": f"{sid}-db",
                "type": "database",
                "label": label,
                "sublabel": sub,
                "tag": tag,
                "row": 4,
                "col": col,
                "size": [206, 96],
            }
        )
    connections = []
    for svc in services:
        s = svc.split("-")[0]
        connections += [
            {"id": f"{s}-p-a", "from": f"{s}-presentation", "to": f"{s}-application", "label": "use case", "labelDy": 58},
            {"id": f"{s}-a-d", "from": f"{s}-application", "to": f"{s}-domain", "label": "domain model", "labelDy": 58},
            {"id": f"{s}-i-d", "from": f"{s}-infrastructure", "to": f"{s}-domain", "label": "implements port", "labelDy": -40},
            {"id": f"{s}-to-db", "from": f"{s}-infrastructure", "to": f"{s}-db", "label": "JPA", "labelDy": 58},
        ]
    boundaries = [
        {"kind": "region", "label": "Tầng 1 · Presentation — Controller · DTO · gRPC/REST", "wraps": [f"{s.split('-')[0]}-presentation" for s in services]},
        {"kind": "region", "label": "Tầng 2 · Application — Use case · Saga · Outbox", "wraps": [f"{s.split('-')[0]}-application" for s in services]},
        {"kind": "region", "label": "Tầng 3 · Domain — Entity · Port · Rule", "wraps": [f"{s.split('-')[0]}-domain" for s in services]},
        {"kind": "region", "label": "Tầng 4 · Infrastructure — Adapter · Repository · Consumer", "wraps": [f"{s.split('-')[0]}-infrastructure" for s in services]},
        {"kind": "region", "label": "Database-per-Service — PostgreSQL ×5 (:5433–:5437)", "wraps": [f"{s.split('-')[0]}-db" for s in services]},
    ]
    cards = [
        {"dot": "cyan", "title": "Tầng 1 — Presentation", "items": [f"{SERVICE_LABEL[s]}: {layer_summary(s, 'presentation')}" for s in services]},
        {"dot": "emerald", "title": "Tầng 2 — Application", "items": [f"{SERVICE_LABEL[s]}: {layer_summary(s, 'application')}" for s in services]},
        {"dot": "violet", "title": "Tầng 3 — Domain", "items": [f"{SERVICE_LABEL[s]}: {layer_summary(s, 'domain')}" for s in services]},
        {"dot": "amber", "title": "Tầng 4 — Infrastructure", "items": [f"{SERVICE_LABEL[s]}: {layer_summary(s, 'infrastructure')}" for s in services]},
        {
            "dot": "rose",
            "title": "Phụ thuộc liên service & hạ tầng dùng chung",
            "items": [
                "Payment → Wallet: gRPC :9090 (Reserve / Debit / Credit / Release / CheckLimit)",
                "Payment → RabbitMQ wallet.transaction.events (routing key transaction.*) → Ledger + Notification",
                "Wallet → Kafka banking.wallet.balance-changed.v1 → Ledger + Notification",
                "Payment → Kafka banking.payment.transaction-lifecycle.v1 → Ledger + Notification",
                "Identity → RabbitMQ user.registered → Wallet tự tạo ví",
                "Identity + Wallet + API Gateway → Redis :6379 (OTP, session, JWT blacklist, distributed lock)",
                "Notification → Firebase FCM + STOMP /topic/notifications (WebSocket)",
                "common-library: wallet.proto, KafkaEventEnvelope, topic constants, BaseKafkaProducer",
            ],
        },
        {
            "dot": "slate",
            "title": "Ghi chú đọc sơ đồ",
            "items": [
                "Sơ đồ này chỉ vẽ cạnh tầng → tầng và tầng Infrastructure → database của chính service đó.",
                "Toàn bộ cạnh broker/liên service (fan-out đầy đủ) nằm ở sơ đồ “Bản đồ phụ thuộc”.",
                "Chi tiết từng class + method + endpoint: xem 5 sơ đồ per-service.",
            ],
        },
    ]
    return {
        "schema_version": 1,
        "diagram_type": "architecture",
        "meta": {"title": "Backend Sen Hồng — 4 tầng trên 5 microservices", "quality_profile": "standard", "legend": {"mode": "auto"}},
        "layout": {"mode": "grid", "cols": 5, "cellW": 206, "cellH": 96, "gapX": 176, "gapY": 96},
        "components": components,
        "boundaries": boundaries,
        "connections": connections,
        "cards": cards,
    }


# ---------------------------------------------------------------------------
# Dependencies: deployment / service interaction map
# ---------------------------------------------------------------------------
def build_dependencies() -> dict:
    SVC_X, INFRA_X = 520, 980
    svc_y = {"identity": 40, "wallet": 170, "payment": 300, "ledger": 430, "notification": 560}
    components = [
        {"id": "client", "type": "external", "label": "Clients", "sublabel": "Mobile · Teller Portal", "pos": [40, 300], "size": [150, 64], "tag": "HTTPS"},
        {"id": "gateway", "type": "security", "label": "API Gateway", "sublabel": "JWT · blacklist · rate limit", "brand": "spring", "pos": [240, 300], "size": [150, 64], "tag": ":8080"},
        {"id": "identity", "type": "backend", "label": "Identity", "sublabel": "Auth · KYC · OTP · Session", "pos": [SVC_X, svc_y["identity"]], "size": [150, 64], "tag": ":8081"},
        {"id": "wallet", "type": "backend", "label": "Wallet", "sublabel": "Balance · gRPC · Lock", "pos": [SVC_X, svc_y["wallet"]], "size": [150, 64], "tag": ":8082 / :9090"},
        {"id": "payment", "type": "backend", "label": "Payment", "sublabel": "Saga · Outbox · Cash", "pos": [SVC_X, svc_y["payment"]], "size": [150, 64], "tag": ":8083"},
        {"id": "ledger", "type": "backend", "label": "Ledger", "sublabel": "Double-entry · Consumer", "pos": [SVC_X, svc_y["ledger"]], "size": [150, 64], "tag": ":8084"},
        {"id": "notification", "type": "backend", "label": "Notification", "sublabel": "WS · FCM · SMS", "pos": [SVC_X, svc_y["notification"]], "size": [150, 64], "tag": ":8085"},
        {"id": "redis", "type": "database", "label": "Redis", "sublabel": "lock · blacklist · OTP", "pos": [INFRA_X, 40], "size": [160, 64], "tag": ":6379"},
        {"id": "kafka", "type": "messagebus", "label": "Kafka KRaft", "sublabel": "balance-changed · lifecycle", "pos": [INFRA_X, 170], "size": [160, 64], "tag": ":9092"},
        {"id": "rabbit", "type": "messagebus", "label": "RabbitMQ", "sublabel": "wallet.transaction.events", "pos": [INFRA_X, 300], "size": [160, 64], "tag": ":5672"},
        {"id": "postgres", "type": "database", "label": "PostgreSQL ×5", "sublabel": "database-per-service", "pos": [INFRA_X, 430], "size": [160, 64], "tag": ":5433–:5437"},
        {"id": "fcm", "type": "cloud", "label": "Firebase FCM", "sublabel": "push notification", "pos": [INFRA_X, 560], "size": [150, 64], "tag": "HTTPS"},
    ]
    connections = [
        {"id": "c-g", "from": "client", "to": "gateway", "label": "HTTPS", "variant": "emphasis"},
        {"id": "g-id", "from": "gateway", "to": "identity", "label": "/auth"},
        {"id": "g-wa", "from": "gateway", "to": "wallet", "label": "/wallets"},
        {"id": "g-pa", "from": "gateway", "to": "payment", "label": "/payments", "variant": "emphasis"},
        {"id": "g-le", "from": "gateway", "to": "ledger", "label": "/ledger"},
        {"id": "g-no", "from": "gateway", "to": "notification", "label": "/notify"},
        {"id": "pa-wa", "from": "payment", "to": "wallet", "label": "gRPC :9090", "variant": "emphasis", "fromSide": "top", "toSide": "bottom"},
        {"id": "id-r", "labelDx": 70, "from": "identity", "to": "redis", "label": "OTP · session"},
        {"id": "wa-r", "labelDx": 70, "from": "wallet", "to": "redis", "label": "lock", "variant": "dashed"},
        {"id": "g-r", "from": "gateway", "to": "redis", "label": "blacklist", "variant": "dashed", "fromSide": "top", "toSide": "left"},
        {"id": "wa-k", "labelDx": 70, "from": "wallet", "to": "kafka", "label": "balance-changed", "variant": "dashed"},
        {"id": "pa-k", "from": "payment", "to": "kafka", "label": "lifecycle", "variant": "dashed"},
        {"id": "pa-q", "labelDx": 70, "from": "payment", "to": "rabbit", "label": "transaction.*", "variant": "dashed"},
        {"id": "le-pg", "from": "ledger", "to": "postgres", "label": "JPA"},
        {"id": "no-f", "from": "notification", "to": "fcm", "label": "push", "variant": "dashed"},
        {"id": "id-q", "from": "identity", "to": "rabbit", "label": "user.registered", "variant": "dashed", "fromSide": "right", "toSide": "left"},
        {"id": "q-wa", "from": "rabbit", "to": "wallet", "label": "auto-create", "variant": "dashed", "fromSide": "left", "toSide": "right"},
        {"id": "k-le", "from": "kafka", "to": "ledger", "label": "consume", "variant": "dashed", "fromSide": "left", "toSide": "right"},
        {"id": "k-no", "from": "kafka", "to": "notification", "label": "consume", "variant": "dashed", "fromSide": "bottom", "toSide": "right"},
        {"id": "q-le", "from": "rabbit", "to": "ledger", "label": "consume", "variant": "dashed", "fromSide": "bottom", "toSide": "right"},
        {"id": "q-no", "from": "rabbit", "to": "notification", "label": "consume", "variant": "dashed", "fromSide": "bottom", "toSide": "right"},
    ]
    boundaries = [
        {"kind": "region", "label": "Core Banking — Database-per-Service", "wraps": ["identity", "wallet", "payment", "ledger", "notification", "redis", "kafka", "rabbit", "postgres"]}
    ]
    cards = [
        {"dot": "cyan", "title": "Đồng bộ", "items": ["Client → Gateway :8080 (JWT filter, Redis blacklist, rate limit)", "Payment → Wallet gRPC :9090 (Reserve / Debit / Credit / Release / CheckLimit)"]},
        {"dot": "emerald", "title": "Bất đồng bộ", "items": ["Identity → RabbitMQ user.registered → Wallet auto-create ví", "Payment Outbox Relay → RabbitMQ transaction.* + Kafka lifecycle", "Wallet → Kafka balance-changed", "Ledger + Notification consume cả RabbitMQ và Kafka (at-least-once, idempotent)"]},
        {"dot": "amber", "title": "Lưu trữ & hạ tầng", "items": ["5 PostgreSQL độc lập :5433–:5437, Flyway mỗi service", "Redis: JWT blacklist, OTP TTL, distributed lock", "Firebase FCM cho push, STOMP /topic/notifications cho WebSocket"]},
        {"dot": "slate", "title": "Hợp đồng dữ liệu", "items": ["common-library: wallet.proto (gRPC stubs), KafkaEventEnvelope, topic constants, BaseKafkaProducer", "Mọi event mang eventId → consumer chống trùng (idempotency)"]},
    ]
    return {
        "schema_version": 1,
        "diagram_type": "architecture",
        "meta": {"title": "Backend — Bản đồ phụ thuộc giữa các service & hạ tầng", "quality_profile": "standard", "legend": {"mode": "auto"}},
        "components": components,
        "boundaries": boundaries,
        "connections": connections,
        "cards": cards,
    }


def main() -> None:
    SPECS.mkdir(parents=True, exist_ok=True)
    (SPECS / "overview.architecture.json").write_text(json.dumps(build_overview(), ensure_ascii=False, indent=2), encoding="utf-8")
    (SPECS / "dependencies.architecture.json").write_text(json.dumps(build_dependencies(), ensure_ascii=False, indent=2), encoding="utf-8")
    for service in META:
        spec = build_service(service)
        name = service.replace("-service", "")
        (SPECS / f"service-{name}.architecture.json").write_text(json.dumps(spec, ensure_ascii=False, indent=2), encoding="utf-8")
    print("specs written to", SPECS)


if __name__ == "__main__":
    main()
