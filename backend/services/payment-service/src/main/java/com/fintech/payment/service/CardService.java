package com.fintech.payment.service;

import com.fintech.payment.domain.entity.Card;
import com.fintech.payment.dto.*;
import com.fintech.payment.repository.CardRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.security.SecureRandom;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
public class CardService {

    private final CardRepository cardRepository;
    private static final SecureRandom RANDOM = new SecureRandom();

    public CardService(CardRepository cardRepository) {
        this.cardRepository = cardRepository;
    }

    /**
     * Thuật toán Luhn (Mod-10) kiểm tra tính hợp lệ của số thẻ thanh toán
     */
    public static boolean isValidLuhn(String cardNumber) {
        if (cardNumber == null || cardNumber.length() != 16 || !cardNumber.matches("\\d+")) {
            return false;
        }
        int sum = 0;
        boolean alternate = false;
        for (int i = cardNumber.length() - 1; i >= 0; i--) {
            int n = Integer.parseInt(cardNumber.substring(i, i + 1));
            if (alternate) {
                n *= 2;
                if (n > 9) {
                    n = (n % 10) + 1;
                }
            }
            sum += n;
            alternate = !alternate;
        }
        return (sum % 10 == 0);
    }

    /**
     * Thuật toán tạo số thẻ 16 chữ số chuẩn Core Banking theo chuẩn ISO/IEC 7812 và Luhn Mod-10
     */
    public static String generateCardNumber(String prefix) {
        StringBuilder sb = new StringBuilder(prefix);
        int remainingDigits = 15 - prefix.length();
        for (int i = 0; i < remainingDigits; i++) {
            sb.append(RANDOM.nextInt(10));
        }
        // Tính chữ số kiểm tra Luhn (Check digit thứ 16)
        int sum = 0;
        boolean alternate = true;
        for (int i = sb.length() - 1; i >= 0; i--) {
            int n = Character.getNumericValue(sb.charAt(i));
            if (alternate) {
                n *= 2;
                if (n > 9) {
                    n = (n % 10) + 1;
                }
            }
            sum += n;
            alternate = !alternate;
        }
        int checkDigit = (10 - (sum % 10)) % 10;
        sb.append(checkDigit);
        return sb.toString();
    }

    public static String maskCardNumber(String cardNumber) {
        if (cardNumber == null || cardNumber.length() < 4) return "•••• •••• •••• ••••";
        String last4 = cardNumber.substring(cardNumber.length() - 4);
        return "•••• •••• •••• " + last4;
    }

    @Transactional
    public List<CardDto> getUserCards(String userId, String cardHolderName) {
        List<Card> cards = cardRepository.findByUserId(userId);
        if (cards.isEmpty()) {
            cards = createStarterPack(userId, cardHolderName);
        }
        return cards.stream().map(this::toDto).collect(Collectors.toList());
    }

    private List<Card> createStarterPack(String userId, String holderName) {
        String holder = (holderName != null && !holderName.isBlank()) ? holderName.toUpperCase() : "CHỦ THẺ SEN HỒNG";
        String expiry = LocalDate.now().plusYears(5).format(DateTimeFormatter.ofPattern("MM/yy"));

        List<Card> starterList = new ArrayList<>();

        // 1. Thẻ Tín Dụng Sen Hồng Visa Signature
        String creditNum = generateCardNumber("428899");
        starterList.add(Card.builder()
                .userId(userId)
                .cardNumber(creditNum)
                .maskedNumber(maskCardNumber(creditNum))
                .cardHolder(holder)
                .cardType("credit")
                .cardTier("THẺ TÍN DỤNG QUỐC TẾ")
                .scheme("VISA")
                .expiryDate(expiry)
                .cvv(String.format("%03d", RANDOM.nextInt(1000)))
                .creditLimit(new BigDecimal("150000000"))
                .availableLimit(new BigDecimal("112500000"))
                .status("ACTIVE")
                .colorScheme("platinum")
                .physical(true)
                .onlinePayment(true)
                .intlPayment(true)
                .contactless(true)
                .atmWithdraw(true)
                .build());

        // 2. Thẻ Ghi Nợ Sen Hồng Napas Chip
        String debitNum = generateCardNumber("970422");
        starterList.add(Card.builder()
                .userId(userId)
                .cardNumber(debitNum)
                .maskedNumber(maskCardNumber(debitNum))
                .cardHolder(holder)
                .cardType("debit")
                .cardTier("THẺ GHI NỢ NỘI ĐỊA")
                .scheme("NAPAS")
                .expiryDate(expiry)
                .cvv(String.format("%03d", RANDOM.nextInt(1000)))
                .creditLimit(new BigDecimal("100000000"))
                .availableLimit(new BigDecimal("12580000"))
                .status("ACTIVE")
                .colorScheme("napas")
                .physical(false)
                .onlinePayment(true)
                .intlPayment(false)
                .contactless(true)
                .atmWithdraw(true)
                .build());

        // 3. Thẻ Ảo Sen Hồng Virtual eCard
        String virtualNum = generateCardNumber("479100");
        starterList.add(Card.builder()
                .userId(userId)
                .cardNumber(virtualNum)
                .maskedNumber(maskCardNumber(virtualNum))
                .cardHolder(holder)
                .cardType("virtual")
                .cardTier("THẺ ẢO THANH TOÁN ONLINE")
                .scheme("VISA")
                .expiryDate(expiry)
                .cvv(String.format("%03d", RANDOM.nextInt(1000)))
                .creditLimit(new BigDecimal("50000000"))
                .availableLimit(new BigDecimal("50000000"))
                .status("ACTIVE")
                .colorScheme("virtual")
                .physical(false)
                .onlinePayment(true)
                .intlPayment(true)
                .contactless(false)
                .atmWithdraw(false)
                .build());

        return cardRepository.saveAll(starterList);
    }

    @Transactional
    public CardDto issueCard(String userId, String cardHolderName, CardIssueRequest request) {
        String holder = (cardHolderName != null && !cardHolderName.isBlank()) ? cardHolderName.toUpperCase() : "CHỦ THẺ SEN HỒNG";
        String type = request.getType().toLowerCase();

        String prefix;
        String tier;
        String scheme;
        String colorScheme;
        BigDecimal limit;

        switch (type) {
            case "credit" -> {
                prefix = "428899";
                tier = "THẺ TÍN DỤNG QUỐC TẾ";
                scheme = "VISA";
                colorScheme = "platinum";
                limit = new BigDecimal("100000000");
            }
            case "virtual" -> {
                prefix = "479100";
                tier = "THẺ ẢO THANH TOÁN ONLINE";
                scheme = "VISA";
                colorScheme = "virtual";
                limit = new BigDecimal("50000000");
            }
            default -> {
                type = "debit";
                prefix = "970422";
                tier = "THẺ GHI NỢ NỘI ĐỊA";
                scheme = "NAPAS";
                colorScheme = "napas";
                limit = new BigDecimal("100000000");
            }
        }

        String cardNumber = generateCardNumber(prefix);
        String expiry = LocalDate.now().plusYears(5).format(DateTimeFormatter.ofPattern("MM/yy"));
        String cvv = String.format("%03d", RANDOM.nextInt(1000));

        Card card = Card.builder()
                .userId(userId)
                .cardNumber(cardNumber)
                .maskedNumber(maskCardNumber(cardNumber))
                .cardHolder(holder)
                .cardType(type)
                .cardTier(tier)
                .scheme(scheme)
                .expiryDate(expiry)
                .cvv(cvv)
                .creditLimit(limit)
                .availableLimit(limit)
                .status("ACTIVE")
                .colorScheme(colorScheme)
                .physical(Boolean.TRUE.equals(request.getPhysical()))
                .deliveryAddress(request.getDeliveryAddress())
                .onlinePayment(true)
                .intlPayment(!"napas".equals(colorScheme))
                .contactless(true)
                .atmWithdraw(!"virtual".equals(type))
                .build();

        card = cardRepository.save(card);
        log.info("Issued new {} card {} for user {}", type, card.getMaskedNumber(), userId);
        return toDto(card);
    }

    @Transactional
    public CardDto updateCardStatus(String userId, String cardId, CardStatusRequest request) {
        Card card = cardRepository.findByIdAndUserId(cardId, userId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy thẻ với id: " + cardId));
        card.setStatus(request.getStatus().toUpperCase());
        card = cardRepository.save(card);
        log.info("Updated card {} status to {}", cardId, card.getStatus());
        return toDto(card);
    }

    @Transactional
    public CardDto updateCardSettings(String userId, String cardId, CardSettingsRequest request) {
        Card card = cardRepository.findByIdAndUserId(cardId, userId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy thẻ với id: " + cardId));

        if (request.getOnlinePayment() != null) card.setOnlinePayment(request.getOnlinePayment());
        if (request.getIntlPayment() != null) card.setIntlPayment(request.getIntlPayment());
        if (request.getContactless() != null) card.setContactless(request.getContactless());
        if (request.getAtmWithdraw() != null) card.setAtmWithdraw(request.getAtmWithdraw());

        card = cardRepository.save(card);
        log.info("Updated settings for card {}", cardId);
        return toDto(card);
    }

    private CardDto toDto(Card card) {
        String title;
        if ("credit".equalsIgnoreCase(card.getCardType())) {
            title = "SEN HỒNG VISA SIGNATURE";
        } else if ("virtual".equalsIgnoreCase(card.getCardType())) {
            title = "SEN HỒNG VIRTUAL ECARD";
        } else {
            title = "SEN HỒNG NAPAS CHIP";
        }

        return CardDto.builder()
                .id(card.getId())
                .type(card.getCardType())
                .title(title)
                .tier(card.getCardTier())
                .scheme(card.getScheme())
                .number(card.getCardNumber())
                .maskedNumber(card.getMaskedNumber())
                .holder(card.getCardHolder())
                .expiry(card.getExpiryDate())
                .cvv(card.getCvv())
                .limit(card.getCreditLimit())
                .available(card.getAvailableLimit())
                .colorScheme(card.getColorScheme())
                .useAsset("credit".equalsIgnoreCase(card.getCardType()))
                .status(card.getStatus())
                .onlinePayment(Boolean.TRUE.equals(card.getOnlinePayment()))
                .intlPayment(Boolean.TRUE.equals(card.getIntlPayment()))
                .contactless(Boolean.TRUE.equals(card.getContactless()))
                .atmWithdraw(Boolean.TRUE.equals(card.getAtmWithdraw()))
                .physical(Boolean.TRUE.equals(card.getPhysical()))
                .build();
    }
}

