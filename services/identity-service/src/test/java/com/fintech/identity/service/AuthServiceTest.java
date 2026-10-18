package com.fintech.identity.service;

import com.fintech.identity.domain.entity.UserEntity;
import com.fintech.identity.domain.entity.UserProfileEntity;
import com.fintech.identity.dto.AuthResponse;
import com.fintech.identity.dto.RegisterRequest;
import com.fintech.identity.messaging.IdentityEventPublisher;
import com.fintech.identity.repository.UserProfileRepository;
import com.fintech.identity.repository.UserRepository;
import com.fintech.identity.repository.UserSessionRepository;
import com.fintech.identity.security.JwtTokenProvider;
import com.fintech.wallet.domain.event.UserRegisteredEvent;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;
import org.springframework.security.crypto.password.PasswordEncoder;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private UserProfileRepository userProfileRepository;

    @Mock
    private UserSessionRepository userSessionRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtTokenProvider tokenProvider;

    @Mock
    private IdentityEventPublisher eventPublisher;

    @Mock
    private StringRedisTemplate redisTemplate;

    @Mock
    private ValueOperations<String, String> valueOperations;

    @InjectMocks
    private AuthService authService;

    @BeforeEach
    void setUp() {
        lenient().when(tokenProvider.getAccessTokenExpirationSeconds()).thenReturn(3600L);
    }

    @Test
    @DisplayName("Đăng ký người dùng mới: lưu User, tạo Profile, phát UserRegisteredEvent lên RabbitMQ")
    void shouldRegisterUserAndPublishUserRegisteredEvent() {
        // Arrange
        RegisterRequest request = RegisterRequest.builder()
                .phoneNumber("0987654321")
                .fullName("Nguyen Van A")
                .password("Password123!")
                .email("nguyenvana@gmail.com")
                .build();

        when(userRepository.existsByPhoneNumber("0987654321")).thenReturn(false);
        when(userRepository.existsByEmail("nguyenvana@gmail.com")).thenReturn(false);
        when(passwordEncoder.encode("Password123!")).thenReturn("$2a$10$encodedPasswordHash");
        when(tokenProvider.generateAccessToken(anyString(), eq("0987654321"), eq("ROLE_USER"), eq("UNVERIFIED")))
                .thenReturn("mock-access-token-jwt");
        when(tokenProvider.generateRefreshToken(anyString()))
                .thenReturn("mock-refresh-token-jwt");

        // Act
        AuthResponse response = authService.register(request);

        // Assert 1: Lưu User vào ewallet_identity_db
        ArgumentCaptor<UserEntity> userCaptor = ArgumentCaptor.forClass(UserEntity.class);
        verify(userRepository).save(userCaptor.capture());
        UserEntity savedUser = userCaptor.getValue();

        assertNotNull(savedUser.getId());
        assertEquals("0987654321", savedUser.getPhoneNumber());
        assertEquals("Nguyen Van A", savedUser.getFullName());
        assertEquals("nguyenvana@gmail.com", savedUser.getEmail());
        assertEquals("$2a$10$encodedPasswordHash", savedUser.getPasswordHash());
        assertEquals("ROLE_USER", savedUser.getRole());
        assertEquals("ACTIVE", savedUser.getStatus());
        assertEquals("UNVERIFIED", savedUser.getKycTier());

        // Assert 2: Tạo UserProfile mặc định
        ArgumentCaptor<UserProfileEntity> profileCaptor = ArgumentCaptor.forClass(UserProfileEntity.class);
        verify(userProfileRepository).save(profileCaptor.capture());
        assertEquals(savedUser.getId(), profileCaptor.getValue().getUserId());

        // Assert 3: Phát sự kiện UserRegisteredEvent lên RabbitMQ (Event-Driven Onboarding)
        ArgumentCaptor<UserRegisteredEvent> eventCaptor = ArgumentCaptor.forClass(UserRegisteredEvent.class);
        verify(eventPublisher, times(1)).publishUserRegistered(eventCaptor.capture());

        UserRegisteredEvent publishedEvent = eventCaptor.getValue();
        assertNotNull(publishedEvent.eventId());
        assertNotNull(publishedEvent.occurredAt());
        assertEquals(savedUser.getId(), publishedEvent.userId());
        assertEquals("0987654321", publishedEvent.phone());
        assertEquals("Nguyen Van A", publishedEvent.fullName());
        assertEquals(0, publishedEvent.kycTier());
        assertEquals("VN", publishedEvent.countryCode());

        // Assert 4: Trả về AuthResponse với token hợp lệ
        assertNotNull(response);
        assertEquals("mock-access-token-jwt", response.getToken());
        assertEquals("mock-refresh-token-jwt", response.getRefreshToken());
        assertEquals(savedUser.getId(), response.getUserId());
        assertEquals("0987654321", response.getPhoneNumber());
        assertEquals("Nguyen Van A", response.getFullName());
    }

    @Test
    @DisplayName("Từ chối đăng ký khi số điện thoại đã tồn tại, KHÔNG phát sự kiện RabbitMQ")
    void shouldThrowExceptionWhenPhoneExistsAndNotPublishEvent() {
        // Arrange
        RegisterRequest request = RegisterRequest.builder()
                .phoneNumber("0987654321")
                .fullName("Nguyen Van A")
                .password("Password123!")
                .build();

        when(userRepository.existsByPhoneNumber("0987654321")).thenReturn(true);

        // Act & Assert
        IllegalArgumentException exception = assertThrows(IllegalArgumentException.class, () -> {
            authService.register(request);
        });

        assertTrue(exception.getMessage().contains("0987654321"));
        verify(userRepository, never()).save(any());
        verify(eventPublisher, never()).publishUserRegistered(any());
    }

    @Test
    @DisplayName("Từ chối đăng ký khi email đã tồn tại, KHÔNG phát sự kiện RabbitMQ")
    void shouldThrowExceptionWhenEmailExistsAndNotPublishEvent() {
        // Arrange
        RegisterRequest request = RegisterRequest.builder()
                .phoneNumber("0987654321")
                .fullName("Nguyen Van A")
                .password("Password123!")
                .email("duplicate@gmail.com")
                .build();

        when(userRepository.existsByPhoneNumber("0987654321")).thenReturn(false);
        when(userRepository.existsByEmail("duplicate@gmail.com")).thenReturn(true);

        // Act & Assert
        assertThrows(IllegalArgumentException.class, () -> authService.register(request));
        verify(userRepository, never()).save(any());
        verify(eventPublisher, never()).publishUserRegistered(any());
    }
}
