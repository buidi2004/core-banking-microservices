package com.fintech.wallet.domain.port.out;

import com.fintech.wallet.domain.model.User;
import java.util.Optional;

public interface UserPersistencePort {
    User saveUser(User user);
    Optional<User> findUserById(String userId);
    Optional<User> findUserByPhoneNumber(String phoneNumber);

    /**
     * Look up a user's public profile by phone number.
     * Used in the P2P transfer flow: sender enters a phone number,
     * UI shows the recipient's name/avatar before the transfer is confirmed.
     * Returns empty if no account is registered for that number.
     */
    Optional<User> searchByPhoneNumber(String phoneNumber);
}
