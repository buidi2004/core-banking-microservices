package com.fintech.notification.notification;

import com.fintech.notification.entity.DeviceToken;
import com.fintech.notification.repository.DeviceTokenRepository;
import com.google.firebase.FirebaseApp;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.MessagingErrorCode;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class FcmPushSenderTest {

    @Mock
    private DeviceTokenRepository deviceTokenRepository;

    private DeviceToken token(String userId, String value) {
        return DeviceToken.create(userId, "ANDROID", value, "Pixel", "1.0");
    }

    @Test
    void doesNothingWhenUserIdBlank() {
        FcmPushSender sender = new FcmPushSender(deviceTokenRepository);

        sender.sendPushNotification("  ", "title", "body", Map.of());

        verifyNoInteractions(deviceTokenRepository);
    }

    @Test
    void skipsWhenNoActiveTokens() {
        when(deviceTokenRepository.findByUserIdAndActiveTrue("user-001")).thenReturn(List.of());
        FcmPushSender sender = new FcmPushSender(deviceTokenRepository);

        assertThatCode(() -> sender.sendPushNotification("user-001", "title", "body", Map.of()))
                .doesNotThrowAnyException();

        verify(deviceTokenRepository).findByUserIdAndActiveTrue("user-001");
    }

    @Test
    void doesNotCallFirebaseWhenAppNotInitialized() {
        when(deviceTokenRepository.findByUserIdAndActiveTrue("user-001"))
                .thenReturn(List.of(token("user-001", "token-1")));
        FcmPushSender sender = new FcmPushSender(deviceTokenRepository);

        try (MockedStatic<FirebaseApp> firebaseApp = mockStatic(FirebaseApp.class);
             MockedStatic<FirebaseMessaging> firebaseMessaging = mockStatic(FirebaseMessaging.class)) {
            firebaseApp.when(FirebaseApp::getApps).thenReturn(List.of());

            assertThatCode(() -> sender.sendPushNotification("user-001", "title", "body", Map.of("k", "v")))
                    .doesNotThrowAnyException();

            firebaseMessaging.verifyNoInteractions();
        }
    }

    @Test
    void dispatchesPushToEveryActiveToken() throws Exception {
        when(deviceTokenRepository.findByUserIdAndActiveTrue("user-001"))
                .thenReturn(List.of(token("user-001", "token-1"), token("user-001", "token-2")));
        FirebaseMessaging messaging = mock(FirebaseMessaging.class);
        when(messaging.send(any(Message.class))).thenReturn("message-id");

        FcmPushSender sender = new FcmPushSender(deviceTokenRepository);

        try (MockedStatic<FirebaseApp> firebaseApp = mockStatic(FirebaseApp.class);
             MockedStatic<FirebaseMessaging> firebaseMessaging = mockStatic(FirebaseMessaging.class)) {
            firebaseApp.when(FirebaseApp::getApps).thenReturn(List.of(mock(FirebaseApp.class)));
            firebaseMessaging.when(FirebaseMessaging::getInstance).thenReturn(messaging);

            sender.sendPushNotification("user-001", "title", "body", Map.of("transactionId", "tx-1"));
        }

        verify(messaging, times(2)).send(any(Message.class));
    }

    @Test
    void prunesUnregisteredToken() throws Exception {
        when(deviceTokenRepository.findByUserIdAndActiveTrue("user-001"))
                .thenReturn(List.of(token("user-001", "stale-token")));

        FirebaseMessagingException exception = mock(FirebaseMessagingException.class);
        when(exception.getMessagingErrorCode()).thenReturn(MessagingErrorCode.UNREGISTERED);
        when(exception.getMessage()).thenReturn("Requested entity was not found.");

        FirebaseMessaging messaging = mock(FirebaseMessaging.class);
        when(messaging.send(any(Message.class))).thenThrow(exception);

        FcmPushSender sender = new FcmPushSender(deviceTokenRepository);

        try (MockedStatic<FirebaseApp> firebaseApp = mockStatic(FirebaseApp.class);
             MockedStatic<FirebaseMessaging> firebaseMessaging = mockStatic(FirebaseMessaging.class)) {
            firebaseApp.when(FirebaseApp::getApps).thenReturn(List.of(mock(FirebaseApp.class)));
            firebaseMessaging.when(FirebaseMessaging::getInstance).thenReturn(messaging);

            sender.sendPushNotification("user-001", "title", "body", Map.of());
        }

        verify(deviceTokenRepository).deleteByToken("stale-token");
    }

    @Test
    void keepsTokenWhenFirebaseFailsWithTransientError() throws Exception {
        when(deviceTokenRepository.findByUserIdAndActiveTrue("user-001"))
                .thenReturn(List.of(token("user-001", "good-token")));

        FirebaseMessagingException exception = mock(FirebaseMessagingException.class);
        when(exception.getMessagingErrorCode()).thenReturn(MessagingErrorCode.INTERNAL);
        when(exception.getMessage()).thenReturn("Internal error");

        FirebaseMessaging messaging = mock(FirebaseMessaging.class);
        when(messaging.send(any(Message.class))).thenThrow(exception);

        FcmPushSender sender = new FcmPushSender(deviceTokenRepository);

        try (MockedStatic<FirebaseApp> firebaseApp = mockStatic(FirebaseApp.class);
             MockedStatic<FirebaseMessaging> firebaseMessaging = mockStatic(FirebaseMessaging.class)) {
            firebaseApp.when(FirebaseApp::getApps).thenReturn(List.of(mock(FirebaseApp.class)));
            firebaseMessaging.when(FirebaseMessaging::getInstance).thenReturn(messaging);

            sender.sendPushNotification("user-001", "title", "body", Map.of());
        }

        verify(deviceTokenRepository, never()).deleteByToken(anyString());
    }
}
