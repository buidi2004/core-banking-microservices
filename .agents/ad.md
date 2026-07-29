# Implementation Plan - Group 1 (27 Mandatory APIs) & Group 3 (12 Growth APIs)

Add 39 new REST APIs across Group 1 (Mandatory Production Features) and Group 3 (Growth & Super-App Features) to expand the Fintech Wallet system into a complete production-ready backend following Hexagonal Architecture.

## User Review Required

> [!IMPORTANT]
> This plan introduces **39 new endpoints**, bringing total backend APIs from 43 to **82 APIs**.
> All domain entities and ports adhere strictly to **Hexagonal Architecture** (Pure Java domain models, Input Ports, Output Ports, JPA Entities, Mappers, Adapters, Controllers).

> [!NOTE]
> Group 2 (Admin / Back-office - 9 APIs) can be implemented in a subsequent phase if internal management UI is needed.

---

## Proposed Architecture & File Structure

```
com.fintech.wallet
├── domain
│   ├── model               (NotificationInfo, UserProfile, DeviceToken, SupportTicket, TicketMessage, LegalConsent, MerchantOrder, Voucher, ReferralReward, AppFeedback)
│   └── port
│       ├── in              (NotificationUseCase, ProfileUseCase, SecurityUseCase, SupportUseCase, LegalUseCase, WebhookUseCase, MerchantUseCase, PromotionUseCase, ReferralUseCase)
│       └── out             (NotificationPersistencePort, ProfilePersistencePort, SecurityPersistencePort, SupportPersistencePort, LegalPersistencePort, MerchantPersistencePort, PromotionPersistencePort, ReferralPersistencePort)
├── application
│   └── service            (NotificationService, ProfileService, SecurityService, SupportService, LegalService, WebhookService, MerchantService, PromotionService, ReferralService)
├── infrastructure
│   └── persistence
│       ├── entity         (NotificationJpaEntity, DeviceTokenJpaEntity, TicketJpaEntity, TicketMessageJpaEntity, LegalConsentJpaEntity, MerchantJpaEntity, VoucherJpaEntity, ReferralJpaEntity, FeedbackJpaEntity)
│       ├── repository     (SpringDataNotificationRepository, SpringDataTicketRepository, SpringDataVoucherRepository, etc.)
│       ├── mapper         (NotificationMapper, SupportMapper, PromotionMapper, etc.)
│       └── adapter        (NotificationPersistenceAdapter, SupportPersistenceAdapter, PromotionPersistenceAdapter, etc.)
└── presentation
    ├── controller         (NotificationController, ProfileController, SecurityController, SupportController, ConfigLegalController, PartnerWebhookController, MerchantController, PromotionController, ReferralController, FeedbackController)
    └── request / response (DTOs for all 39 new endpoints)
```

---

## Detailed Endpoint Implementation Breakdown

### 🔴 GROUP 1: Mandatory Production APIs (27 APIs)

#### 1. Notification Controller ([NEW] NotificationController.java) - 6 APIs

- `GET /api/v1/notifications`: Paginated notification history for logged-in user.
- `PUT /api/v1/notifications/{id}/read`: Mark notification as read.
- `PUT /api/v1/notifications/read-all`: Mark all notifications as read.
- `POST /api/v1/notifications/devices`: Register FCM device token.
- `DELETE /api/v1/notifications/devices/{deviceId}`: Unregister FCM device token on logout.
- `PUT /api/v1/notifications/settings`: Update user push notification preferences.

#### 2. User Profile Controller ([MODIFY] UserController.java / [NEW] ProfileController.java) - 4 APIs

- `GET /api/v1/users/me`: Get logged-in user profile details (full name, email, dob, avatar, kyc status).
- `PUT /api/v1/users/me`: Update profile info.
- `POST /api/v1/users/me/avatar`: Upload user avatar image URL.
- `GET /api/v1/users/{id}/public-info`: Fetch recipient public name & avatar before transfer to verify recipient identity.

#### 3. Personal Wallet QR & Scan Controller ([NEW] QrController.java) - 2 APIs

- `GET /api/v1/users/me/qrcode`: Generate user's static wallet QR code payload for receiving wallet money.
- `POST /api/v1/payments/qr/scan`: Smart scan endpoint that parses any QR payload and routes to appropriate flow (Wallet Transfer / VietQR / Bill Payment / Merchant Order).

#### 4. Security & Biometrics Controller ([NEW] SecurityController.java) - 5 APIs

- `POST /api/v1/security/biometric/register`: Register biometric (FaceID / Fingerprint) public token.
- `POST /api/v1/security/biometric/verify`: Verify biometric token and issue PIN verification token.
- `GET /api/v1/security/login-history`: Get user login audit history log.
- `POST /api/v1/account/2fa/enable`: Enable Two-Factor Authentication.
- `POST /api/v1/account/2fa/disable`: Disable Two-Factor Authentication.

#### 5. Dispute & Support Controller ([NEW] SupportController.java) - 5 APIs

- `POST /api/v1/support/tickets`: Create transaction dispute ticket.
- `GET /api/v1/support/tickets`: List user's dispute tickets.
- `GET /api/v1/support/tickets/{id}`: Get ticket details and conversation thread.
- `POST /api/v1/support/tickets/{id}/messages`: Reply to support ticket thread.
- `GET /api/v1/support/faq`: Get FAQ list.

#### 6. Config & Legal Controller ([NEW] LegalConfigController.java) - 3 APIs

- `GET /api/v1/config/limits`: Retrieve user's active daily & monthly transaction limits and current usage.
- `GET /api/v1/legal/terms`: Get Terms of Service & Privacy Policy text.
- `POST /api/v1/legal/consent`: Record user legal agreement consent timestamp & IP for compliance audit log.

#### 7. Partner External Webhooks ([NEW] PartnerWebhookController.java) - 2 APIs

- `POST /api/v1/webhooks/napas/callback`: Napas bank account linking / gateway transfer callback.
- `POST /api/v1/webhooks/bank/deposit-notify`: Bank deposit notification webhook when external bank pushes funds to user wallet.

---

### 🟢 GROUP 3: Growth & Super-App APIs (12 APIs)

#### 8. Merchant Payment Gateway Controller ([NEW] MerchantController.java) - 4 APIs

- `POST /api/v1/merchants/register`: Register merchant store account.
- `POST /api/v1/merchants/payment-requests`: Create merchant payment order/checkout link.
- `POST /api/v1/merchants/payments/confirm`: Pay merchant order using wallet balance.
- `POST /api/v1/webhooks/merchants/callback`: Send payment completion callback notification to merchant backend.

#### 9. Voucher & Promotion Controller ([NEW] PromotionController.java) - 4 APIs

- `GET /api/v1/promotions`: List active promotions & available vouchers.
- `POST /api/v1/promotions/redeem`: Redeem voucher code or use reward points.
- `POST /api/v1/promotions/apply`: Validate & apply discount voucher to checkout transaction.
- `GET /api/v1/promotions/my-vouchers`: List user's saved/redeemed vouchers.

#### 10. Referral Program Controller ([NEW] ReferralController.java) - 3 APIs

- `GET /api/v1/referrals/code`: Get user's unique referral code & share link.
- `POST /api/v1/referrals/apply`: Apply referral code upon registration/onboarding.
- `GET /api/v1/referrals/history`: List user's earned referral bonuses and invited friends.

#### 11. Feedback Controller ([NEW] FeedbackController.java) - 1 API

- `POST /api/v1/feedback`: Submit app review rating & feedback comment.

---

## Verification Plan

### Automated Tests

- Run `mvn test` to verify all domain entities, services, and controllers compile cleanly and pass unit tests.

### Manual Verification

- Test registration & device token registration.
- Verify recipient public info lookup `GET /api/v1/users/{id}/public-info`.
- Test smart QR scan router `POST /api/v1/payments/qr/scan`.
- Verify dispute ticket creation & reply message flow.
- Verify merchant payment request and wallet confirmation.
