package com.fintech.notification.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.Resource;
import org.springframework.core.io.ResourceLoader;

import java.io.ByteArrayInputStream;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

@Configuration
public class FirebaseConfig {

    private static final Logger log = LoggerFactory.getLogger(FirebaseConfig.class);

    @Value("${firebase.credential.path:classpath:firebase-service-account.json}")
    private String credentialPath;

    @Value("${FIREBASE_CREDENTIALS_JSON:}")
    private String credentialsJson;

    private final ResourceLoader resourceLoader;

    public FirebaseConfig(ResourceLoader resourceLoader) {
        this.resourceLoader = resourceLoader;
    }

    @PostConstruct
    public void init() {
        if (!FirebaseApp.getApps().isEmpty()) {
            return;
        }
        try {
            if (credentialsJson != null && !credentialsJson.isBlank()) {
                try (InputStream stream = new ByteArrayInputStream(credentialsJson.getBytes(StandardCharsets.UTF_8))) {
                    FirebaseApp.initializeApp(FirebaseOptions.builder()
                            .setCredentials(GoogleCredentials.fromStream(stream))
                            .build());
                    log.info("FirebaseApp initialized from FIREBASE_CREDENTIALS_JSON");
                    return;
                }
            }

            Resource resource = resourceLoader.getResource(credentialPath);
            if (resource.exists()) {
                try (InputStream serviceAccount = resource.getInputStream()) {
                    FirebaseApp.initializeApp(FirebaseOptions.builder()
                            .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                            .build());
                    log.info("FirebaseApp initialized from {}", credentialPath);
                    return;
                }
            }

            try {
                FirebaseApp.initializeApp(FirebaseOptions.builder()
                        .setCredentials(GoogleCredentials.getApplicationDefault())
                        .build());
                log.info("FirebaseApp initialized from Application Default Credentials");
            } catch (Exception e) {
                log.warn("No Firebase credentials configured. FCM push runs in mock/log-only mode.");
            }
        } catch (Exception e) {
            log.error("Failed to initialize FirebaseApp. FCM will run in fallback/mock mode.", e);
        }
    }
}
