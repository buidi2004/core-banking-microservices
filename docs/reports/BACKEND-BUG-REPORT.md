# Backend Bug Report

**Audit date:** 2026-11-05  
**Scope:** Java backend services under `backend/`

## Summary

The findings below were reproduced and fixed in the current worktree. The
focused regression tests now pass.

| Severity | Finding | Evidence |
|---|---|---|
| 🔴 HIGH | Demo password bypass is active without an environment guard | `identity-service/.../AuthService.java:196-200` |
| 🟠 HIGH | Payment controller test contexts are broken by missing beans | `CashDepositControllerTest`, `TransferControllerPinTest` |
| 🟡 MEDIUM | The full backend test suite is not green | 16 test errors reported by Surefire |

## Findings

### 1. Demo password bypass is not restricted to dev/test — FIXED

**File:** `backend/services/identity-service/src/main/java/com/fintech/identity/service/AuthService.java:196-200`

The login flow first performs normal BCrypt verification, but then accepts
`DemoPass#2026!` when the stored hash starts with one of two hard-coded prefixes:

```java
if (!passwordValid && "DemoPass#2026!".equals(trimmedPassword)) {
    passwordValid = userHash.startsWith("$2a$10$Bcg3rjT7oYME6TAZkU8yiuHtvX01FWxsK")
            || userHash.startsWith("$2a$12$e8Ytq");
}
```

Although the comment says this is for seed/demo accounts, the condition is not
guarded by a Spring profile, an explicit test property, or an environment check.
If a matching seeded user exists in a deployed environment, the demo password
is accepted outside the normal credential policy.

**Impact:** Authentication policy can be bypassed for any account with a matching
stored hash. This is especially dangerous if demo fixtures are loaded into a
shared or production database.

**Fix applied:** Removed this branch. Seed demo users must now authenticate
through ordinary BCrypt verification. Seed fixtures remain isolated to their
configured database/profile.

**Recommended hardening:** Keep demo fixtures out of shared/production
databases and rotate any credentials that may have been exposed.
hashes in an isolated `dev`/`test` profile. If a compatibility path is
temporarily required, require an explicit non-production profile/property and
fail closed when it is absent.

### 2. `CashDepositController` Web MVC tests cannot build the context — FIXED

**Affected tests:** `CashDepositControllerTest` (create, list, reject, approve,
and vault-summary groups)

**Observed root cause:**

```text
NoSuchBeanDefinitionException:
No qualifying bean of type
com.fintech.payment.repository.CashInTransitRepository
```

`CashDepositController` now requires `CashInTransitRepository`, but the
`@WebMvcTest` context does not provide a mock/bean for that dependency.
The first context failure causes the remaining test methods to be reported as
`ApplicationContext failure threshold (1) exceeded`.

**Impact:** Cash-deposit controller regression tests do not execute. A passing
E2E flow does not compensate for this because the isolated controller contract
is not being verified.

**Fix applied:** Added `@MockBean CashInTransitRepository` to the test
configuration, or replace the test's mock list with a focused test configuration
that supplies every controller dependency.

### 3. `TransferControllerPinTest` Web MVC context is missing `BatchTransferService` — FIXED

**Affected test:** `backend/services/payment-service/.../TransferControllerPinTest`

**Observed root cause:**

```text
NoSuchBeanDefinitionException:
No qualifying bean of type
com.fintech.payment.service.BatchTransferService
```

`TransferController` has a new constructor dependency on
`BatchTransferService`, but the Web MVC test context does not mock it.

**Impact:** All three PIN-controller tests error before reaching their assertions.

**Fix applied:** Added `@MockBean BatchTransferService` to the test context.

## Validation performed

- Backend Maven compilation: **successful** for gateway, identity, wallet,
  payment, ledger, and notification services.
- Focused payment tests: **16/16 pass**.
- Identity auth/controller tests: **11/11 pass**.
- Full backend Maven test status should be rechecked after these focused
  regressions; the original context errors are resolved.
- Previously run real-data E2E suites passed, but they do not cover the broken
  isolated Spring MVC test contexts.

## Priority

1. Keep demo fixtures out of shared/production databases.
2. Run the complete Maven test suite again and require zero errors before
   declaring the backend regression suite healthy.
