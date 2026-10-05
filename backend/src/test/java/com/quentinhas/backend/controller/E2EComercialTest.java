package com.quentinhas.backend.controller;

import com.quentinhas.backend.AbstractIntegrationTest;
import com.quentinhas.backend.dto.request.ClienteRequest;
import com.quentinhas.backend.dto.request.ItemPedidoRequest;
import com.quentinhas.backend.dto.request.PagamentoRequest;
import com.quentinhas.backend.dto.request.PedidoRequest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import com.fasterxml.jackson.databind.ObjectMapper;

import static org.hamcrest.Matchers.containsString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@AutoConfigureMockMvc
public class E2EComercialTest extends AbstractIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    private ObjectMapper objectMapper = new ObjectMapper();

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private UUID caixaId;
    private UUID variacaoMId;
    private UUID adicionalOvoId;

    @BeforeEach
    void setUp() {
        jdbcTemplate.execute("TRUNCATE TABLE produtos CASCADE");
        jdbcTemplate.execute("TRUNCATE TABLE adicionais CASCADE");
        jdbcTemplate.execute("TRUNCATE TABLE usuarios CASCADE");
        jdbcTemplate.execute("TRUNCATE TABLE caixas CASCADE");
        jdbcTemplate.execute("TRUNCATE TABLE pedidos CASCADE");
        jdbcTemplate.execute("TRUNCATE TABLE clientes CASCADE");

        UUID userId = UUID.randomUUID();
        jdbcTemplate.update("INSERT INTO usuarios (id, nome, email, password_hash, role) VALUES (?, 'Op', 'op@test.com', 'hash', 'CAIXA')", userId);

        caixaId = UUID.randomUUID();
        jdbcTemplate.update("INSERT INTO caixas (id, operador_id, terminal_id, status) VALUES (?, ?, 'T1', 'ABERTO')", caixaId, userId);

        UUID produtoId = UUID.randomUUID();
        jdbcTemplate.update("INSERT INTO produtos (id, nome, categoria, preco_base, estoque_atual) VALUES (?, 'Carne', 'PRATO_PRINCIPAL', 0, 10)", produtoId);

        variacaoMId = UUID.randomUUID();
        jdbcTemplate.update("INSERT INTO produto_variacoes (id, produto_id, tamanho, preco, ativo) VALUES (?, ?, 'M', 22.00, true)", variacaoMId, produtoId);

        adicionalOvoId = UUID.randomUUID();
        jdbcTemplate.update("INSERT INTO adicionais (id, nome, preco, ativo) VALUES (?, 'Ovo', 3.00, true)", adicionalOvoId);
    }

    @Test
    @WithMockUser
    @DisplayName("E2E P0.4: Produto Carne, Var M (R$22) x 2, Ovo (R$3) -> Total 50, Estoque -2")
    void testFluxoComercialE2E() throws Exception {
        PedidoRequest req = new PedidoRequest(
                caixaId,
                new ClienteRequest("E2E Test", "5511000000000"),
                "RETIRADA",
                BigDecimal.ZERO,
                null,
                "Sem cebola",
                List.of(
                        new ItemPedidoRequest(variacaoMId, 2, List.of(adicionalOvoId), "Bem passado")
                ),
                new PagamentoRequest("PIX", new BigDecimal("50.00"), null, null),
                "APP",
                "evt-e2e-1"
        );

        mockMvc.perform(post("/api/pedidos")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("SUCCESS"))
                .andExpect(jsonPath("$.pedidoId").exists());

        Integer estoque = jdbcTemplate.queryForObject("SELECT estoque_atual FROM produtos WHERE nome = 'Carne'", Integer.class);
        org.junit.jupiter.api.Assertions.assertEquals(8, estoque, "Estoque devia ter diminuido em 2");

        Map<String, Object> pedido = jdbcTemplate.queryForMap("SELECT total, numero_comercial FROM pedidos WHERE provedor_evento = 'APP' AND external_event_id = 'evt-e2e-1'");
        org.junit.jupiter.api.Assertions.assertEquals(new BigDecimal("50.00"), pedido.get("total"));
        org.junit.jupiter.api.Assertions.assertTrue(((String) pedido.get("numero_comercial")).startsWith("#QP-"));

        Map<String, Object> item = jdbcTemplate.queryForMap("SELECT quantidade, preco_unitario_aplicado, subtotal_aplicado FROM itens_pedido LIMIT 1");
        org.junit.jupiter.api.Assertions.assertEquals(2, item.get("quantidade"));
        org.junit.jupiter.api.Assertions.assertEquals(new BigDecimal("22.00"), item.get("preco_unitario_aplicado"));
        org.junit.jupiter.api.Assertions.assertEquals(new BigDecimal("50.00"), item.get("subtotal_aplicado"));

        Map<String, Object> add = jdbcTemplate.queryForMap("SELECT preco_aplicado FROM pedido_item_adicionais LIMIT 1");
        org.junit.jupiter.api.Assertions.assertEquals(new BigDecimal("3.00"), add.get("preco_aplicado"));
    }
}
