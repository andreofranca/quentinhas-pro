package com.quentinhas.backend.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.quentinhas.backend.dto.request.EstoqueRequest;
import com.quentinhas.backend.model.Produto;
import com.quentinhas.backend.repository.ProdutoRepository;
import com.quentinhas.backend.repository.OfertaRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.util.UUID;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
public class EstoqueIntegrationTest extends com.quentinhas.backend.AbstractIntegrationTest { 
    @Autowired 
    private org.springframework.jdbc.core.JdbcTemplate jdbcTemplate;

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ProdutoRepository produtoRepository;

    @Autowired
    private OfertaRepository ofertaRepository;

    private ObjectMapper objectMapper = new ObjectMapper();

    private Produto produto1;

    @BeforeEach
    void setUp() {
        ofertaRepository.deleteAll();
        jdbcTemplate.execute("TRUNCATE TABLE produtos CASCADE");
        produto1 = new Produto();
        produto1.setNome("Produto Teste Estoque");
        produto1.setDescricao("Desc");
        produto1.setCategoria("Bebidas");
        produto1.setPrecoBase(new BigDecimal("5.00"));
        produto1.setEstoqueAtual(10);
        produto1.setEstoqueMinimo(5);
        produto1 = produtoRepository.save(produto1);
    }

    @Test
    @WithMockUser(roles = "ATENDENTE")
    void deveListarEstoque() throws Exception {
        mockMvc.perform(get("/api/gestao/estoque"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].nome").value("Produto Teste Estoque"))
                .andExpect(jsonPath("$[0].estoqueAtual").value(10));
    }

    @Test
    @WithMockUser(roles = "ATENDENTE")
    void deveBuscarEstoquePorProduto() throws Exception {
        mockMvc.perform(get("/api/gestao/estoque/" + produto1.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nome").value("Produto Teste Estoque"))
                .andExpect(jsonPath("$.estoqueMinimo").value(5));
    }

    @Test
    @WithMockUser(roles = "ATENDENTE")
    void atendenteNaoPodeAtualizarEstoque() throws Exception {
        EstoqueRequest req = new EstoqueRequest();
        req.setEstoqueAtual(20);
        req.setEstoqueMinimo(10);

        mockMvc.perform(put("/api/gestao/estoque/" + produto1.getId())
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    void adminDeveAtualizarEstoque() throws Exception {
        EstoqueRequest req = new EstoqueRequest();
        req.setEstoqueAtual(20);
        req.setEstoqueMinimo(10);

        mockMvc.perform(put("/api/gestao/estoque/" + produto1.getId())
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.estoqueAtual").value(20))
                .andExpect(jsonPath("$.estoqueMinimo").value(10));
    }
}

