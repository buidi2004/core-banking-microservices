package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.port.in.GenerateReceiptUseCase;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/transactions")
@Tag(name = "Electronic Receipt", description = "Endpoints for downloading transaction PDF receipts")
public class ReceiptController {

    private final GenerateReceiptUseCase generateReceiptUseCase;

    public ReceiptController(GenerateReceiptUseCase generateReceiptUseCase) {
        this.generateReceiptUseCase = generateReceiptUseCase;
    }

    @Operation(summary = "Download Electronic Receipt (PDF)", description = "Generates and downloads a PDF receipt for a specific transaction")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "PDF receipt generated successfully",
                    content = @Content(mediaType = "application/pdf")),
            @ApiResponse(responseCode = "401", description = "Unauthorized", content = @Content(schema = @Schema(hidden = true))),
            @ApiResponse(responseCode = "403", description = "Forbidden (Not owner)", content = @Content(schema = @Schema(hidden = true))),
            @ApiResponse(responseCode = "404", description = "Transaction not found", content = @Content(schema = @Schema(hidden = true)))
    })
    @GetMapping(value = "/{id}/receipt.pdf", produces = MediaType.APPLICATION_PDF_VALUE)
    public ResponseEntity<byte[]> downloadReceipt(
            @Parameter(description = "Transaction ID", required = true) @PathVariable("id") String transactionId,
            org.springframework.security.core.Authentication auth) {
        
        String userId = auth.getName();
        byte[] pdfBytes = generateReceiptUseCase.generateReceiptPdf(transactionId, userId);

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_PDF);
        headers.setContentDispositionFormData("inline", "receipt_" + transactionId + ".pdf");
        headers.setCacheControl("must-revalidate, post-check=0, pre-check=0");

        return new ResponseEntity<>(pdfBytes, headers, HttpStatus.OK);
    }
}
