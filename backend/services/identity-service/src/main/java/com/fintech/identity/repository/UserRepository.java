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

    Optional<UserEntity> findByAccountAlias(String accountAlias);

    @Query("SELECT u FROM UserEntity u WHERE " +
           "LOWER(u.username) = LOWER(:identifier) OR " +
           "LOWER(u.accountAlias) = LOWER(:identifier) OR " +
           "u.phoneNumber = :identifier OR " +
           "LOWER(u.email) = LOWER(:identifier) OR " +
           "LOWER(u.email) LIKE LOWER(CONCAT(:identifier, '@%'))")
    Optional<UserEntity> findByIdentifier(@Param("identifier") String identifier);

    @Query("SELECT u FROM UserEntity u WHERE UPPER(u.branchId) = UPPER(:branchId) AND " +
           "(u.role IN ('ROLE_TELLER', 'ROLE_MANAGER', 'ROLE_ADMIN') OR u.role NOT IN ('ROLE_USER', 'USER')) " +
           "ORDER BY u.role DESC, u.fullName ASC")
    List<UserEntity> findStaffByBranchId(@Param("branchId") String branchId);

    @Query("SELECT u FROM UserEntity u WHERE " +
           "(u.role IN ('ROLE_TELLER', 'ROLE_MANAGER', 'ROLE_ADMIN', 'TELLER', 'MANAGER', 'ADMIN') OR u.role NOT IN ('ROLE_USER', 'USER')) " +
           "ORDER BY u.branchId ASC, u.role DESC, u.fullName ASC")
    List<UserEntity> findAllStaff();

    // Tham số đã chuẩn hoá chữ hoa ở tầng service; không dùng UPPER()/CONCAT() trên
    // tham số nullable vì PostgreSQL JDBC bind null thành bytea -> "upper(bytea)" không tồn tại.
    @Query("SELECT u FROM UserEntity u WHERE " +
           "(:branchId IS NULL OR UPPER(u.branchId) = :branchId) AND " +
           "(:role IS NULL OR UPPER(u.role) = :role OR UPPER(u.role) = :roleWithPrefix) AND " +
           "(:status IS NULL OR UPPER(u.status) = :status) AND " +
           "(u.role IN ('ROLE_TELLER', 'ROLE_MANAGER', 'ROLE_ADMIN', 'TELLER', 'MANAGER', 'ADMIN') OR u.role NOT IN ('ROLE_USER', 'USER')) " +
           "ORDER BY u.branchId ASC, u.role DESC, u.fullName ASC")
    List<UserEntity> findStaffFiltered(@Param("branchId") String branchId,
                                       @Param("role") String role,
                                       @Param("roleWithPrefix") String roleWithPrefix,
                                       @Param("status") String status);

    boolean existsByPhoneNumber(String phoneNumber);

    boolean existsByUsername(String username);

    boolean existsByEmail(String email);

    boolean existsByAccountAlias(String accountAlias);
}
