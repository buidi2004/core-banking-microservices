package com.fintech.payment.service;

import com.fintech.payment.domain.entity.BankAccount;
import com.fintech.payment.domain.entity.Card;
import com.fintech.payment.domain.entity.FundingSource;
import com.fintech.payment.dto.FundingSourceDto;
import com.fintech.payment.repository.BankAccountRepository;
import com.fintech.payment.repository.CardRepository;
import com.fintech.payment.repository.FundingSourceRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Slf4j
@Service
public class FundingSourceService {

    private final FundingSourceRepository fundingSourceRepository;
    private final BankAccountRepository bankAccountRepository;
    private final CardRepository cardRepository;

    public FundingSourceService(FundingSourceRepository fundingSourceRepository,
                                BankAccountRepository bankAccountRepository,
                                CardRepository cardRepository) {
        this.fundingSourceRepository = fundingSourceRepository;
        this.bankAccountRepository = bankAccountRepository;
        this.cardRepository = cardRepository;
    }

    @Transactional(readOnly = true)
    public List<FundingSourceDto> getFundingSources(String userId) {
        List<FundingSourceDto> list = new ArrayList<>();

        // 1. Nguồn tiền mặc định: Ví điện tử Sen Hồng Pay
        list.add(FundingSourceDto.builder()
                .id("FS-WALLET-" + userId)
                .sourceType("WALLET")
                .sourceRefId(userId)
                .title("Ví chính Sen Hồng Pay")
                .subtitle("Tài khoản ví điện tử khả dụng")
                .balanceOrLimit(BigDecimal.ZERO)
                .active(true)
                .priority(1)
                .build());

        // 2. Tài khoản ngân hàng liên kết
        List<BankAccount> bankAccounts = bankAccountRepository.findByUserId(userId);
        int prio = 2;
        for (BankAccount ba : bankAccounts) {
            list.add(FundingSourceDto.builder()
                    .id(ba.getId())
                    .sourceType("LINKED_BANK")
                    .sourceRefId(ba.getId())
                    .title("Tài khoản NH (..." + (ba.getAccountNumber().length() > 4 ? ba.getAccountNumber().substring(ba.getAccountNumber().length() - 4) : ba.getAccountNumber()) + ")")
                    .subtitle(ba.getAccountHolderName())
                    .balanceOrLimit(BigDecimal.ZERO)
                    .active(Boolean.TRUE.equals(ba.getVerified()))
                    .priority(prio++)
                    .build());
        }

        // 3. Thẻ tín dụng / thẻ ghi nợ
        List<Card> cards = cardRepository.findByUserId(userId);
        for (Card card : cards) {
            if ("ACTIVE".equalsIgnoreCase(card.getStatus())) {
                list.add(FundingSourceDto.builder()
                        .id(card.getId())
                        .sourceType("CREDIT".equalsIgnoreCase(card.getCardType()) ? "CREDIT_CARD" : "DEBIT_CARD")
                        .sourceRefId(card.getId())
                        .title(card.getCardTier() + " (" + card.getMaskedNumber() + ")")
                        .subtitle("Hạn mức: " + card.getAvailableLimit())
                        .balanceOrLimit(card.getAvailableLimit())
                        .active(true)
                        .priority(prio++)
                        .build());
            }
        }

        return list;
    }
}

