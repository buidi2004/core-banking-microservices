package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.model.FundingSource;
import com.fintech.wallet.domain.port.in.FundingSourceUseCase;
import com.fintech.wallet.presentation.request.LinkFundingSourceRequest;
import com.fintech.wallet.presentation.response.ApiResponse;
import com.fintech.wallet.presentation.response.FundingSourceResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/v1/funding-sources")
@Tag(name = "Funding Source", description = "Endpoints for managing bank accounts and credit/debit cards")
public class FundingSourceController {

    private final FundingSourceUseCase fundingSourceUseCase;

    public FundingSourceController(FundingSourceUseCase fundingSourceUseCase) {
        this.fundingSourceUseCase = fundingSourceUseCase;
    }

    @Operation(summary = "Get all funding sources", description = "Returns active linked bank accounts and cards for the current user")
    @GetMapping
    public ResponseEntity<ApiResponse<List<FundingSourceResponse>>> getFundingSources(Authentication auth) {
        String userId = auth.getName();
        List<FundingSource> sources = fundingSourceUseCase.getFundingSources(userId);
        
        List<FundingSourceResponse> response = sources.stream()
                .map(FundingSourceResponse::fromDomain)
                .collect(Collectors.toList());
                
        return ResponseEntity.ok(ApiResponse.success("Danh sách nguồn tiền", response));
    }

    @Operation(summary = "Link a new funding source", description = "Mock linking a bank account or card. Only stores masked numbers.")
    @PostMapping("/link")
    public ResponseEntity<ApiResponse<FundingSourceResponse>> linkFundingSource(
            Authentication auth,
            @Valid @RequestBody LinkFundingSourceRequest request) {
        
        String userId = auth.getName();
        FundingSource source = fundingSourceUseCase.linkFundingSource(userId, request);
        return ResponseEntity.ok(ApiResponse.success("Liên kết thành công", FundingSourceResponse.fromDomain(source)));
    }

    @Operation(summary = "Unlink a funding source", description = "Soft deletes a linked card or bank account")
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> unlinkFundingSource(
            @PathVariable("id") String fundingSourceId,
            Authentication auth) {
        
        String userId = auth.getName();
        fundingSourceUseCase.unlinkFundingSource(userId, fundingSourceId);
        return ResponseEntity.ok(ApiResponse.success("Hủy liên kết thành công", null));
    }
}
