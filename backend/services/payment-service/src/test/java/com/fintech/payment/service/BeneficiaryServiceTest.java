package com.fintech.payment.service;

import com.fintech.payment.domain.entity.Beneficiary;
import com.fintech.payment.dto.BeneficiaryDto;
import com.fintech.payment.dto.CreateBeneficiaryRequest;
import com.fintech.payment.repository.BeneficiaryRepository;
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
class BeneficiaryServiceTest {

    @Mock
    private BeneficiaryRepository beneficiaryRepository;

    private BeneficiaryService beneficiaryService;

    private final String userId = UUID.randomUUID().toString();

    @BeforeEach
    void setUp() {
        beneficiaryService = new BeneficiaryService(beneficiaryRepository);
    }

    @Test
    @DisplayName("getBeneficiaries: Lấy danh bạ người thụ hưởng của người dùng")
    void getBeneficiaries_Success() {
        Beneficiary b = Beneficiary.builder()
                .id(UUID.randomUUID().toString())
                .userId(userId)
                .beneficiaryPhone("0988776655")
                .nickname("Mẹ Yêu")
                .build();

        when(beneficiaryRepository.findByUserId(userId)).thenReturn(List.of(b));

        List<BeneficiaryDto> list = beneficiaryService.getBeneficiaries(userId);

        assertThat(list).hasSize(1);
        assertThat(list.get(0).getNickname()).isEqualTo("Mẹ Yêu");
        assertThat(list.get(0).getPhoneNumber()).isEqualTo("0988776655");
    }

    @Test
    @DisplayName("addBeneficiary: Thêm người thụ hưởng mới vào danh bạ")
    void addBeneficiary_Success() {
        CreateBeneficiaryRequest req = CreateBeneficiaryRequest.builder()
                .phoneNumber("0912345678")
                .name("Trần Văn B")
                .nickname("Bạn Thân")
                .bankCode("VCB")
                .accountNumber("001100223344")
                .build();

        when(beneficiaryRepository.save(any(Beneficiary.class))).thenAnswer(invocation -> {
            Beneficiary b = invocation.getArgument(0);
            b.setId(UUID.randomUUID().toString());
            return b;
        });

        BeneficiaryDto res = beneficiaryService.addBeneficiary(userId, req);

        assertThat(res).isNotNull();
        assertThat(res.getNickname()).isEqualTo("Bạn Thân");
        assertThat(res.getPhoneNumber()).isEqualTo("0912345678");

        verify(beneficiaryRepository).save(any(Beneficiary.class));
    }

    @Test
    @DisplayName("deleteBeneficiary: Xóa người thụ hưởng khỏi danh bạ")
    void deleteBeneficiary_Success() {
        String id = UUID.randomUUID().toString();
        Beneficiary b = Beneficiary.builder().id(id).userId(userId).build();

        when(beneficiaryRepository.findById(id)).thenReturn(Optional.of(b));

        beneficiaryService.deleteBeneficiary(userId, id);

        verify(beneficiaryRepository).delete(b);
    }
}

