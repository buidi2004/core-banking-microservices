package com.fintech.wallet.domain.port.in;

import com.fintech.wallet.domain.model.FundingSource;
import com.fintech.wallet.presentation.request.LinkFundingSourceRequest;
import java.util.List;

public interface FundingSourceUseCase {
    List<FundingSource> getFundingSources(String userId);
    FundingSource linkFundingSource(String userId, LinkFundingSourceRequest request);
    void unlinkFundingSource(String userId, String fundingSourceId);
}
