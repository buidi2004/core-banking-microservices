#!/usr/bin/env python3
"""Trích xuất inventory backend (class / method / endpoint / listener) cho sơ đồ Archify.

Chỉ đọc source trong backend/**/src/main/java, bỏ qua target/.
Output: docs/architecture/backend-4layer/inventory.json
"""
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BACKEND = ROOT / "backend"
OUT = ROOT / "docs" / "architecture" / "backend-4layer" / "inventory.json"

SERVICES = [
    "api-gateway",
    "identity-service",
    "wallet-service",
    "payment-service",
    "ledger-service",
    "notification-service",
    "common-library",
]

# Ưu tiên khớp cụm dài trước. Key là hậu tố package.
LAYER_RULES = {
    "controller": "presentation",
    "presentation": "presentation",
    "dto": "presentation",
    "web": "presentation",
    "grpc": "presentation",          # inbound gRPC server (wallet)
    "domain": "domain",
    "entity": "domain",              # notification-service
    "model": "domain",
    "port": "domain",
    "service": "application",
    "application": "application",
    "saga": "application",
    "outbox": "application",
    "rule": "domain",
    "repository": "infrastructure",
    "security": "infrastructure",
    "messaging": "infrastructure",
    "kafka": "infrastructure",
    "amqp": "infrastructure",
    "config": "infrastructure",
    "infrastructure": "infrastructure",
    "notification": "infrastructure",
    "exception": "domain",
}

TYPE_RE = re.compile(r"\b(class|interface|enum|record)\s+(\w+)")
PKG_RE = re.compile(r"^\s*package\s+([\w.]+)\s*;", re.M)
PUBLIC_METHOD_RE = re.compile(
    r"^\s*public\s+(?:static\s+)?(?:final\s+)?(?:synchronized\s+)?(?:abstract\s+)?"
    r"(?:<[^>{};]+>\s+)?([\w.$]+(?:<[^;{}()]*>)?(?:\[\])?)\s+(\w+)\s*\(",
    re.M,
)
FIELD_RE = re.compile(
    r"^\s*private\s+(?:static\s+)?(?:final\s+)?([\w.$<>\[\], ?]+)\s+(\w+)\s*(?:=|;)",
    re.M,
)
MAPPING_RE = re.compile(r"@(Get|Post|Put|Delete|Patch|Request)Mapping\s*(?:\(([^)]*)\))?", re.S)
LISTENER_RE = re.compile(r"@(RabbitListener|KafkaListener)\s*\(", re.S)

# Giá trị thật của các constant hay dùng trong listener
CONST_HINTS = {
    "AmqpConfig.LEDGER_QUEUE": "ledger.transaction.events",
    "RabbitMqConfig.QUEUE_NOTIFICATION": "notification.transaction.events",
    "KafkaTopicConfig.TOPIC_WALLET_BALANCE_CHANGED": "banking.wallet.balance-changed.v1",
    "KafkaTopicConfig.TOPIC_PAYMENT_TRANSACTION_LIFECYCLE": "banking.payment.transaction-lifecycle.v1",
    "KafkaTopicConstants.TOPIC_WALLET_BALANCE_CHANGED": "banking.wallet.balance-changed.v1",
    "KafkaTopicConstants.TOPIC_PAYMENT_TRANSACTION_LIFECYCLE": "banking.payment.transaction-lifecycle.v1",
}


def layer_for(service: str, tail: str, kind: str, cls: str) -> str:
    if service == "api-gateway":
        return "infrastructure" if cls == "GatewayApplication" else "presentation"
    if service == "common-library":
        return "domain" if tail.startswith("domain") else "infrastructure"
    if kind == "interface" and (cls.endswith("Port") or cls.endswith("Repository")):
        return "domain" if cls.endswith("Port") else "infrastructure"
    if ".infrastructure.web" in f".{tail}" or tail == "infrastructure.web":
        return "presentation"
    if "controller" in tail or tail == "presentation" or tail.startswith("presentation."):
        return "presentation"
    if "dto" in tail:
        return "presentation"
    if "domain" in tail or tail == "entity" or ".entity" in f".{tail}":
        return "domain"
    if tail == "rule" or tail.startswith("rule."):
        return "domain"
    if tail == "grpc" and service == "payment-service":
        return "infrastructure"
    if tail == "grpc" or tail.startswith("grpc."):
        return "presentation"
    if "application.port" in tail:
        return "domain"
    if "application" in tail or tail == "service" or tail.startswith("service.") \
            or "saga" in tail or "outbox" in tail:
        return "application"
    if "infrastructure" in tail:
        return "infrastructure"
    return "infrastructure"


def balanced_args(text: str, start: int) -> tuple[str, int]:
    depth = 1
    i = start
    while i < len(text) and depth:
        if text[i] == "(":
            depth += 1
        elif text[i] == ")":
            depth -= 1
        i += 1
    return text[start : i - 1], i


def extract_methods(text: str, cls: str) -> list[str]:
    methods: list[str] = []
    for m in PUBLIC_METHOD_RE.finditer(text):
        ret, name = m.group(1), m.group(2)
        if name == cls or ret in ("return", "new", "throw", "else"):
            continue
        if name in ("toString", "equals", "hashCode", "builder", "main"):
            continue
        if re.match(r"^(get|set|is)[A-Z]", name):
            continue
        raw, _ = balanced_args(text, m.end())
        params = re.sub(r"@\w+(\([^)]*\))?", "", raw)
        params = re.sub(r"\s+", " ", params).strip()
        if len(params) > 96:
            params = params[:93] + "..."
        methods.append(f"{name}({params})")
    return methods


def extract_fields(text: str) -> list[str]:
    out = []
    for m in FIELD_RE.finditer(text):
        typ, name = m.group(1).strip(), m.group(2)
        if name == "serialVersionUID":
            continue
        typ = re.sub(r"\s+", " ", typ)
        out.append(f"{name}: {typ}")
    return out


def extract_endpoints(text: str, base: str) -> list[str]:
    body = text[text.find("{"):] if "{" in text else text
    out = []
    for m in MAPPING_RE.finditer(body):
        verb = m.group(1).upper()
        args, end = m.group(2) or "", m.end()
        path = ""
        pm = re.search(r'"([^"]*)"', args)
        if pm:
            path = pm.group(1)
        tail = body[end : end + 900]
        mm = re.search(r"public\s+[\w<>\[\],.?\s]+\s+(\w+)\s*\(", tail)
        method = mm.group(1) if mm else "?"
        if method == "?":
            continue
        if verb == "REQUEST":
            v = re.search(r"RequestMethod\.(\w+)", args)
            verb = v.group(1) if v else "ANY"
        if not path:
            full = base or "/"
        else:
            full = (base.rstrip("/") + "/" + path.lstrip("/")).replace("//", "/")
        out.append(f"{verb} {full or '/'} -> {method}")
    return out


def extract_listeners(text: str) -> list[str]:
    out = []
    for m in LISTENER_RE.finditer(text):
        kind = m.group(1)
        args, end = balanced_args(text, m.end())
        tail = text[end : end + 1200]
        mm = re.search(r"public\s+[\w<>\[\],.?\s]+\s+(\w+)\s*\(", tail)
        method = mm.group(1) if mm else "?"
        dest = ""
        for pat in (r'queues\s*=\s*"([^"]+)"', r'topics\s*=\s*"([^"]+)"'):
            dm = re.search(pat, args, re.S)
            if dm:
                dest = dm.group(1)
                break
        if not dest:
            cm = re.search(r"(?:queues|topics)\s*=\s*\{?\s*([\w.]+)", args)
            if cm:
                dest = CONST_HINTS.get(cm.group(1), cm.group(1))
            else:
                bm = re.search(r'@Queue\(value\s*=\s*"([^"]+)"', args)
                dest = bm.group(1) if bm else "?"
        out.append(f"{kind} {dest} -> {method}")
    return out


def listener_meta(text: str) -> list[dict]:
    """Queue/topic + exchange/routing key cho consumer."""
    out = []
    for m in LISTENER_RE.finditer(text):
        kind = m.group(1)
        args, end = balanced_args(text, m.end())
        tail = text[end : end + 1200]
        mm = re.search(r"public\s+[\w<>\[\],.?\s]+\s+(\w+)\s*\(", tail)
        method = mm.group(1) if mm else "?"
        info = {"kind": kind, "method": method}
        for key in ("queues", "topics", "exchange", "routingKey", "routing_key"):
            dm = re.search(rf'{key}\s*=\s*"([^"]+)"', args, re.S)
            if dm:
                info[key] = dm.group(1)
        if "queues" not in info:
            cm = re.search(r"queues\s*=\s*\{?\s*([\w.]+)", args)
            if cm:
                info["queues"] = CONST_HINTS.get(cm.group(1), cm.group(1))
        if "topics" not in info:
            cm = re.search(r"topics\s*=\s*\{?\s*([\w.]+)", args)
            if cm:
                info["topics"] = CONST_HINTS.get(cm.group(1), cm.group(1))
        if "queues" not in info and "topics" not in info:
            bm = re.search(r'@Queue\(value\s*=\s*"([^"]+)"', args)
            if bm:
                info["queues"] = bm.group(1)
        out.append(info)
    return out


def main() -> None:
    inv = {"services": {}}
    for svc in SERVICES:
        svc_root = BACKEND / "services" / svc if svc != "common-library" else BACKEND / "common-library"
        src = svc_root / "src" / "main" / "java"
        classes = []
        if not src.exists():
            continue
        for path in sorted(src.rglob("*.java")):
            text = path.read_text(encoding="utf-8", errors="ignore")
            tm = TYPE_RE.search(text)
            if not tm:
                continue
            kind, cls = tm.group(1), tm.group(2)
            pkg = PKG_RE.search(text)
            pkg_name = pkg.group(1) if pkg else ""
            tail = pkg_name.split("com.fintech.")[-1] if "com.fintech." in pkg_name else pkg_name
            prefix = svc.replace("-service", "")
            if svc == "common-library":
                tail = tail.replace("wallet.", "", 1)
            elif tail.startswith(prefix + "."):
                tail = tail[len(prefix) + 1 :]
            layer = layer_for(svc, tail, kind, cls)
            base = ""
            bm = re.search(r'@RequestMapping\s*\(\s*(?:value\s*=\s*)?"([^"]*)"', text)
            if bm:
                base = bm.group(1)
            endpoints = []
            if any(k in pkg_name.lower() for k in ("controller", ".web", "presentation")):
                endpoints = extract_endpoints(text, base)
            classes.append(
                {
                    "name": cls,
                    "kind": kind,
                    "package": pkg_name,
                    "layer": layer,
                    "path": str(path.relative_to(ROOT)),
                    "methods": extract_methods(text, cls),
                    "fields": extract_fields(text) if layer == "domain" else [],
                    "endpoints": endpoints,
                    "listeners": extract_listeners(text),
                    "listener_meta": listener_meta(text),
                }
            )
        inv["services"][svc] = classes

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(inv, ensure_ascii=False, indent=2), encoding="utf-8")
    for svc, classes in inv["services"].items():
        by_layer: dict[str, int] = {}
        for c in classes:
            by_layer[c["layer"]] = by_layer.get(c["layer"], 0) + 1
        print(f"{svc:24} {len(classes):3}  {by_layer}")


if __name__ == "__main__":
    main()
