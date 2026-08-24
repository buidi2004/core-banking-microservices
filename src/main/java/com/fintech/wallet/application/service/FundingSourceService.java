package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.model.FundingSource;
import com.fintech.wallet.domain.port.in.FundingSourceUseCase;
import com.fintech.wallet.domain.port.out.FundingSourcePersistencePort;
import com.fintech.wallet.domain.port.out.UserPersistencePort;
import com.fintech.wallet.presentation.request.LinkFundingSourceRequest;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class FundingSourceService implements FundingSourceUseCase {

    private final FundingSourcePersistencePort fundingSourcePersistencePort;
    private final UserPersistencePort userPersistencePort;

    public FundingSourceService(FundingSourcePersistencePort fundingSourcePersistencePort,
                                UserPersistencePort userPersistencePort) {
        this.fundingSourcePersistencePort = fundingSourcePersistencePort;
        this.userPersistencePort = userPersistencePort;
    }

    @Override
    public List<FundingSource> getFundingSources(String userId) {
        // verify user exists
        userPersistencePort.findUserById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        return fundingSourcePersistencePort.findByUserIdAndActive(userId);
    }

    @Override
    public FundingSource linkFundingSource(String userId, LinkFundingSourceRequest request) {
        userPersistencePort.findUserById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        FundingSource fundingSource = FundingSource.create(
                userId,
                request.getType(),
                request.getProvider(),
                request.getNumber()
        );

        return fundingSourcePersistencePort.save(fundingSource);
    }

    @Override
    public void unlinkFundingSource(String userId, String fundingSourceId) {
        userPersistencePort.findUserById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        FundingSource source = fundingSourcePersistencePort.findById(fundingSourceId)
                .orElseThrow(() -> new IllegalArgumentException("Funding source not found"));

        if (!source.getUserId().equals(userId)) {
            throw new IllegalArgumentException("Unauthorized to modify this funding source");
        }

        source.markInactive();
        fundingSourcePersistencePort.save(source);
    }
}
