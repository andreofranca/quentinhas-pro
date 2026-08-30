package com.quentinhas.backend.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.quentinhas.backend.dto.request.ClienteRequest;
import com.quentinhas.backend.dto.request.ItemPedidoRequest;
import com.quentinhas.backend.dto.request.PagamentoRequest;
import com.quentinhas.backend.dto.request.PedidoRequest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static org.hamcrest.Matchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class PedidoIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    private ObjectMapper objectMapper = new ObjectMapper();

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private UUID caixaId;
    private UUID ofertaPId;
    private UUID ofertaGId;

    @BeforeEach
    void setUp() {
        jdbcTemplate.execute("TRUNCATE TABLE produtos CASCADE");
        jdbcTemplate.execute("TRUNCATE TABLE cardapios CASCADE");
        jdbcTemplate.execute("TRUNCATE TABLE ofertas CASCADE");
        jdbcTemplate.execute("TRUNCATE TABLE usuarios CASCADE");
        jdbcTemplate.execute("TRUNCATE TABLE caixas CASCADE");
        jdbcTemplate.execute("TRUNCATE TABLE pedidos CASCADE");
        jdbcTemplate.execute("TRUNCATE TABLE clientes CASCADE");
        jdbcTemplate.execute("DELETE FROM usuarios WHERE email = 'operador@test.com'");

        UUID userId = UUID.randomUUID();
        jdbcTemplate.update("INSERT INTO usuarios (id, nome, email, password_hash, role) VALUES (?, 'Operador', 'operador@test.com', 'hash', 'CAIXA')", userId);

        caixaId = UUID.randomUUID();
        jdbcTemplate.update("INSERT INTO caixas (id, operador_id, terminal_id, status) VALUES (?, ?, 'TEST', 'ABERTO')", caixaId, userId);

        UUID produtoId = UUID.randomUUID();
        jdbcTemplate.update("INSERT INTO produtos (id, nome, categoria, preco_base) VALUES (?, 'Teste', 'PRATO_PRINCIPAL', 0)", produtoId);
        
        UUID cardapioId = UUID.randomUUID();
        jdbcTemplate.update("INSERT INTO cardapios (id, data_referencia, status) VALUES (?, CURRENT_DATE, 'ABERTO')", cardapioId);

        ofertaPId = UUID.randomUUID();
        jdbcTemplate.update("INSERT INTO ofertas (id, cardapio_id, produto_id, tamanho, preco_vigente, limite_producao, reservado_atual) VALUES (?, ?, ?, 'PEQUENA', 15.00, 10, 0)", ofertaPId, cardapioId, produtoId);

        ofertaGId = UUID.randomUUID();
        // A oferta G tem apenas 1 de limite e 1 reservado (Esgotada)
        jdbcTemplate.update("INSERT INTO ofertas (id, cardapio_id, produto_id, tamanho, preco_vigente, limite_producao, reservado_atual) VALUES (?, ?, ?, 'GRANDE', 25.00, 1, 1)", ofertaGId, cardapioId, produtoId);
    }

    private PedidoRequest buildPedidoRequest(String evtId) {
        return new PedidoRequest(
                caixaId,
                new ClienteRequest("João", "5511999999999"),
                "RETIRADA",
                BigDecimal.ZERO,
                null,
                "",
                new BigDecimal("15.00"),
                List.of(
                        new ItemPedidoRequest(ofertaPId, 1, new BigDecimal("15.00"), new BigDecimal("15.00"))
                ),
                new PagamentoRequest("PIX", new BigDecimal("15.00"), new BigDecimal("15.00"), BigDecimal.ZERO),
                "APP",
                evtId
        );
    }

    @Test
    @DisplayName("Deve ser bloqueado sem autenticação")
    void testSemAutenticacao() throws Exception {
        PedidoRequest req = buildPedidoRequest("evt1");
        mockMvc.perform(post("/api/pedidos")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser
    @DisplayName("Deve criar pedido simples validado com sucesso")
    void testPedidoSimples() throws Exception {
        PedidoRequest req = buildPedidoRequest("evt2");
        mockMvc.perform(post("/api/pedidos")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("SUCCESS"))
                .andExpect(jsonPath("$.pedidoId").exists());
                
        // Garante que o reservado foi incrementado
        Integer reservado = jdbcTemplate.queryForObject("SELECT reservado_atual FROM ofertas WHERE id = ?", Integer.class, ofertaPId);
        org.junit.jupiter.api.Assertions.assertEquals(1, reservado);
    }

    @Test
    @WithMockUser
    @DisplayName("Deve rejeitar pedido com externalEventId duplicado (Idempotência)")
    void testIdempotencia() throws Exception {
        PedidoRequest req = buildPedidoRequest("evt-dup");
        
        // Primeiro passa
        mockMvc.perform(post("/api/pedidos")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk());

        // Segundo com mesmo ID rejeitado 409
        mockMvc.perform(post("/api/pedidos")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.detail", containsString("Pedido duplicado")));
    }

    @Test
    @WithMockUser
    @DisplayName("Deve rejeitar 400 Bad Request por matemática errada (Total vs Itens)")
    void testTotalInvalido() throws Exception {
        PedidoRequest req = new PedidoRequest(caixaId, new ClienteRequest("A", "1"), "RETIRADA", BigDecimal.ZERO, null, "", new BigDecimal("20.00"), // Errado, subtotal é 15
                List.of(new ItemPedidoRequest(ofertaPId, 1, new BigDecimal("15.00"), new BigDecimal("15.00"))),
                null, "APP", "evt3");

        mockMvc.perform(post("/api/pedidos")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.detail", containsString("O total do pedido não corresponde")));
    }

    @Test
    @WithMockUser
    @DisplayName("Deve rejeitar 400 Bad Request por troco incorreto")
    void testTrocoIncorreto() throws Exception {
        PedidoRequest req = new PedidoRequest(caixaId, new ClienteRequest("A", "1"), "RETIRADA", BigDecimal.ZERO, null, "", new BigDecimal("15.00"),
                List.of(new ItemPedidoRequest(ofertaPId, 1, new BigDecimal("15.00"), new BigDecimal("15.00"))),
                new PagamentoRequest("DINHEIRO", new BigDecimal("15.00"), new BigDecimal("20.00"), new BigDecimal("2.00")), // Troco errado
                "APP", "evt4");

        mockMvc.perform(post("/api/pedidos")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.detail", containsString("Cálculo de troco inválido")));
    }
    
    @Test
    @WithMockUser
    @DisplayName("Deve permitir pagamento em DINHEIRO com matemática de troco correta")
    void testTrocoCorreto() throws Exception {
        PedidoRequest req = new PedidoRequest(caixaId, new ClienteRequest("A", "1"), "RETIRADA", BigDecimal.ZERO, null, "", new BigDecimal("15.00"),
                List.of(new ItemPedidoRequest(ofertaPId, 1, new BigDecimal("15.00"), new BigDecimal("15.00"))),
                new PagamentoRequest("DINHEIRO", new BigDecimal("15.00"), new BigDecimal("20.00"), new BigDecimal("5.00")), // Troco correto = 5
                "APP", "evt-dinheiro");

        mockMvc.perform(post("/api/pedidos")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk());
    }

    @Test
    @WithMockUser
    @DisplayName("Deve rejeitar 409 Conflict se tentar comprar oferta sem estoque")
    void testEstoqueEsgotado() throws Exception {
        PedidoRequest req = new PedidoRequest(caixaId, new ClienteRequest("A", "1"), "RETIRADA", BigDecimal.ZERO, null, "", new BigDecimal("25.00"),
                List.of(new ItemPedidoRequest(ofertaGId, 1, new BigDecimal("25.00"), new BigDecimal("25.00"))),
                null, "APP", "evt5");

        mockMvc.perform(post("/api/pedidos")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.detail", containsString("Estoque esgotado")));
    }

    @Test
    @WithMockUser
    @DisplayName("Deve validar 400 Bad Request Payload inválido via @Valid")
    void testPayloadInvalido() throws Exception {
        PedidoRequest req = new PedidoRequest(caixaId, null, "", BigDecimal.ZERO, null, "", BigDecimal.ZERO, List.of(), null, "", "");
        mockMvc.perform(post("/api/pedidos")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("Deve retornar 403 Forbidden se GET sem JWT")
    void getPedidosUnauthorized() throws Exception {
        mockMvc.perform(get("/api/pedidos"))
               .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser
    @DisplayName("Deve retornar 200 OK com JWT na consulta de pedidos")
    void getPedidosOk() throws Exception {
        mockMvc.perform(get("/api/pedidos"))
               .andExpect(status().isOk());
    }

    @Test
    @WithMockUser
    @DisplayName("Deve validar 400 em transição inválida")
    void testTransicaoInvalida() throws Exception {
        String payload = "{\"status\": \"STATUS_INVENTADO\"}";
        UUID dummyId = UUID.randomUUID();
        // Since the DB has CHECK constraint on status, it should throw exception mapped to 400 or 500. But since we use simple update and no order exists, it should be 400 (IllegalArgumentException).
        mockMvc.perform(post("/api/pedidos/" + dummyId + "/transicao")
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
                .andExpect(status().isBadRequest()); // from IllegalArgumentException
    }
}
