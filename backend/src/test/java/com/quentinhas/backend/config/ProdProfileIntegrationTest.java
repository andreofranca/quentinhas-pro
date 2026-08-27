package com.quentinhas.backend.config;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.core.env.Environment;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@ActiveProfiles("prod")
@TestPropertySource(properties = {
    "SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5440/quentinhas_test",
    "SPRING_DATASOURCE_USERNAME=quentinhas_app",
    "SPRING_DATASOURCE_PASSWORD=app_password",
    "JWT_SECRET=prodsecretprodsecretprodsecretprodsecretprodsecret",
    "FRONTEND_URL=https://app.quentinhas.com"
})
public class ProdProfileIntegrationTest {

    @Autowired
    private Environment env;

    @Test
    void testProdProfileProperties() {
        assertThat(env.getActiveProfiles()).contains("prod");
        assertThat(env.getProperty("spring.datasource.url")).isEqualTo("jdbc:postgresql://localhost:5440/quentinhas_test");
        assertThat(env.getProperty("cors.allowed-origins")).isEqualTo("https://app.quentinhas.com");
    }
}
