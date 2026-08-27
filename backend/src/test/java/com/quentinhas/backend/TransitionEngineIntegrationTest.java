package com.quentinhas.backend;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;

import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.fail;

@SpringBootTest
@org.springframework.test.context.ActiveProfiles("test")
class TransitionEngineIntegrationTest {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    @DisplayName("Garante que a Transition Engine está materializada e acessível via JDBC na base conectada")
    void verifyTransitionEngineConnectivity() {
        // Envia um payload propositalmente inválido (caixa inexistente) para validar que a RPC processa e responde corretamente.
        String payload = "{\"caixa_id\": \"00000000-0000-0000-0000-000000000000\", \"itens\": []}";
        
        try {
            jdbcTemplate.queryForObject("SELECT rpc_processar_pedido(?::jsonb)", String.class, payload);
            fail("Deveria lançar exceção de caixa não aberto ou caixa fechado validado pela RPC.");
        } catch (Exception e) {
            String message = e.getMessage() != null ? e.getMessage() : "";
            assertTrue(
                message.contains("não está aberto") || message.contains("Caixa"),
                "A RPC deveria retornar um erro semântico de negócio, sinalizando sua operabilidade. Mensagem real: " + message
            );
        }
    }
}
