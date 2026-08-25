package com.quentinhas.backend.controller;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.UUID;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;

import com.quentinhas.backend.model.Usuario;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
class CaixaIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private UUID userId;
    private Usuario mockUser;

    @BeforeEach
    void setUp() {
        jdbcTemplate.execute("TRUNCATE TABLE usuarios CASCADE");
        jdbcTemplate.execute("TRUNCATE TABLE caixas CASCADE");

        userId = UUID.randomUUID();
        jdbcTemplate.update("INSERT INTO usuarios (id, nome, email, password_hash, role) VALUES (?, 'Test', 'test@test.com', 'hash', 'CAIXA')", userId);

        mockUser = new Usuario("Test", "test@test.com", "hash", "CAIXA");
        ReflectionTestUtils.setField(mockUser, "id", userId);
    }

    @Test
    @DisplayName("Deve retornar 200 com os dados do caixa ativo do usuario")
    void deveRetornarCaixaAtivo() throws Exception {
        UUID caixaId = UUID.randomUUID();
        jdbcTemplate.update("INSERT INTO caixas (id, operador_id, terminal_id, status) VALUES (?, ?, 'TEST_TERM', 'ABERTO')", caixaId, userId);

        mockMvc.perform(get("/api/caixas/ativo")
                        .with(user(mockUser)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(caixaId.toString()))
                .andExpect(jsonPath("$.terminalId").value("TEST_TERM"))
                .andExpect(jsonPath("$.status").value("ABERTO"));
    }

    @Test
    @DisplayName("Deve retornar 404 quando o usuario nao tem caixa aberto")
    void deveRetornar404SemCaixaAberto() throws Exception {
        mockMvc.perform(get("/api/caixas/ativo")
                        .with(user(mockUser)))
                .andExpect(status().isNotFound());
    }
    
    @Test
    @DisplayName("Deve retornar 404 quando o usuario tem caixa, mas esta fechado")
    void deveRetornar404ComCaixaFechado() throws Exception {
        UUID caixaId = UUID.randomUUID();
        jdbcTemplate.update("INSERT INTO caixas (id, operador_id, terminal_id, status) VALUES (?, ?, 'TEST_TERM', 'FECHADO')", caixaId, userId);

        mockMvc.perform(get("/api/caixas/ativo")
                        .with(user(mockUser)))
                .andExpect(status().isNotFound());
    }
    
    @Test
    @DisplayName("Deve retornar 403 quando nao autenticado")
    void deveRetornar401NaoAutenticado() throws Exception {
        mockMvc.perform(get("/api/caixas/ativo"))
                .andExpect(status().isForbidden());
    }
}
