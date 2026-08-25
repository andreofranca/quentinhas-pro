package com.quentinhas.backend.controller;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.UUID;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
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
    @DisplayName("Deve retornar 403 quando nao autenticado no get")
    void deveRetornar401NaoAutenticado() throws Exception {
        mockMvc.perform(get("/api/caixas/ativo"))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("Deve abrir caixa com sucesso")
    void deveAbrirCaixaComSucesso() throws Exception {
        String jsonPayload = """
                {
                  "saldoInicial": 50.00
                }
                """;
        mockMvc.perform(post("/api/caixas/abrir")
                        .with(user(mockUser))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(jsonPayload))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").exists())
                .andExpect(jsonPath("$.status").value("ABERTO"));
    }

    @Test
    @DisplayName("Deve retornar 409 conflito ao tentar abrir caixa ja aberto")
    void deveRetornar409SeCaixaJaAberto() throws Exception {
        UUID caixaId = UUID.randomUUID();
        jdbcTemplate.update("INSERT INTO caixas (id, operador_id, terminal_id, status) VALUES (?, ?, 'TEST_TERM', 'ABERTO')", caixaId, userId);

        String jsonPayload = """
                {
                  "saldoInicial": 50.00
                }
                """;
        mockMvc.perform(post("/api/caixas/abrir")
                        .with(user(mockUser))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(jsonPayload))
                .andExpect(status().isConflict());
    }

    @Test
    @DisplayName("Deve retornar 403 quando nao autenticado no post")
    void deveRetornar403NaoAutenticadoPost() throws Exception {
        String jsonPayload = """
                {
                  "saldoInicial": 50.00
                }
                """;
        mockMvc.perform(post("/api/caixas/abrir")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(jsonPayload))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("Deve retornar 400 bad request ao tentar abrir caixa com saldo negativo")
    void deveRetornar400SaldoNegativo() throws Exception {
        String jsonPayload = """
                {
                  "saldoInicial": -10.00
                }
                """;
        mockMvc.perform(post("/api/caixas/abrir")
                        .with(user(mockUser))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(jsonPayload))
                .andExpect(status().isBadRequest());
    }
}
