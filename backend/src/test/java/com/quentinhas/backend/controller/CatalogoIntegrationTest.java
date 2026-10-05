package com.quentinhas.backend.controller;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;

import java.util.UUID;

import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@AutoConfigureMockMvc
class CatalogoIntegrationTest extends com.quentinhas.backend.AbstractIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private UUID produtoId1;
    private UUID variacaoPId;
    private UUID variacaoMId;
    private UUID variacaoGId;

    @BeforeEach
    void setUp() {
        jdbcTemplate.execute("TRUNCATE TABLE produtos CASCADE");
        jdbcTemplate.execute("TRUNCATE TABLE adicionais CASCADE");
        jdbcTemplate.execute("TRUNCATE TABLE produto_variacoes CASCADE");

        produtoId1 = UUID.randomUUID();
        jdbcTemplate.update("INSERT INTO produtos (id, nome, descricao, categoria, preco_base, estoque_atual) VALUES (?, ?, ?, ?, ?, ?)",
                produtoId1, "Frango Assado", "Frango assado na brasa", "PRATO_PRINCIPAL", 0.00, 10);

        variacaoPId = UUID.randomUUID();
        jdbcTemplate.update("INSERT INTO produto_variacoes (id, produto_id, tamanho, preco, ativo) VALUES (?, ?, ?, ?, ?)",
                variacaoPId, produtoId1, "PEQUENA", 18.00, true);

        variacaoMId = UUID.randomUUID();
        jdbcTemplate.update("INSERT INTO produto_variacoes (id, produto_id, tamanho, preco, ativo) VALUES (?, ?, ?, ?, ?)",
                variacaoMId, produtoId1, "MEDIA", 22.00, true);

        variacaoGId = UUID.randomUUID();
        // Inativa
        jdbcTemplate.update("INSERT INTO produto_variacoes (id, produto_id, tamanho, preco, ativo) VALUES (?, ?, ?, ?, ?)",
                variacaoGId, produtoId1, "GRANDE", 28.00, false);
                
        // Adicionais
        jdbcTemplate.update("INSERT INTO adicionais (id, nome, preco, ativo) VALUES (?, 'Ovo', 3.00, true)", UUID.randomUUID());
    }

    @Test
    @DisplayName("Deve retornar o catalogo agrupado por produto apenas com variacoes ativas")
    void testGetCatalogoOk() throws Exception {
        mockMvc.perform(get("/api/catalogo"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.produtos", hasSize(1)))
                .andExpect(jsonPath("$.produtos[0].nome").value("Frango Assado"))
                .andExpect(jsonPath("$.produtos[0].tamanhos", hasSize(2))) // P e M
                .andExpect(jsonPath("$.produtos[0].tamanhos[0].ofertaId").exists()) // backwards comp
                .andExpect(jsonPath("$.adicionais", hasSize(1)));
    }

    @Test
    @DisplayName("Deve retornar 404 se a variacao nao existir")
    void testGetOfertaInexistente() throws Exception {
        mockMvc.perform(get("/api/ofertas/" + UUID.randomUUID()))
                .andExpect(status().isNotFound());
    }

    @Test
    @DisplayName("Deve retornar detalhes da oferta (variacao) corretamente")
    void testGetOfertaExistente() throws Exception {
        mockMvc.perform(get("/api/ofertas/" + variacaoPId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nomeProduto").value("Frango Assado"))
                .andExpect(jsonPath("$.preco").value(18.00))
                .andExpect(jsonPath("$.tamanho").value("PEQUENA"))
                .andExpect(jsonPath("$.disponivel").value(true)); // estoque_atual = 10
    }
}
