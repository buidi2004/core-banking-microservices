package com.fintech.wallet.infrastructure.amqp.consumer;

import com.fintech.wallet.domain.event.UserRegisteredEvent;
import com.fintech.wallet.domain.model.Wallet;
import com.fintech.wallet.domain.model.WalletStatus;
import com.fintech.wallet.domain.port.out.WalletPersistencePort;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.rabbit.annotation.Exchange;
import org.springframework.amqp.rabbit.annotation.Queue;
import org.springframework.amqp.rabbit.annotation.QueueBinding;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;
import java.util.UUID;

/**
 * Consumer bất đồng bộ phục vụ Onboarding ví người dùng mới (Giai đoạn 3 kiến trúc phân rã).
 * Lắng nghe UserRegisteredEvent từ Identity Service để khởi tạo ví trong ewallet_wallet_db.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class UserRegisteredWalletConsumer {

    private final WalletPersistencePort walletPersistencePort;

    @RabbitListener(bindings = @QueueBinding(
            value = @Queue(value = "wallet.user.registered.queue", durable = "true"),
            exchange = @Exchange(value = "wallet.exchange", type = "topic"),
            key = "wallet.user.registered"
    ))
    @Transactional
    public void handleUserRegistered(UserRegisteredEvent event) {
        log.info("Nhận sự kiện UserRegisteredEvent: userId={}, phone={}", event.userId(), event.phone());

        // Kiểm tra Idempotency - nếu ví đã tồn tại thì bỏ qua
        Optional<Wallet> existing = walletPersistencePort.findWalletByOwnerId(event.userId());
        if (existing.isPresent()) {
            log.warn("Ví cho userId={} đã tồn tại. Bỏ qua bước tạo mới (Idempotent).", event.userId());
            return;
        }

        // Khởi tạo ví mới với số dư ban đầu = 0, currency = VND
        Wallet newWallet = Wallet.createNew(event.userId(), "VND");
        walletPersistencePort.saveWallet(newWallet);
        log.info("Khởi tạo ví thành công cho userId={}, walletId={}", event.userId(), newWallet.getId());
    }
}
