package com.quentinhas.backend.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.quentinhas.backend.dto.request.ProdutoRequest;
import com.quentinhas.backend.model.Produto;
import com.quentinhas.backend.repository.ProdutoRepository;
import com.quentinhas.backend.repository.OfertaRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
public class ProdutoIntegrationTest extends com.quentinhas.backend.AbstractIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ProdutoRepository produtoRepository;

    @Autowired
    private OfertaRepository ofertaRepository;

    private ObjectMapper objectMapper = new ObjectMapper();

    @BeforeEach
    void setUp() {
        ofertaRepository.deleteAll();
        produtoRepository.deleteAll();
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    void deveCriarProduto() throws Exception {
        ProdutoRequest request = new ProdutoRequest("Marmita Extra", "Teste", "Lanches", new BigDecimal("25.50"), 0, 8, true);
        
        mockMvc.perform(post("/api/gestao/produtos")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.nome").value("Marmita Extra"))
                .andExpect(jsonPath("$.precoBase").value(25.5));
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    void deveEditarProduto() throws Exception {
        Produto p = new Produto();
        p.setNome("Velho");
        p.setCategoria("Lanches");
        p.setPrecoBase(new BigDecimal("10.00"));
        p.setAtivo(true);
        p = produtoRepository.save(p);

        ProdutoRequest request = new ProdutoRequest("Novo", "Desc", "Lanches", new BigDecimal("15.00"), 0, 8, true);

        mockMvc.perform(put("/api/gestao/produtos/" + p.getId())
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nome").value("Novo"))
                .andExpect(jsonPath("$.precoBase").value(15.0));
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    void deveDesativarProduto() throws Exception {
        Produto p = new Produto();
        p.setNome("Apagar");
        p.setCategoria("Lanches");
        p.setPrecoBase(new BigDecimal("10.00"));
        p.setAtivo(true);
        p = produtoRepository.save(p);

        mockMvc.perform(delete("/api/gestao/produtos/" + p.getId()))
                .andExpect(status().isNoContent());

        mockMvc.perform(get("/api/gestao/produtos/" + p.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.ativo").value(false));
    }

    @Test
    void naoDeveCriarSemAdmin() throws Exception {
        ProdutoRequest request = new ProdutoRequest("Marmita Extra", "Teste", "Lanches", new BigDecimal("25.50"), 0, 8, true);
        
        mockMvc.perform(post("/api/gestao/produtos")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isForbidden());
    }
}
