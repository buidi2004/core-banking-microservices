package com.fintech.payment.service;

import com.fintech.payment.domain.entity.Bank;
import com.fintech.payment.domain.entity.BankAccount;
import com.fintech.payment.dto.BankAccountDto;
import com.fintech.payment.dto.LinkBankAccountRequest;
import com.fintech.payment.repository.BankAccountRepository;
import com.fintech.payment.repository.BankRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class BankAccountServiceTest {

    @Mock
    private BankAccountRepository bankAccountRepository;

    @Mock
    private BankRepository bankRepository;

    private BankAccountService bankAccountService;

    private final String userId = UUID.randomUUID().toString();

    @BeforeEach
    void setUp() {
        bankAccountService = new BankAccountService(bankAccountRepository, bankRepository);
    }

    @Test
    @DisplayName("linkBankAccount: Thành công liên kết tài khoản ngân hàng")
    void linkBankAccount_Success() {
        LinkBankAccountRequest request = LinkBankAccountRequest.builder()
                .bankCode("VCB")
                .accountNumber("001100998877")
                .accountHolderName("NGUYEN VAN A")
                .build();

        Bank bank = Bank.builder()
                .id(UUID.randomUUID().toString())
                .code("VCB")
                .name("Ngân hàng TMCP Ngoại Thương Việt Nam")
                .shortName("Vietcombank")
                .bin("970436")
                .logoUrl("https://static.vietqr.io/img/VCB.png")
                .active(true)
                .build();

        when(bankRepository.findByCode("VCB")).thenReturn(Optional.of(bank));
        when(bankAccountRepository.findByUserId(userId)).thenReturn(List.of());
        when(bankAccountRepository.save(any(BankAccount.class))).thenAnswer(invocation -> {
            BankAccount ba = invocation.getArgument(0);
            ba.setId(UUID.randomUUID().toString());
            return ba;
        });

        BankAccountDto result = bankAccountService.linkBankAccount(userId, request);

        assertThat(result).isNotNull();
        assertThat(result.getBankCode()).isEqualTo("VCB");
        assertThat(result.getAccountNumber()).isEqualTo("001100998877");
        assertThat(result.getAccountHolderName()).isEqualTo("NGUYEN VAN A");
        assertThat(result.isDefault()).isTrue(); // first account defaults to true

        verify(bankAccountRepository).save(any(BankAccount.class));
    }

    @Test
    @DisplayName("linkBankAccount: Báo lỗi khi mã ngân hàng không tồn tại")
    void linkBankAccount_BankNotFound_ThrowsException() {
        LinkBankAccountRequest request = LinkBankAccountRequest.builder()
                .bankCode("UNKNOWN")
                .accountNumber("123456789")
                .accountHolderName("NGUYEN VAN A")
                .build();

        when(bankRepository.findByCode("UNKNOWN")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> bankAccountService.linkBankAccount(userId, request))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Ngân hàng không tồn tại");
    }

    @Test
    @DisplayName("getUserBankAccounts: Lấy danh sách tài khoản đã liên kết của người dùng")
    void getUserBankAccounts_Success() {
        String bankId = UUID.randomUUID().toString();
        Bank bank = Bank.builder()
                .id(bankId)
                .code("MB")
                .name("Ngân hàng Quân Đội")
                .shortName("MBBank")
                .bin("970422")
                .active(true)
                .build();

        BankAccount ba = BankAccount.builder()
                .id(UUID.randomUUID().toString())
                .userId(userId)
                .bankId(bankId)
                .accountNumber("999988887777")
                .accountHolderName("NGUYEN VAN A")
                .verified(true)
                .defaultAccount(true)
                .build();

        when(bankAccountRepository.findByUserId(userId)).thenReturn(List.of(ba));
        when(bankRepository.findById(bankId)).thenReturn(Optional.of(bank));

        List<BankAccountDto> list = bankAccountService.getUserBankAccounts(userId);

        assertThat(list).hasSize(1);
        assertThat(list.get(0).getBankCode()).isEqualTo("MB");
        assertThat(list.get(0).getBankName()).isEqualTo("Ngân hàng Quân Đội");
        assertThat(list.get(0).getAccountNumber()).isEqualTo("999988887777");
    }

    @Test
    @DisplayName("unlinkBankAccount: Hủy liên kết thành công")
    void unlinkBankAccount_Success() {
        String accId = UUID.randomUUID().toString();
        BankAccount ba = BankAccount.builder()
                .id(accId)
                .userId(userId)
                .bankId(UUID.randomUUID().toString())
                .accountNumber("12345")
                .accountHolderName("A")
                .build();

        when(bankAccountRepository.findByIdAndUserId(accId, userId)).thenReturn(Optional.of(ba));

        bankAccountService.unlinkBankAccount(userId, accId);

        verify(bankAccountRepository).delete(ba);
    }
}

