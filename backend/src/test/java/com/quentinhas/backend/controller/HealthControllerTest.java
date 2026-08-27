package com.quentinhas.backend.controller;

import com.quentinhas.backend.security.SecurityConfig;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@org.springframework.test.context.ActiveProfiles("test")
@AutoConfigureMockMvc
class HealthControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    @DisplayName("GET /api/health deve retornar status 200 OK com payload indicando UP")
    void healthEndpointShouldReturnUp() throws Exception {
        mockMvc.perform(get("/api/health")
                .accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("UP"))
                .andExpect(jsonPath("$.service").value("quentinhas-pro-api"));
    }

    @Test
    @DisplayName("GET /api/health/error deve estourar a RuntimeException e ser traduzido para ProblemDetail (Status 500)")
    void errorEndpointShouldReturnProblemDetail() throws Exception {
        mockMvc.perform(get("/api/health/error")
                .accept(MediaType.APPLICATION_PROBLEM_JSON))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.title").value("Internal Server Error"))
                .andExpect(jsonPath("$.detail").value("Test exception for problem detail"));
    }

    @Test
    @DisplayName("GET /api/qualquer-outra-coisa deve ser bloqueado pelo Spring Security")
    void anyOtherEndpointShouldReturnForbiddenOrUnauthorized() throws Exception {
        mockMvc.perform(get("/api/endpoint-protegido-inexistente"))
                .andExpect(status().isForbidden()); // Sem auth configurada, default behavior é 403.
    }
}
