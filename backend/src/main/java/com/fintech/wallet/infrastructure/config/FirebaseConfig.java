package com.fintech.wallet.infrastructure.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.Resource;
import org.springframework.core.io.ResourceLoader;

import jakarta.annotation.PostConstruct;
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
            // 1. Try raw JSON from environment variable if provided
            if (credentialsJson != null && !credentialsJson.isBlank()) {
                try (InputStream stream = new ByteArrayInputStream(credentialsJson.getBytes(StandardCharsets.UTF_8))) {
                    FirebaseOptions options = FirebaseOptions.builder()
                            .setCredentials(GoogleCredentials.fromStream(stream))
                            .build();
                    FirebaseApp.initializeApp(options);
                    log.info("FirebaseApp initialized successfully from FIREBASE_CREDENTIALS_JSON environment variable");
                    return;
                }
            }

            // 2. Try loading from credential path (classpath or file)
            if (credentialPath != null && !credentialPath.isBlank()) {
                Resource resource = resourceLoader.getResource(credentialPath);
                if (resource.exists()) {
                    try (InputStream serviceAccount = resource.getInputStream()) {
                        FirebaseOptions options = FirebaseOptions.builder()
                                .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                                .build();
                        FirebaseApp.initializeApp(options);
                        log.info("FirebaseApp initialized successfully using credentials from {}", credentialPath);
                        return;
                    }
                } else {
                    log.info("Firebase credential resource [{}] does not exist. Checking application default credentials...", credentialPath);
                }
            }

            // 3. Fallback to application default credentials (e.g. GCP environment or GOOGLE_APPLICATION_CREDENTIALS)
            try {
                FirebaseOptions options = FirebaseOptions.builder()
                        .setCredentials(GoogleCredentials.getApplicationDefault())
                        .build();
                FirebaseApp.initializeApp(options);
                log.info("FirebaseApp initialized successfully using Application Default Credentials");
            } catch (Exception e) {
                log.warn("No Firebase credentials configured (file [{}] not found and no Application Default Credentials). " +
                        "FCM Push notifications will run in mock/log-only mode until a service account JSON is provided.", credentialPath);
            }
        } catch (Exception e) {
            log.error("Failed to initialize FirebaseApp. FCM will run in fallback/mock mode.", e);
        }
    }
}
