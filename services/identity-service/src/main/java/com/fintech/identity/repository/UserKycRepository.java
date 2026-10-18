package com.fintech.identity.repository;

import com.fintech.identity.domain.entity.UserKycEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserKycRepository extends JpaRepository<UserKycEntity, String> {

    List<UserKycEntity> findByUserIdOrderByCreatedAtDesc(String userId);

    Optional<UserKycEntity> findTopByUserIdOrderByCreatedAtDesc(String userId);

    List<UserKycEntity> findByVerificationStatus(String verificationStatus);
}
