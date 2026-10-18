package com.fintech.identity.repository;

import com.fintech.identity.domain.entity.UserEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<UserEntity, String> {

    Optional<UserEntity> findByPhoneNumber(String phoneNumber);

    Optional<UserEntity> findByUsername(String username);

    Optional<UserEntity> findByEmail(String email);

    @Query("SELECT u FROM UserEntity u WHERE " +
           "u.username = :identifier OR " +
           "u.phoneNumber = :identifier OR " +
           "u.email = :identifier OR " +
           "u.email LIKE CONCAT(:identifier, '@%')")
    Optional<UserEntity> findByIdentifier(@Param("identifier") String identifier);

    @Query("SELECT u FROM UserEntity u WHERE UPPER(u.branchId) = UPPER(:branchId) AND " +
           "(u.role IN ('ROLE_TELLER', 'ROLE_MANAGER', 'ROLE_ADMIN') OR u.role NOT IN ('ROLE_USER', 'USER')) " +
           "ORDER BY u.role DESC, u.fullName ASC")
    List<UserEntity> findStaffByBranchId(@Param("branchId") String branchId);

    boolean existsByPhoneNumber(String phoneNumber);

    boolean existsByUsername(String username);

    boolean existsByEmail(String email);
}
