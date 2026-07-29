package com.fintech.wallet.domain.port.out;

import com.fintech.wallet.domain.model.User;
import java.util.Optional;

public interface UserPersistencePort {
    User saveUser(User user);
    Optional<User> findUserById(String userId);
    Optional<User> findUserByPhoneNumber(String phoneNumber);
}
