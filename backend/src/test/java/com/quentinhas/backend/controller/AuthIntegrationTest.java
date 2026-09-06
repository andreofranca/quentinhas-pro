package com.quentinhas.backend.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.quentinhas.backend.dto.request.LoginRequest;
import com.quentinhas.backend.dto.request.RegisterRequest;
import com.quentinhas.backend.model.Usuario;
import com.quentinhas.backend.repository.UsuarioRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.notNullValue;
import static org.hamcrest.Matchers.nullValue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@AutoConfigureMockMvc
class AuthIntegrationTest extends com.quentinhas.backend.AbstractIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Autowired
    private UsuarioRepository usuarioRepository;

    @Autowired
    private org.springframework.jdbc.core.JdbcTemplate jdbcTemplate;

    @BeforeEach
    void setUp() {
        jdbcTemplate.execute("TRUNCATE TABLE usuarios CASCADE");
    }

    @Test
    @DisplayName("Cadastro válido deve retornar token e não expor password_hash")
    void testCadastroValido() throws Exception {
        RegisterRequest request = new RegisterRequest("Operador Teste", "operador@test.com", "senha123", "GERENTE");

        mockMvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token", notNullValue()))
                .andExpect(jsonPath("$.usuario.email").value("operador@test.com"))
                .andExpect(jsonPath("$.usuario.nome").value("Operador Teste"))
                .andExpect(jsonPath("$.usuario.password_hash").doesNotExist())
                .andExpect(jsonPath("$.usuario.passwordHash").doesNotExist())
                .andExpect(jsonPath("$.usuario.senha").doesNotExist());
        
        Usuario salvo = usuarioRepository.findByEmail("operador@test.com").orElseThrow();
        assertThat(salvo.getPasswordHash()).isNotEqualTo("senha123"); // BCrypt foi aplicado
    }

    @Test
    @DisplayName("Cadastro com email duplicado deve falhar (ProblemDetail)")
    void testCadastroEmailDuplicado() throws Exception {
        RegisterRequest request = new RegisterRequest("Operador Teste", "duplicado@test.com", "senha123", "GERENTE");

        mockMvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk());

        mockMvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.detail").value("E-mail já cadastrado"));
    }

    @Test
    @DisplayName("Login válido deve retornar token e não expor senha")
    void testLoginValido() throws Exception {
        RegisterRequest regRequest = new RegisterRequest("Login Teste", "login@test.com", "senha123", "GERENTE");
        mockMvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(regRequest)))
                .andExpect(status().isOk());

        LoginRequest loginReq = new LoginRequest("login@test.com", "senha123");
        mockMvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(loginReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token", notNullValue()))
                .andExpect(jsonPath("$.usuario.email").value("login@test.com"))
                .andExpect(jsonPath("$.usuario.password_hash").doesNotExist());
    }

    @Test
    @DisplayName("Login com senha inválida deve retornar 401")
    void testLoginSenhaInvalida() throws Exception {
        RegisterRequest regRequest = new RegisterRequest("Login Teste", "login_errado@test.com", "senha123", "GERENTE");
        mockMvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(regRequest)))
                .andExpect(status().isOk());

        LoginRequest loginReq = new LoginRequest("login_errado@test.com", "senhaErrada");
        mockMvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(loginReq)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.detail").value("Credenciais inválidas ou token expirado"));
    }

    @Test
    @DisplayName("Login de usuário inexistente deve retornar 401")
    void testLoginUsuarioInexistente() throws Exception {
        LoginRequest loginReq = new LoginRequest("inexistente@test.com", "senha123");
        mockMvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(loginReq)))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("Acesso ao /me com JWT válido deve retornar dados sem password_hash")
    void testMeComTokenValido() throws Exception {
        RegisterRequest regRequest = new RegisterRequest("Me Teste", "me@test.com", "senha123", "ATENDENTE");
        String result = mockMvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(regRequest)))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();

        String token = objectMapper.readTree(result).get("token").asText();

        mockMvc.perform(get("/api/auth/me")
                .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email").value("me@test.com"))
                .andExpect(jsonPath("$.role").value("ATENDENTE"))
                .andExpect(jsonPath("$.nome").value("Me Teste"))
                .andExpect(jsonPath("$.password_hash").doesNotExist());
    }

    @Test
    @DisplayName("Acesso ao /me sem token deve ser rejeitado")
    void testMeSemToken() throws Exception {
        mockMvc.perform(get("/api/auth/me"))
                .andExpect(status().isForbidden()); // Dependendo de como Spring Security devolve para requests anon, pode ser 403. Let's fix Se for 403.
    }

    @Test
    @DisplayName("Acesso ao /me com JWT inválido deve ser rejeitado")
    void testMeComTokenInvalido() throws Exception {
        mockMvc.perform(get("/api/auth/me")
                .header("Authorization", "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI..."))
                .andExpect(status().isUnauthorized());
    }
}
