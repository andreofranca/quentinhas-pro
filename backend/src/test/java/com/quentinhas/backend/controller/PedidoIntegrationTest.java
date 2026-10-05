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

@AutoConfigureMockMvc
class PedidoIntegrationTest extends com.quentinhas.backend.AbstractIntegrationTest {

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
        jdbcTemplate.update("INSERT INTO produtos (id, nome, categoria, preco_base, estoque_atual) VALUES (?, 'Teste', 'PRATO_PRINCIPAL', 0, 10)", produtoId);
        
        UUID cardapioId = UUID.randomUUID();
        jdbcTemplate.update("INSERT INTO cardapios (id, data_referencia, status) VALUES (?, CURRENT_DATE, 'ABERTO')", cardapioId);

        ofertaPId = UUID.randomUUID();
        jdbcTemplate.update("INSERT INTO produto_variacoes (id, produto_id, tamanho, preco, ativo) VALUES (?, ?, 'PEQUENA', 15.00, true)", ofertaPId, produtoId);

        ofertaGId = UUID.randomUUID();
        jdbcTemplate.update("INSERT INTO produto_variacoes (id, produto_id, tamanho, preco, ativo) VALUES (?, ?, 'GRANDE', 25.00, true)", ofertaGId, produtoId);
    }

    private PedidoRequest buildPedidoRequest(String evtId) {
        return new PedidoRequest(
                caixaId,
                new ClienteRequest("Joao", "5511999999999"),
                "RETIRADA",
                BigDecimal.ZERO,
                null,
                "",
                List.of(
                        new ItemPedidoRequest(ofertaPId, 1, java.util.List.of(), "")
                ),
                new PagamentoRequest("PIX", new java.math.BigDecimal("15.00"), null, null),
                "APP",
                evtId
        );
    }

    @Test
    @DisplayName("Deve ser bloqueado sem autenticacao")
    void testSemAutenticacao() throws Exception {
        PedidoRequest req = buildPedidoRequest("evt1");
        mockMvc.perform(post("/api/pedidos")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser
    @DisplayName("Deve criar pedido simples validado com sucesso e deduzir estoque")
    void testPedidoSimples() throws Exception {
        PedidoRequest req = buildPedidoRequest("evt2");
        mockMvc.perform(post("/api/pedidos")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("SUCCESS"))
                .andExpect(jsonPath("$.pedidoId").exists());
                
        // Garante que o estoque da proteina (Produto) foi deduzido (de 10 para 9)
        Integer estoque = jdbcTemplate.queryForObject("SELECT estoque_atual FROM produtos LIMIT 1", Integer.class);
        org.junit.jupiter.api.Assertions.assertEquals(9, estoque);
    }

    @Test
    @WithMockUser
    @DisplayName("Deve rejeitar pedido com externalEventId duplicado (Idempotencia)")
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
    @DisplayName("Deve testar a autoridade de preco do backend (ignorando qualquer valor externo)")
    void testAutoridadeDePrecoBackend() throws Exception {
        // Agora que o DTO nao aceita precos, a propria assinatura do teste garante que o cliente nao envia preco.
        // Nos enviaremos apenas o ID da variacao, que custa 15.00 no banco.
        PedidoRequest req = new PedidoRequest(caixaId, new ClienteRequest("A", "1"), "RETIRADA", BigDecimal.ZERO, null, "", 
                List.of(new ItemPedidoRequest(ofertaPId, 2, java.util.List.of(), "")), // 2 itens de 15.00 = 30.00
                new PagamentoRequest("PIX", new java.math.BigDecimal("30.00"), null, null), // Valor do pagamento validado contra o banco
                "APP", "evt-autoridade");

        // Realizamos a operacao
        String response = mockMvc.perform(post("/api/pedidos")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();

        // Verificamos no banco se o total foi salvo como 30.00
        BigDecimal totalPersistido = jdbcTemplate.queryForObject("SELECT total FROM pedidos ORDER BY criado_em DESC LIMIT 1", BigDecimal.class);
        org.junit.jupiter.api.Assertions.assertEquals(new java.math.BigDecimal("30.00"), totalPersistido);
    }

    @Test
    @WithMockUser
    @DisplayName("Deve rejeitar pagamento insuficiente (validando a nova regra de troco)")
    void testTrocoIncorreto() throws Exception {
        // Pedido de 1 item de 15.00. O cliente tenta pagar em DINHEIRO mas so entrega 10.00.
        PedidoRequest req = new PedidoRequest(caixaId, new ClienteRequest("A", "1"), "RETIRADA", BigDecimal.ZERO, null, "", 
                List.of(new ItemPedidoRequest(ofertaPId, 1, java.util.List.of(), "")),
                new PagamentoRequest("DINHEIRO", new java.math.BigDecimal("15.00"), new java.math.BigDecimal("10.00"), java.math.BigDecimal.ZERO),
                "APP", "evt-insuficiente");

        mockMvc.perform(post("/api/pedidos")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isUnprocessableEntity()) // mapeado a BusinessRuleException
                .andExpect(jsonPath("$.detail", containsString("insuficiente")));
    }
    
    @Test
    @WithMockUser
    @DisplayName("Deve permitir pagamento em DINHEIRO com valor recebido suficiente e backend calcula troco")
    void testTrocoCorreto() throws Exception {
        // Pedido de 15.00. Cliente entrega 20.00.
        PedidoRequest req = new PedidoRequest(caixaId, new ClienteRequest("A", "1"), "RETIRADA", BigDecimal.ZERO, null, "", 
                List.of(new ItemPedidoRequest(ofertaPId, 1, java.util.List.of(), "")),
                new PagamentoRequest("DINHEIRO", new java.math.BigDecimal("15.00"), new java.math.BigDecimal("20.00"), java.math.BigDecimal.ZERO),
                "APP", "evt-dinheiro");

        mockMvc.perform(post("/api/pedidos")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk());
                
        // Verificamos no banco se o troco foi persistido como 5.00 (20 recebido - 15 cobrado)
        BigDecimal trocoPersistido = jdbcTemplate.queryForObject("SELECT troco FROM pagamentos ORDER BY id DESC LIMIT 1", BigDecimal.class);
        org.junit.jupiter.api.Assertions.assertEquals(new java.math.BigDecimal("5.00"), trocoPersistido);
    }

    @Test
    @WithMockUser
    @DisplayName("Deve rejeitar 409 Conflict se tentar comprar oferta sem estoque (bloqueado pelo banco)")
    void testEstoqueEsgotado() throws Exception {
        jdbcTemplate.update("UPDATE produtos SET estoque_atual = 0");

        PedidoRequest req = new PedidoRequest(caixaId, new ClienteRequest("A", "1"), "RETIRADA", BigDecimal.ZERO, null, "", 
                java.util.List.of(new ItemPedidoRequest(ofertaGId, 1, java.util.List.of(), "")), 
                null, "APP", "evt-estoque-zero");

        mockMvc.perform(post("/api/pedidos")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.detail", containsString("Estoque esgotado")));
                
        jdbcTemplate.update("UPDATE produtos SET estoque_atual = 10");
    }

    @Test
    @WithMockUser
    @DisplayName("Deve validar 400 Bad Request Payload invalido via @Valid")
    void testPayloadInvalido() throws Exception {
        // DTO com nulls em campos obrigatorios
        PedidoRequest req = new PedidoRequest(caixaId, null, "", BigDecimal.ZERO, null, "", java.util.List.of(), null, "", "");
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
    @DisplayName("Deve validar 400 em transicao invalida")
    void testTransicaoInvalida() throws Exception {
        String payload = "{\"status\": \"STATUS_INVENTADO\"}";
        UUID dummyId = UUID.randomUUID();
        mockMvc.perform(post("/api/pedidos/" + dummyId + "/transicao")
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
                .andExpect(status().isBadRequest());
    }
}
