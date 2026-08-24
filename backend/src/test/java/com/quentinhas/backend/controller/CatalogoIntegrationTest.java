package com.quentinhas.backend.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.quentinhas.backend.model.Cardapio;
import com.quentinhas.backend.model.Oferta;
import com.quentinhas.backend.model.Produto;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class CatalogoIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private UUID produtoId1;
    private UUID ofertaPId;
    private UUID ofertaMId;
    private UUID ofertaGId;

    @BeforeEach
    void setUp() {
        jdbcTemplate.execute("DELETE FROM ofertas");
        jdbcTemplate.execute("DELETE FROM cardapios");
        jdbcTemplate.execute("DELETE FROM produtos");

        produtoId1 = UUID.randomUUID();
        jdbcTemplate.update("INSERT INTO produtos (id, nome, descricao, categoria, preco_base) VALUES (?, ?, ?, ?, ?)",
                produtoId1, "Frango Assado", "Frango assado na brasa", "PRATO_PRINCIPAL", 15.00);

        UUID cardapioId = UUID.randomUUID();
        jdbcTemplate.update("INSERT INTO cardapios (id, data_referencia, status) VALUES (?, ?, ?)",
                cardapioId, LocalDate.now(), "ABERTO");

        ofertaPId = UUID.randomUUID();
        jdbcTemplate.update("INSERT INTO ofertas (id, cardapio_id, produto_id, tamanho, preco_vigente, limite_producao, reservado_atual) VALUES (?, ?, ?, ?, ?, ?, ?)",
                ofertaPId, cardapioId, produtoId1, "PEQUENA", 18.00, 10, 5); // disponivel = true

        ofertaMId = UUID.randomUUID();
        jdbcTemplate.update("INSERT INTO ofertas (id, cardapio_id, produto_id, tamanho, preco_vigente, limite_producao, reservado_atual) VALUES (?, ?, ?, ?, ?, ?, ?)",
                ofertaMId, cardapioId, produtoId1, "MEDIA", 22.00, null, 0); // disponivel = true

        ofertaGId = UUID.randomUUID();
        jdbcTemplate.update("INSERT INTO ofertas (id, cardapio_id, produto_id, tamanho, preco_vigente, limite_producao, reservado_atual) VALUES (?, ?, ?, ?, ?, ?, ?)",
                ofertaGId, cardapioId, produtoId1, "GRANDE", 27.00, 5, 5); // disponivel = false
    }

    @Test
    @DisplayName("Deve listar catálogo com produtos, tamanhos e disponibilidade")
    void testGetCatalogo() throws Exception {
        mockMvc.perform(get("/api/catalogo"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.produtos", hasSize(1)))
                .andExpect(jsonPath("$.produtos[0].id").value(produtoId1.toString()))
                .andExpect(jsonPath("$.produtos[0].nome").value("Frango Assado"))
                .andExpect(jsonPath("$.produtos[0].tamanhos", hasSize(3)))
                // Verifica mapeamento P, M, G
                .andExpect(jsonPath("$.produtos[0].tamanhos[*].sigla", containsInAnyOrder("P", "M", "G")))
                // Verifica disponibilidade P = true, M = true, G = false
                .andExpect(jsonPath("$.produtos[0].tamanhos[?(@.sigla=='G')].disponivel").value(false))
                .andExpect(jsonPath("$.produtos[0].tamanhos[?(@.sigla=='P')].disponivel").value(true));
    }

    @Test
    @DisplayName("Deve retornar detalhes da oferta existente publicamente")
    void testGetOfertaExistente() throws Exception {
        mockMvc.perform(get("/api/ofertas/" + ofertaPId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(ofertaPId.toString()))
                .andExpect(jsonPath("$.tamanho").value("PEQUENA"))
                .andExpect(jsonPath("$.preco").value(18.00))
                .andExpect(jsonPath("$.disponivel").value(true));
    }

    @Test
    @DisplayName("Deve retornar 404 para oferta inexistente")
    void testGetOfertaInexistente() throws Exception {
        mockMvc.perform(get("/api/ofertas/" + UUID.randomUUID()))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.status").value(404));
    }

    @Test
    @DisplayName("Catálogo não deve decrementar ou modificar estoque")
    void testNaoModificaEstoque() throws Exception {
        mockMvc.perform(get("/api/catalogo"))
                .andExpect(status().isOk());
                
        // Verifica se reservado_atual da ofertaP continua 5
        Integer reservado = jdbcTemplate.queryForObject("SELECT reservado_atual FROM ofertas WHERE id = ?", Integer.class, ofertaPId);
        org.junit.jupiter.api.Assertions.assertEquals(5, reservado);
    }
}
