package com.fintech.payment.service;

import com.fintech.payment.domain.entity.Beneficiary;
import com.fintech.payment.dto.BeneficiaryDto;
import com.fintech.payment.dto.CreateBeneficiaryRequest;
import com.fintech.payment.repository.BeneficiaryRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
public class BeneficiaryService {

    private final BeneficiaryRepository beneficiaryRepository;

    public BeneficiaryService(BeneficiaryRepository beneficiaryRepository) {
        this.beneficiaryRepository = beneficiaryRepository;
    }

    @Transactional(readOnly = true)
    public List<BeneficiaryDto> getBeneficiaries(String userId) {
        List<Beneficiary> list = beneficiaryRepository.findByUserId(userId);
        return list.stream().map(this::toDto).collect(Collectors.toList());
    }

    @Transactional
    public BeneficiaryDto addBeneficiary(String userId, CreateBeneficiaryRequest request) {
        String name = request.getFullName() != null ? request.getFullName() : request.getName();
        String nickname = request.getNickname() != null ? request.getNickname() : name;

        Beneficiary beneficiary = Beneficiary.builder()
                .userId(userId)
                .beneficiaryUserId(request.getBeneficiaryUserId())
                .beneficiaryWalletId(request.getBeneficiaryWalletId())
                .beneficiaryPhone(request.getPhoneNumber())
                .fullName(name)
                .bankCode(request.getBankCode())
                .accountNumber(request.getAccountNumber())
                .nickname(nickname)
                .build();

        beneficiary = beneficiaryRepository.save(beneficiary);
        log.info("Saved beneficiary {} for user {}", beneficiary.getId(), userId);
        return toDto(beneficiary);
    }

    @Transactional
    public void deleteBeneficiary(String userId, String id) {
        Beneficiary b = beneficiaryRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy người thụ hưởng: " + id));
        if (!userId.equals(b.getUserId())) {
            throw new IllegalArgumentException("Không có quyền xóa người thụ hưởng này");
        }
        beneficiaryRepository.delete(b);
        log.info("Deleted beneficiary {} for user {}", id, userId);
    }

    private BeneficiaryDto toDto(Beneficiary b) {
        return BeneficiaryDto.builder()
                .id(b.getId())
                .name(b.getFullName() != null ? b.getFullName() : b.getNickname())
                .fullName(b.getFullName())
                .nickname(b.getNickname())
                .phoneNumber(b.getBeneficiaryPhone())
                .bankCode(b.getBankCode())
                .accountNumber(b.getAccountNumber())
                .beneficiaryUserId(b.getBeneficiaryUserId())
                .beneficiaryWalletId(b.getBeneficiaryWalletId())
                .createdAt(b.getCreatedAt())
                .build();
    }
}

