package com.fintech.wallet.infrastructure.persistence.adapter;

import com.fintech.wallet.domain.model.DeviceToken;
import com.fintech.wallet.domain.port.out.DeviceTokenPersistencePort;
import com.fintech.wallet.infrastructure.persistence.entity.DeviceTokenEntity;
import com.fintech.wallet.infrastructure.persistence.repository.SpringDataDeviceTokenRepository;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Component
public class DeviceTokenPersistenceAdapter implements DeviceTokenPersistencePort {

    private final SpringDataDeviceTokenRepository repository;

    public DeviceTokenPersistenceAdapter(SpringDataDeviceTokenRepository repository) {
        this.repository = repository;
    }

    @Override
    public DeviceToken save(DeviceToken deviceToken) {
        DeviceTokenEntity entity = new DeviceTokenEntity(
                deviceToken.getId(),
                deviceToken.getUserId(),
                deviceToken.getFcmToken(),
                deviceToken.getDeviceType(),
                deviceToken.getCreatedAt(),
                deviceToken.getUpdatedAt()
        );
        DeviceTokenEntity saved = repository.save(entity);
        return mapToDomain(saved);
    }

    @Override
    public Optional<DeviceToken> findByFcmToken(String fcmToken) {
        return repository.findByFcmToken(fcmToken).map(this::mapToDomain);
    }

    @Override
    public List<DeviceToken> findByUserId(String userId) {
        return repository.findByUserId(userId).stream()
                .map(this::mapToDomain)
                .collect(Collectors.toList());
    }

    @Override
    public void deleteByFcmToken(String fcmToken) {
        repository.deleteByFcmToken(fcmToken);
    }

    @Override
    public void deleteByUserIdAndFcmToken(String userId, String fcmToken) {
        repository.deleteByUserIdAndFcmToken(userId, fcmToken);
    }

    private DeviceToken mapToDomain(DeviceTokenEntity entity) {
        return new DeviceToken(
                entity.getId(),
                entity.getUserId(),
                entity.getFcmToken(),
                entity.getDeviceType(),
                entity.getCreatedAt(),
                entity.getUpdatedAt()
        );
    }
}
