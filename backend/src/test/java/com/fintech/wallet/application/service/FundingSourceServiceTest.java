package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.model.FundingSource;
import com.fintech.wallet.domain.model.FundingSourceStatus;
import com.fintech.wallet.domain.model.FundingSourceType;
import com.fintech.wallet.domain.model.User;
import com.fintech.wallet.domain.port.out.FundingSourcePersistencePort;
import com.fintech.wallet.domain.port.out.UserPersistencePort;
import com.fintech.wallet.presentation.request.LinkFundingSourceRequest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class FundingSourceServiceTest {

    @Mock
    private FundingSourcePersistencePort fundingSourcePersistencePort;

    @Mock
    private UserPersistencePort userPersistencePort;

    @InjectMocks
    private FundingSourceService fundingSourceService;

    private User mockUser;

    @BeforeEach
    void setUp() {
        mockUser = User.createNew("0987654321", "hash");
    }

    @Test
    void testLinkFundingSource_Success_StandardCard() {
        when(userPersistencePort.findUserById(mockUser.getId())).thenReturn(Optional.of(mockUser));
        
        LinkFundingSourceRequest req = new LinkFundingSourceRequest(
                FundingSourceType.CREDIT_CARD, "VISA", "4970123456789012", "NGUYEN VAN A", "12/26", "123"
        );

        when(fundingSourcePersistencePort.save(any(FundingSource.class))).thenAnswer(invocation -> invocation.getArgument(0));

        FundingSource saved = fundingSourceService.linkFundingSource(mockUser.getId(), req);

        assertNotNull(saved);
        assertEquals(FundingSourceType.CREDIT_CARD, saved.getType());
        assertEquals("4970 **** **** 9012", saved.getMaskedNumber());
    }

    @Test
    void testLinkFundingSource_Success_BankAccount() {
        when(userPersistencePort.findUserById(mockUser.getId())).thenReturn(Optional.of(mockUser));
        
        LinkFundingSourceRequest req = new LinkFundingSourceRequest(
                FundingSourceType.BANK_ACCOUNT, "VIETCOMBANK", "1012345678", "NGUYEN VAN A", null, null
        );

        when(fundingSourcePersistencePort.save(any(FundingSource.class))).thenAnswer(invocation -> invocation.getArgument(0));

        FundingSource saved = fundingSourceService.linkFundingSource(mockUser.getId(), req);

        assertNotNull(saved);
        assertEquals(FundingSourceType.BANK_ACCOUNT, saved.getType());
        assertEquals("10****78", saved.getMaskedNumber());
    }

    @Test
    void testLinkFundingSource_InvalidNumberLength() {
        when(userPersistencePort.findUserById(mockUser.getId())).thenReturn(Optional.of(mockUser));
        
        LinkFundingSourceRequest req = new LinkFundingSourceRequest(
                FundingSourceType.BANK_ACCOUNT, "VIETCOMBANK", "123", "NGUYEN VAN A", null, null
        );

        assertThrows(IllegalArgumentException.class, () -> fundingSourceService.linkFundingSource(mockUser.getId(), req));
    }

    @Test
    void testUnlinkFundingSource_Success() {
        when(userPersistencePort.findUserById(mockUser.getId())).thenReturn(Optional.of(mockUser));
        
        FundingSource source = FundingSource.create(mockUser.getId(), FundingSourceType.BANK_ACCOUNT, "VCB", "1234567890");
        when(fundingSourcePersistencePort.findById(source.getId())).thenReturn(Optional.of(source));

        fundingSourceService.unlinkFundingSource(mockUser.getId(), source.getId());

        assertEquals(FundingSourceStatus.INACTIVE, source.getStatus());
        verify(fundingSourcePersistencePort, times(1)).save(source);
    }
}
