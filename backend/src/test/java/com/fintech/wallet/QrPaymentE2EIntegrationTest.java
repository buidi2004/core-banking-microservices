package com.fintech.wallet;

import com.fintech.wallet.presentation.request.DepositRequest;
import com.fintech.wallet.presentation.request.RegisterRequest;
import com.fintech.wallet.presentation.request.TransferQrRequest;
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
public class QrPaymentE2EIntegrationTest {

    @Autowired
    private TestRestTemplate restTemplate;

    @Autowired
    private RedisTemplate<String, Object> redisTemplate;

    @Test
    public void testQrPaymentFlow() throws Exception {
        // 1. Register User A (Sender)
        String phoneA = "09Q" + (System.currentTimeMillis() % 100000);
        String password = "password123";
        RegisterRequest reqA = new RegisterRequest();
        reqA.setPhoneNumber(phoneA);
        reqA.setPassword(password);

        ResponseEntity<ApiResponse> regResA = restTemplate.postForEntity("/api/v1/auth/register", reqA, ApiResponse.class);
        assertEquals(HttpStatus.CREATED, regResA.getStatusCode());
        Map<String, Object> dataA = (Map<String, Object>) regResA.getBody().getData();
        String tokenA = (String) dataA.get("accessToken");

        // 2. Register User B (Receiver)
        String phoneB = "09R" + (System.currentTimeMillis() % 100000);
        RegisterRequest reqB = new RegisterRequest();
        reqB.setPhoneNumber(phoneB);
        reqB.setPassword(password);

        ResponseEntity<ApiResponse> regResB = restTemplate.postForEntity("/api/v1/auth/register", reqB, ApiResponse.class);
        assertEquals(HttpStatus.CREATED, regResB.getStatusCode());
        Map<String, Object> dataB = (Map<String, Object>) regResB.getBody().getData();
        String tokenB = (String) dataB.get("accessToken");

        // Set up headers
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
        depositReq.setAmount(new BigDecimal("500000")); // 500,000 VND
        depositReq.setCurrency("VND");
        depositReq.setRequestId(UUID.randomUUID().toString());

        HttpEntity<DepositRequest> depositEntity = new HttpEntity<>(depositReq, headersA);
        ResponseEntity<ApiResponse> depositRes = restTemplate.postForEntity("/api/v1/wallets/deposit", depositEntity, ApiResponse.class);
        assertEquals(HttpStatus.OK, depositRes.getStatusCode(), "Deposit should succeed");

        // 5. Generate QR for User B
        HttpEntity<Void> getEntityB = new HttpEntity<>(headersB);
        ResponseEntity<ApiResponse> qrRes = restTemplate.exchange("/api/v1/users/me/qrcode", HttpMethod.GET, getEntityB, ApiResponse.class);
        assertEquals(HttpStatus.OK, qrRes.getStatusCode());
        String qrCodeString = (String) qrRes.getBody().getData();
        assertNotNull(qrCodeString);

        // 6. Initialize QR Transfer from A to B using scanned QR code string
        TransferQrRequest qrReq = new TransferQrRequest();
        qrReq.setRequestId(UUID.randomUUID().toString());
        qrReq.setSourceWalletId(walletIdA);
        qrReq.setQrCode(qrCodeString);
        qrReq.setAmount(new BigDecimal("150000")); // Override amount if QR doesn't have it
        qrReq.setCurrency("VND");

        HttpEntity<TransferQrRequest> transferQrEntity = new HttpEntity<>(qrReq, headersA);
        ResponseEntity<ApiResponse> initRes = restTemplate.postForEntity("/api/v1/wallets/transfer/qr/init", transferQrEntity, ApiResponse.class);
        if (initRes.getStatusCode() != HttpStatus.OK) {
            System.out.println("QR Init Transfer Failed: " + initRes.getBody().getMessage() + " - " + initRes.getBody().getErrorCode());
        }
        assertEquals(HttpStatus.OK, initRes.getStatusCode());
        
        Map<String, Object> transferData = (Map<String, Object>) initRes.getBody().getData();
        String transactionId = (String) transferData.get("transactionId");

        // 7. Confirm Transfer with PIN
        ResponseEntity<ApiResponse> confirmRes = restTemplate.postForEntity("/api/v1/wallets/transfer/" + transactionId + "/confirm?pin=123456", new HttpEntity<>(null, headersA), ApiResponse.class);
        if (confirmRes.getStatusCode() != HttpStatus.OK) {
            System.out.println("QR Confirm Transfer Failed: " + confirmRes.getBody().getMessage() + " - " + confirmRes.getBody().getErrorCode());
        }
        assertEquals(HttpStatus.OK, confirmRes.getStatusCode(), "QR Transfer confirm should succeed");

        // 8. Verify Balances
        HttpEntity<Void> getEntityA = new HttpEntity<>(headersA);
        ResponseEntity<ApiResponse> balanceResA = restTemplate.exchange("/api/v1/wallets/" + walletIdA, HttpMethod.GET, getEntityA, ApiResponse.class);
        Number finalBalanceA = (Number) ((Map<String, Object>) balanceResA.getBody().getData()).get("balance");
        assertTrue(finalBalanceA.doubleValue() <= 350000.0); // 500000 - 150000 - fee

        ResponseEntity<ApiResponse> balanceResB = restTemplate.exchange("/api/v1/wallets/" + walletIdB, HttpMethod.GET, getEntityB, ApiResponse.class);
        Number finalBalanceB = (Number) ((Map<String, Object>) balanceResB.getBody().getData()).get("balance");
        assertEquals(150000.0, finalBalanceB.doubleValue());
    }
}
