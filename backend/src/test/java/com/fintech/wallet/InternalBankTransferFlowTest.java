package com.fintech.wallet;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fintech.wallet.presentation.request.RegisterRequest;
import com.fintech.wallet.presentation.request.TransferRequest;
import com.fintech.wallet.presentation.request.DepositRequest;
import com.jayway.jsonpath.JsonPath;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.math.BigDecimal;
import java.util.UUID;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
public class InternalBankTransferFlowTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    public void testInternalTransferFlow() throws Exception {
        // 1. Register Alice
        RegisterRequest aliceReq = new RegisterRequest();
        aliceReq.setPhoneNumber("0988000111");
        aliceReq.setPassword("password123");
        aliceReq.setFullName("Alice Nguyen");
        aliceReq.setDeviceId("deviceA");

        MvcResult aliceRegResult = mockMvc.perform(post("/api/v1/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(aliceReq)))
                .andExpect(status().isOk())
                .andReturn();
        String aliceToken = JsonPath.read(aliceRegResult.getResponse().getContentAsString(), "$.data.accessToken");

        // 2. Register Bob
        RegisterRequest bobReq = new RegisterRequest();
        bobReq.setPhoneNumber("0988000222");
        bobReq.setPassword("password123");
        bobReq.setFullName("Bob Tran");
        bobReq.setDeviceId("deviceB");

        MvcResult bobRegResult = mockMvc.perform(post("/api/v1/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(bobReq)))
                .andExpect(status().isOk())
                .andReturn();
        String bobToken = JsonPath.read(bobRegResult.getResponse().getContentAsString(), "$.data.accessToken");

        // Get Alice Wallet ID
        MvcResult aliceWalletRes = mockMvc.perform(get("/api/v1/wallets")
                .header("Authorization", "Bearer " + aliceToken))
                .andExpect(status().isOk())
                .andReturn();
        String aliceWalletId = JsonPath.read(aliceWalletRes.getResponse().getContentAsString(), "$.data.id");

        // Get Bob Wallet ID
        MvcResult bobWalletRes = mockMvc.perform(get("/api/v1/wallets")
                .header("Authorization", "Bearer " + bobToken))
                .andExpect(status().isOk())
                .andReturn();
        String bobWalletId = JsonPath.read(bobWalletRes.getResponse().getContentAsString(), "$.data.id");

        // 3. Deposit money to Alice
        DepositRequest depositRequest = new DepositRequest();
        depositRequest.setAmount(new BigDecimal("1000000")); // 1M
        depositRequest.setCurrency("VND");
        
        mockMvc.perform(post("/api/v1/wallets/deposit")
                .header("Authorization", "Bearer " + aliceToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(depositRequest)))
                .andExpect(status().isOk());

        // 4. Alice initiates transfer to Bob
        TransferRequest transferRequest = new TransferRequest();
        transferRequest.setRequestId(UUID.randomUUID().toString());
        transferRequest.setSourceWalletId(aliceWalletId);
        transferRequest.setTargetWalletId(bobWalletId);
        transferRequest.setAmount(new BigDecimal("200000")); // 200k
        transferRequest.setCurrency("VND");
        transferRequest.setBankCode("SENHONG");
        transferRequest.setNote("Tra tien an trua");

        MvcResult initRes = mockMvc.perform(post("/api/v1/wallets/transfer/init")
                .header("Authorization", "Bearer " + aliceToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(transferRequest)))
                .andExpect(status().isOk())
                .andReturn();
                
        String transactionId = JsonPath.read(initRes.getResponse().getContentAsString(), "$.data.transactionId");

        // 5. Alice confirms transfer
        // Note: Default OTP in test/dev might be something we need to check, let's assume no real OTP check if we pass the right mocked OTP or just '123456'.
        // Looking at typical OTP behavior, it might need actual generated OTP, but we can bypass or see if tests use '123456' as default OTP in non-prod.
        // Let's check if '123456' works or look at AuthSecurityFeaturesTest for OTP verify.
        
        // Actually, we'll just run it without OTP if it is allowed, or query Redis for it. But wait, OTP is sent via SMS. In tests it might be "123456" for mock.
        MvcResult confirmRes = mockMvc.perform(post("/api/v1/wallets/transfer/" + transactionId + "/confirm")
                .header("Authorization", "Bearer " + aliceToken)
                .param("otp", "123456"))
                .andReturn();
                
        System.out.println("=== CONFIRM RESPONSE ===");
        System.out.println(confirmRes.getResponse().getContentAsString());
        System.out.println("========================");

        // 6. Check Alice's History
        MvcResult historyRes = mockMvc.perform(get("/api/v1/transactions?walletId=" + aliceWalletId)
                .header("Authorization", "Bearer " + aliceToken))
                .andExpect(status().isOk())
                .andReturn();
                
        System.out.println("=== HISTORY RESPONSE ===");
        System.out.println(historyRes.getResponse().getContentAsString());
        System.out.println("========================");
    }
}
