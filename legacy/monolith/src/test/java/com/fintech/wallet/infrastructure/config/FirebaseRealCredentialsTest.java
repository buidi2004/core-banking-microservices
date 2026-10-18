package com.fintech.wallet.infrastructure.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import org.junit.jupiter.api.Test;
import org.springframework.core.io.ClassPathResource;

import java.io.InputStream;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

class FirebaseRealCredentialsTest {

    @Test
    void testRealCredentialsFileCanBeParsed() throws Exception {
        ClassPathResource resource = new ClassPathResource("firebase-service-account.json");
        org.junit.jupiter.api.Assumptions.assumeTrue(resource.exists(), "Skip if file not present");

        try (InputStream is = resource.getInputStream()) {
            GoogleCredentials credentials = GoogleCredentials.fromStream(is);
            assertNotNull(credentials, "GoogleCredentials should parse the JSON key successfully");
            
            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(credentials)
                    .setProjectId("nganhang-bbcfe")
                    .build();
            
            assertEquals("nganhang-bbcfe", options.getProjectId());
        }
    }
}
