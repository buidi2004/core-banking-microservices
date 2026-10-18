-- ============================================================================
-- KẾ HOẠCH 4 GIAI ĐOẠN PHÂN RÃ HỆ THỐNG VÍ ĐIỆN TỬ
-- GIAI ĐOẠN 0: KHỞI TẠO 5 DATABASE ĐỘC LẬP + PHÂN QUYỀN
-- ============================================================================

-- 1. TẠO 5 DATABASE RIÊNG BIỆT
CREATE DATABASE ewallet_identity_db
    WITH OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;

CREATE DATABASE ewallet_wallet_db
    WITH OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;

CREATE DATABASE ewallet_payment_db
    WITH OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;

CREATE DATABASE ewallet_ledger_db
    WITH OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;

CREATE DATABASE ewallet_notification_db
    WITH OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;

-- 2. TẠO USER 'ledger_app_user' CHỈ CÓ QUYỀN SELECT, INSERT TRÊN ewallet_ledger_db
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'ledger_app_user') THEN
        CREATE USER ledger_app_user WITH PASSWORD 'LedgerApp#Secure2025!';
    END IF;
END
$$;

-- CẤP QUYỀN CHO ledger_app_user TRÊN ewallet_ledger_db
\c ewallet_ledger_db

GRANT CONNECT ON DATABASE ewallet_ledger_db TO ledger_app_user;
GRANT USAGE ON SCHEMA public TO ledger_app_user;

-- CHỈ CẤP SELECT VÀ INSERT (Append-Only, cấm UPDATE/DELETE)
GRANT SELECT, INSERT ON ALL TABLES IN SCHEMA public TO ledger_app_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT ON TABLES TO ledger_app_user;

-- TUYỆT ĐỐI REVOKE UPDATE, DELETE ĐỂ BẢO VỆ TÍNH BẤT BIẾN CỦA CHỨNG TỪ KẾ TOÁN
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM ledger_app_user;
GRANT SELECT, INSERT ON ALL TABLES IN SCHEMA public TO ledger_app_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES FROM ledger_app_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT ON TABLES TO ledger_app_user;

-- CẤM ledger_app_user DROP hoặc ALTER TABLE
REVOKE CREATE ON SCHEMA public FROM ledger_app_user;
GRANT CREATE ON SCHEMA public TO ledger_app_user; -- chỉ cho phép DDL của Flyway

-- 3. TẠO USER ĐỘC LẬP CHO CÁC DATABASE CÒN LẠI
-- identity_db_user
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'identity_db_user') THEN
        CREATE USER identity_db_user WITH PASSWORD 'IdentityDb#Secure2025!';
    END IF;
END
$$;

-- wallet_db_user
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'wallet_db_user') THEN
        CREATE USER wallet_db_user WITH PASSWORD 'WalletDb#Secure2025!';
    END IF;
END
$$;

-- payment_db_user
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'payment_db_user') THEN
        CREATE USER payment_db_user WITH PASSWORD 'PaymentDb#Secure2025!';
    END IF;
END
$$;

-- notification_db_user
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'notification_db_user') THEN
        CREATE USER notification_db_user WITH PASSWORD 'NotificationDb#Secure2025!';
    END IF;
END
$$;
