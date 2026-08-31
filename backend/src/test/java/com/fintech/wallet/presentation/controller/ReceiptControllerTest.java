package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.port.in.GenerateReceiptUseCase;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
public class ReceiptControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private GenerateReceiptUseCase generateReceiptUseCase;

    @Test
    @WithMockUser(username = "user-123")
    void testDownloadReceipt_Success() throws Exception {
        byte[] mockPdf = "%PDF-1.4 mock".getBytes();
        when(generateReceiptUseCase.generateReceiptPdf(eq("tx-1"), eq("user-123"))).thenReturn(mockPdf);

        mockMvc.perform(get("/api/v1/transactions/tx-1/receipt.pdf"))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_PDF))
                .andExpect(header().string("Content-Disposition", "form-data; name=\"inline\"; filename=\"receipt_tx-1.pdf\""))
                .andExpect(content().bytes(mockPdf));
    }

    @Test
    @WithMockUser(username = "user-123")
    void testDownloadReceipt_Unauthorized_Returns400() throws Exception {
        when(generateReceiptUseCase.generateReceiptPdf(eq("tx-1"), eq("user-123")))
                .thenThrow(new IllegalArgumentException("Unauthorized to view this receipt"));

        mockMvc.perform(get("/api/v1/transactions/tx-1/receipt.pdf"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Unauthorized to view this receipt"));
    }
}
