
    create table audit_logs (
        created_at timestamp(6) with time zone not null,
        action varchar(255) not null,
        caller_id varchar(255),
        id varchar(255) not null,
        ip_address varchar(255),
        payload_hash varchar(255),
        primary key (id)
    );

    create table bank_accounts (
        is_default boolean not null,
        created_at timestamp(6) with time zone not null,
        account_holder_name varchar(255) not null,
        account_number varchar(255) not null,
        bank_code varchar(255) not null,
        id varchar(255) not null,
        user_id varchar(255) not null,
        primary key (id)
    );

    create table beneficiaries (
        created_at timestamp(6) with time zone not null,
        account_number varchar(255),
        bank_code varchar(255),
        beneficiary_wallet_id varchar(255),
        id varchar(255) not null,
        nickname varchar(255),
        user_id varchar(255) not null,
        primary key (id)
    );

    create table journal_entries (
        created_at timestamp(6) with time zone not null,
        description varchar(255),
        id varchar(255) not null,
        transaction_id varchar(255),
        primary key (id)
    );

    create table ledger_accounts (
        balance numeric(38,2) not null,
        account_name varchar(255) not null,
        account_type varchar(255) not null,
        currency varchar(255) not null,
        id varchar(255) not null,
        primary key (id)
    );

    create table ledger_postings (
        amount numeric(38,2) not null,
        account_id varchar(255) not null,
        entry_type varchar(255) not null,
        id varchar(255) not null,
        journal_entry_id varchar(255) not null,
        primary key (id)
    );

    create table transactions (
        amount numeric(38,2) not null,
        created_at timestamp(6) with time zone not null,
        currency varchar(255) not null,
        id varchar(255) not null,
        request_id varchar(255),
        source_wallet_id varchar(255),
        status varchar(255) not null,
        target_wallet_id varchar(255),
        type varchar(255) not null,
        primary key (id),
        constraint idx_transaction_request_id unique (request_id)
    );

    create table user_kycs (
        created_at timestamp(6) with time zone not null,
        verified_at timestamp(6) with time zone,
        back_card_url varchar(255),
        dob varchar(255),
        front_card_url varchar(255),
        full_name varchar(255),
        id varchar(255) not null,
        id_card_number varchar(255),
        selfie_url varchar(255),
        status varchar(255) not null,
        user_id varchar(255) not null unique,
        primary key (id)
    );

    create table users (
        created_at timestamp(6) with time zone not null,
        updated_at timestamp(6) with time zone not null,
        id varchar(255) not null,
        kyc_status varchar(255) not null,
        password_hash varchar(255) not null,
        phone_number varchar(255) not null unique,
        pin_hash varchar(255),
        primary key (id)
    );

    create table wallets (
        balance_amount numeric(38,2) not null,
        created_at timestamp(6) with time zone not null,
        updated_at timestamp(6) with time zone not null,
        version bigint,
        currency varchar(255) not null,
        id varchar(255) not null,
        owner_id varchar(255) not null unique,
        primary key (id)
    );
