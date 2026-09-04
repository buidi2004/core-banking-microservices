package com.fintech.wallet;

import com.fintech.wallet.presentation.request.DepositRequest;
import com.fintech.wallet.presentation.request.RegisterRequest;
import com.fintech.wallet.presentation.request.TransferRequest;
import com.fintech.wallet.presentation.request.SetPinRequest;
import com.fintech.wallet.presentation.response.ApiResponse;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.*;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.test.context.ActiveProfiles;

import java.math.BigDecimal;
import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
public class WalletE2EIntegrationTest {

    @Autowired
    private TestRestTemplate restTemplate;

    @Autowired
    private RedisTemplate<String, Object> redisTemplate;

    @Test
    public void testWalletDepositAndTransferFlow() throws Exception {
        // 1. Register User A (Sender)
        String phoneA = "09A" + (System.currentTimeMillis() % 100000);
        String password = "password123";
        RegisterRequest reqA = new RegisterRequest();
        reqA.setPhoneNumber(phoneA);
        reqA.setPassword(password);
        reqA.setFullName("User A");

        ResponseEntity<ApiResponse> regResA = restTemplate.postForEntity("/api/v1/auth/register", reqA, ApiResponse.class);
        assertEquals(HttpStatus.CREATED, regResA.getStatusCode());
        Map<String, Object> dataA = (Map<String, Object>) regResA.getBody().getData();
        String tokenA = (String) dataA.get("accessToken");
        String userIdA = (String) dataA.get("userId");

        // 2. Register User B (Receiver)
        String phoneB = "09B" + (System.currentTimeMillis() % 100000);
        RegisterRequest reqB = new RegisterRequest();
        reqB.setPhoneNumber(phoneB);
        reqB.setPassword(password);
        reqB.setFullName("User B");

        ResponseEntity<ApiResponse> regResB = restTemplate.postForEntity("/api/v1/auth/register", reqB, ApiResponse.class);
        assertEquals(HttpStatus.CREATED, regResB.getStatusCode());
        Map<String, Object> dataB = (Map<String, Object>) regResB.getBody().getData();
        String tokenB = (String) dataB.get("accessToken");
        String userIdB = (String) dataB.get("userId");

        // Set up headers for User A
        HttpHeaders headersA = new HttpHeaders();
        headersA.setBearerAuth(tokenA);
        headersA.setContentType(MediaType.APPLICATION_JSON);
        
        HttpHeaders headersB = new HttpHeaders();
        headersB.setBearerAuth(tokenB);
        headersB.setContentType(MediaType.APPLICATION_JSON);

        // 2b. Set PIN for User A
        SetPinRequest pinReq = new SetPinRequest();
        pinReq.setPin("123456");
        ResponseEntity<ApiResponse> setPinRes = restTemplate.postForEntity("/api/v1/users/pin/set", new HttpEntity<>(pinReq, headersA), ApiResponse.class);
        assertEquals(HttpStatus.OK, setPinRes.getStatusCode(), "Set PIN should succeed");

        // 3. Get Wallet IDs via recipient info lookup
        ResponseEntity<ApiResponse> infoResA = restTemplate.exchange("/api/v1/wallets/recipient-info?phoneNumber=" + phoneA, HttpMethod.GET, new HttpEntity<>(headersA), ApiResponse.class);
        assertEquals(HttpStatus.OK, infoResA.getStatusCode());
        String walletIdA = (String) ((Map<String, Object>) infoResA.getBody().getData()).get("walletId");

        ResponseEntity<ApiResponse> infoResB = restTemplate.exchange("/api/v1/wallets/recipient-info?phoneNumber=" + phoneB, HttpMethod.GET, new HttpEntity<>(headersB), ApiResponse.class);
        assertEquals(HttpStatus.OK, infoResB.getStatusCode());
        String walletIdB = (String) ((Map<String, Object>) infoResB.getBody().getData()).get("walletId");

        // 4. Deposit money to User A's wallet
        DepositRequest depositReq = new DepositRequest();
        depositReq.setWalletId(walletIdA);
        depositReq.setAmount(new BigDecimal("1000000")); // 1,000,000 VND
        depositReq.setCurrency("VND");
        depositReq.setRequestId(UUID.randomUUID().toString());

        HttpEntity<DepositRequest> depositEntity = new HttpEntity<>(depositReq, headersA);
        ResponseEntity<ApiResponse> depositRes = restTemplate.postForEntity("/api/v1/wallets/deposit", depositEntity, ApiResponse.class);
        assertEquals(HttpStatus.OK, depositRes.getStatusCode(), "Deposit should succeed");

        // 5. Check User A balance
        HttpEntity<Void> getEntityA = new HttpEntity<>(headersA);
        ResponseEntity<ApiResponse> balanceResA = restTemplate.exchange("/api/v1/wallets/" + walletIdA, HttpMethod.GET, getEntityA, ApiResponse.class);
        assertEquals(HttpStatus.OK, balanceResA.getStatusCode());
        Map<String, Object> walletDataA = (Map<String, Object>) balanceResA.getBody().getData();
        Number balanceA = (Number) walletDataA.get("balance");
        assertEquals(51000000.0, balanceA.doubleValue());

        // 6. Initialize Transfer from A to B
        TransferRequest transferReq = new TransferRequest();
        transferReq.setSourceWalletId(walletIdA);
        transferReq.setTargetWalletId(walletIdB);
        transferReq.setAmount(new BigDecimal("200000")); // 200,000 VND
        transferReq.setCurrency("VND");
        transferReq.setRequestId(UUID.randomUUID().toString());
        transferReq.setBankCode("SENHONG");
        transferReq.setNote("E2E Transfer Test");

        HttpEntity<TransferRequest> transferEntity = new HttpEntity<>(transferReq, headersA);
        ResponseEntity<ApiResponse> initRes = restTemplate.postForEntity("/api/v1/wallets/transfer/init", transferEntity, ApiResponse.class);
        assertEquals(HttpStatus.OK, initRes.getStatusCode());
        Map<String, Object> transferData = (Map<String, Object>) initRes.getBody().getData();
        String transactionId = (String) transferData.get("transactionId");

        // 7. Confirm Transfer with PIN
        ResponseEntity<ApiResponse> confirmRes = restTemplate.postForEntity("/api/v1/wallets/transfer/" + transactionId + "/confirm?pin=123456", new HttpEntity<>(null, headersA), ApiResponse.class);
        if (confirmRes.getStatusCode() != HttpStatus.OK) {
            System.out.println("Confirm Transfer Failed: " + confirmRes.getBody().getMessage() + " - " + confirmRes.getBody().getErrorCode());
        }
        assertEquals(HttpStatus.OK, confirmRes.getStatusCode(), "Transfer confirm should succeed");

        // 8. Check User A balance again
        ResponseEntity<ApiResponse> finalBalanceResA = restTemplate.exchange("/api/v1/wallets/" + walletIdA, HttpMethod.GET, getEntityA, ApiResponse.class);
        Number finalBalanceA = (Number) ((Map<String, Object>) finalBalanceResA.getBody().getData()).get("balance");
        assertTrue(finalBalanceA.doubleValue() <= 50800000.0);

        // 9. Check User B balance
        HttpEntity<Void> getEntityB = new HttpEntity<>(headersB);
        ResponseEntity<ApiResponse> balanceResB = restTemplate.exchange("/api/v1/wallets/" + walletIdB, HttpMethod.GET, getEntityB, ApiResponse.class);
        Number balanceB = (Number) ((Map<String, Object>) balanceResB.getBody().getData()).get("balance");
        assertEquals(50200000.0, balanceB.doubleValue());
    }
}
