package com.fintech.wallet.infrastructure.persistence.adapter;

import com.fintech.wallet.domain.model.User;
import com.fintech.wallet.domain.port.out.UserPersistencePort;
import com.fintech.wallet.infrastructure.persistence.entity.UserJpaEntity;
import com.fintech.wallet.infrastructure.persistence.mapper.UserMapper;
import com.fintech.wallet.infrastructure.persistence.repository.SpringDataUserRepository;
import org.springframework.stereotype.Component;

import java.util.Optional;

@Component
public class UserPersistenceAdapter implements UserPersistencePort {

    private final SpringDataUserRepository userRepository;
    private final UserMapper mapper;

    public UserPersistenceAdapter(SpringDataUserRepository userRepository, UserMapper mapper) {
        this.userRepository = userRepository;
        this.mapper = mapper;
    }

    @Override
    public User saveUser(User user) {
        UserJpaEntity entity = mapper.toJpaEntity(user);
        UserJpaEntity saved = userRepository.save(entity);
        return mapper.toDomain(saved);
    }

    @Override
    public Optional<User> findUserById(String userId) {
        return userRepository.findById(userId).map(mapper::toDomain);
    }

    @Override
    public Optional<User> findUserByPhoneNumber(String phoneNumber) {
        return userRepository.findByPhoneNumber(phoneNumber).map(mapper::toDomain);
    }

    @Override
    public Optional<User> searchByPhoneNumber(String phoneNumber) {
        return userRepository.findByPhoneNumber(phoneNumber).map(mapper::toDomain);
    }
}
