package com.fintech.payment.service;

import com.fintech.payment.domain.entity.Card;
import com.fintech.payment.dto.*;
import com.fintech.payment.repository.CardRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class CardServiceTest {

    @Mock
    private CardRepository cardRepository;

    private CardService cardService;

    private final String userId = UUID.randomUUID().toString();

    @BeforeEach
    void setUp() {
        cardService = new CardService(cardRepository);
    }

    @Test
    @DisplayName("Luhn Algorithm: Kiểm tra thuật toán Mod-10 cho số thẻ hợp lệ")
    void luhnValidation_ValidAndInvalidCards() {
        // Test standard valid card numbers
        assertThat(CardService.isValidLuhn("4288990088996687")).isFalse(); // invalid check digit
        // Generate valid Luhn card with prefix 970422
        String validDebit = CardService.generateCardNumber("970422");
        assertThat(validDebit).hasSize(16);
        assertThat(validDebit.startsWith("970422")).isTrue();
        assertThat(CardService.isValidLuhn(validDebit)).isTrue();

        String validCredit = CardService.generateCardNumber("428899");
        assertThat(validCredit).hasSize(16);
        assertThat(validCredit.startsWith("428899")).isTrue();
        assertThat(CardService.isValidLuhn(validCredit)).isTrue();
    }

    @Test
    @DisplayName("getUserCards: Khi user chưa có thẻ, tự động khởi tạo bộ thẻ chuẩn (Visa Signature, Napas Chip, Virtual eCard)")
    void getUserCards_AutoIssuesStarterPackWhenEmpty() {
        when(cardRepository.findByUserId(userId)).thenReturn(List.of());
        when(cardRepository.saveAll(any())).thenAnswer(invocation -> invocation.getArgument(0));

        List<CardDto> cards = cardService.getUserCards(userId, "NGUYEN VAN A");

        assertThat(cards).hasSize(3);
        assertThat(cards).anyMatch(c -> c.getType().equalsIgnoreCase("credit") && c.getScheme().equalsIgnoreCase("VISA"));
        assertThat(cards).anyMatch(c -> c.getType().equalsIgnoreCase("debit") && c.getScheme().equalsIgnoreCase("NAPAS"));
        assertThat(cards).anyMatch(c -> c.getType().equalsIgnoreCase("virtual"));

        verify(cardRepository).saveAll(any());
    }

    @Test
    @DisplayName("issueCard: Phát hành thẻ mới thành công theo yêu cầu")
    void issueCard_Success() {
        CardIssueRequest request = CardIssueRequest.builder()
                .type("DEBIT")
                .physical(true)
                .deliveryAddress("123 Vo Van Tan, Q3, TP HCM")
                .build();

        when(cardRepository.save(any(Card.class))).thenAnswer(invocation -> {
            Card c = invocation.getArgument(0);
            c.setId(UUID.randomUUID().toString());
            return c;
        });

        CardDto result = cardService.issueCard(userId, "TRAN THI B", request);

        assertThat(result).isNotNull();
        assertThat(result.getType()).isEqualTo("debit");
        assertThat(result.getHolder()).isEqualTo("TRAN THI B");
        assertThat(result.getNumber()).hasSize(16);
        assertThat(CardService.isValidLuhn(result.getNumber())).isTrue();
    }

    @Test
    @DisplayName("updateCardStatus: Khóa hoặc mở khóa thẻ")
    void updateCardStatus_Success() {
        String cardId = UUID.randomUUID().toString();
        Card card = Card.builder()
                .id(cardId)
                .userId(userId)
                .status("ACTIVE")
                .cardNumber("9704220012345678")
                .maskedNumber("•••• •••• •••• 5678")
                .cardType("DEBIT")
                .cardTier("THẺ GHI NỢ NỘI ĐỊA")
                .scheme("NAPAS")
                .cardHolder("NGUYEN VAN A")
                .expiryDate("12/29")
                .cvv("123")
                .creditLimit(BigDecimal.ZERO)
                .availableLimit(BigDecimal.ZERO)
                .build();

        when(cardRepository.findByIdAndUserId(cardId, userId)).thenReturn(Optional.of(card));
        when(cardRepository.save(any(Card.class))).thenAnswer(invocation -> invocation.getArgument(0));

        CardDto updated = cardService.updateCardStatus(userId, cardId, CardStatusRequest.builder().status("LOCKED").build());

        assertThat(updated.getStatus()).isEqualTo("LOCKED");
        verify(cardRepository).save(card);
    }

    @Test
    @DisplayName("updateCardSettings: Cập nhật cấu hình bảo mật thanh toán thẻ")
    void updateCardSettings_Success() {
        String cardId = UUID.randomUUID().toString();
        Card card = Card.builder()
                .id(cardId)
                .userId(userId)
                .status("ACTIVE")
                .cardNumber("9704220012345678")
                .maskedNumber("•••• •••• •••• 5678")
                .cardType("DEBIT")
                .cardTier("THẺ GHI NỢ NỘI ĐỊA")
                .scheme("NAPAS")
                .cardHolder("NGUYEN VAN A")
                .expiryDate("12/29")
                .cvv("123")
                .creditLimit(BigDecimal.ZERO)
                .availableLimit(BigDecimal.ZERO)
                .onlinePayment(true)
                .intlPayment(true)
                .contactless(true)
                .atmWithdraw(true)
                .build();

        when(cardRepository.findByIdAndUserId(cardId, userId)).thenReturn(Optional.of(card));
        when(cardRepository.save(any(Card.class))).thenAnswer(invocation -> invocation.getArgument(0));

        CardSettingsRequest settings = CardSettingsRequest.builder()
                .onlinePayment(false)
                .intlPayment(false)
                .contactless(true)
                .atmWithdraw(false)
                .build();

        CardDto updated = cardService.updateCardSettings(userId, cardId, settings);

        assertThat(updated.isOnlinePayment()).isFalse();
        assertThat(updated.isIntlPayment()).isFalse();
        assertThat(updated.isContactless()).isTrue();
        assertThat(updated.isAtmWithdraw()).isFalse();
    }
}

