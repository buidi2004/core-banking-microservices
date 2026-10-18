package com.fintech.wallet;

import com.fintech.wallet.presentation.request.DepositRequest;
import com.fintech.wallet.presentation.request.PayBillRequest;
import com.fintech.wallet.presentation.request.RegisterRequest;
import com.fintech.wallet.presentation.response.ApiResponse;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.*;
import org.springframework.test.context.ActiveProfiles;

import java.math.BigDecimal;
import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
public class BillPaymentE2EIntegrationTest {

    @Autowired
    private TestRestTemplate restTemplate;

    @Test
    public void testBillPaymentFlow() throws Exception {
        // 1. Register User
        String phone = "09C" + (System.currentTimeMillis() % 100000);
        String password = "password123";
        RegisterRequest req = new RegisterRequest();
        req.setPhoneNumber(phone);
        req.setPassword(password);
        req.setFullName("Test User");

        ResponseEntity<ApiResponse> regRes = restTemplate.postForEntity("/api/v1/auth/register", req, ApiResponse.class);
        assertEquals(HttpStatus.CREATED, regRes.getStatusCode());
        Map<String, Object> data = (Map<String, Object>) regRes.getBody().getData();
        String token = (String) data.get("accessToken");

        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(token);
        headers.setContentType(MediaType.APPLICATION_JSON);

        // 2. Get Wallet ID
        ResponseEntity<ApiResponse> infoRes = restTemplate.exchange("/api/v1/wallets/recipient-info?phoneNumber=" + phone, HttpMethod.GET, new HttpEntity<>(headers), ApiResponse.class);
        assertEquals(HttpStatus.OK, infoRes.getStatusCode());
        String walletId = (String) ((Map<String, Object>) infoRes.getBody().getData()).get("walletId");

        // 3. Deposit money to wallet
        DepositRequest depositReq = new DepositRequest();
        depositReq.setWalletId(walletId);
        depositReq.setAmount(new BigDecimal("500000")); // 500,000 VND
        depositReq.setCurrency("VND");
        depositReq.setRequestId(UUID.randomUUID().toString());

        HttpEntity<DepositRequest> depositEntity = new HttpEntity<>(depositReq, headers);
        ResponseEntity<ApiResponse> depositRes = restTemplate.postForEntity("/api/v1/wallets/deposit", depositEntity, ApiResponse.class);
        assertEquals(HttpStatus.OK, depositRes.getStatusCode(), "Deposit should succeed");

        // 4. Lookup Bill
        HttpEntity<Void> getEntity = new HttpEntity<>(headers);
        ResponseEntity<ApiResponse> lookupRes = restTemplate.exchange("/api/v1/bills/lookup?type=ELECTRICITY&customerCode=PE123456", HttpMethod.GET, getEntity, ApiResponse.class);
        assertEquals(HttpStatus.OK, lookupRes.getStatusCode());
        
        Map<String, Object> billData = (Map<String, Object>) lookupRes.getBody().getData();
        String billId = (String) billData.get("billId");
        Number billAmount = (Number) billData.get("amount");
        
        assertNotNull(billId);
        assertTrue(billAmount.doubleValue() > 0);

        // 5. Pay Bill
        PayBillRequest payReq = new PayBillRequest();
        payReq.setBillId(billId);
        payReq.setAmount(new BigDecimal(billAmount.toString()));
        payReq.setCurrency("VND");
        payReq.setWalletId(walletId);
        payReq.setRequestId(UUID.randomUUID().toString());

        HttpEntity<PayBillRequest> payEntity = new HttpEntity<>(payReq, headers);
        ResponseEntity<ApiResponse> payRes = restTemplate.postForEntity("/api/v1/bills/pay", payEntity, ApiResponse.class);
        assertEquals(HttpStatus.OK, payRes.getStatusCode(), "Bill payment should succeed");

        // 6. Verify Balance is deducted
        ResponseEntity<ApiResponse> balanceRes = restTemplate.exchange("/api/v1/wallets/" + walletId, HttpMethod.GET, getEntity, ApiResponse.class);
        Number finalBalance = (Number) ((Map<String, Object>) balanceRes.getBody().getData()).get("balance");
        
        // Bill payment fee is flat 2,200 (UNVERIFIED). Plus 50M signup bonus.
        double expectedBalance = 50500000.0 - billAmount.doubleValue() - 2200.0;
        assertEquals(expectedBalance, finalBalance.doubleValue());
    }
}
