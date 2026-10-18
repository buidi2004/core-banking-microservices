package com.fintech.identity.repository;

import com.fintech.identity.domain.entity.UserProfileEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserProfileRepository extends JpaRepository<UserProfileEntity, String> {

    Optional<UserProfileEntity> findByUserId(String userId);

    boolean existsByIdentityCardNumber(String identityCardNumber);
}
