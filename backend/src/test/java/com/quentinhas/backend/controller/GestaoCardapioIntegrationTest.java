package com.quentinhas.backend.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.quentinhas.backend.model.Usuario;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@AutoConfigureMockMvc
@Transactional
class GestaoCardapioIntegrationTest extends com.quentinhas.backend.AbstractIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private UUID userId;
    private Usuario mockUser;
    private UUID produtoId;
    private UUID cardapioId;
    private UUID ofertaId;

    @BeforeEach
    void setUp() {
        jdbcTemplate.execute("TRUNCATE TABLE usuarios CASCADE");
        jdbcTemplate.execute("TRUNCATE TABLE ofertas CASCADE");
        jdbcTemplate.execute("TRUNCATE TABLE cardapios CASCADE");
        jdbcTemplate.execute("TRUNCATE TABLE produtos CASCADE");

        userId = UUID.randomUUID();
        jdbcTemplate.update("INSERT INTO usuarios (id, nome, email, password_hash, role) VALUES (?, 'Admin', 'admin@test.com', 'hash', 'ADMIN')", userId);

        mockUser = new Usuario("Admin", "admin@test.com", "hash", "ADMIN");
        ReflectionTestUtils.setField(mockUser, "id", userId);

        produtoId = UUID.randomUUID();
        jdbcTemplate.update("INSERT INTO produtos (id, nome, categoria, preco_base) VALUES (?, 'Produto Teste', 'Lanches', 20.00)", produtoId);

        cardapioId = UUID.randomUUID();
        jdbcTemplate.update("INSERT INTO cardapios (id, data_referencia, status) VALUES (?, CURRENT_DATE, 'ABERTO')", cardapioId);

        ofertaId = UUID.randomUUID();
        jdbcTemplate.update("INSERT INTO ofertas (id, cardapio_id, produto_id, tamanho, preco_vigente, limite_producao, reservado_atual, ativo) VALUES (?, ?, ?, 'MEDIA', 25.00, 10, 2, true)", ofertaId, cardapioId, produtoId);
    }

    @Test
    void listarOfertas() throws Exception {
        mockMvc.perform(get("/api/gestao/ofertas")
                .with(user(mockUser)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").value(ofertaId.toString()))
                .andExpect(jsonPath("$[0].produtoNome").value("Produto Teste"));
    }

    @Test
    void criarOferta() throws Exception {
        String payload = "{ \"produtoId\": \"" + produtoId + "\", \"tamanho\": \"GRANDE\", \"precoVigente\": 30.00, \"limiteProducao\": 5, \"ativo\": true }";

        mockMvc.perform(post("/api/gestao/ofertas")
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload)
                .with(user(mockUser)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.tamanho").value("GRANDE"))
                .andExpect(jsonPath("$.precoVigente").value(30.00));
    }

    @Test
    void editarOferta() throws Exception {
        String payload = "{ \"produtoId\": \"" + produtoId + "\", \"tamanho\": \"MEDIA\", \"precoVigente\": 28.00, \"limiteProducao\": 15, \"ativo\": false }";

        mockMvc.perform(put("/api/gestao/ofertas/" + ofertaId)
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload)
                .with(user(mockUser)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.precoVigente").value(28.00))
                .andExpect(jsonPath("$.ativo").value(false));
    }

    @Test
    void editarOferta_limiteInvalido() throws Exception {
        // reservado_atual é 2. Tentar setar limite_producao para 1 deve falhar.
        String payload = "{ \"produtoId\": \"" + produtoId + "\", \"tamanho\": \"MEDIA\", \"precoVigente\": 28.00, \"limiteProducao\": 1, \"ativo\": true }";

        mockMvc.perform(put("/api/gestao/ofertas/" + ofertaId)
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload)
                .with(user(mockUser)))
                .andExpect(status().isBadRequest());
    }
}
