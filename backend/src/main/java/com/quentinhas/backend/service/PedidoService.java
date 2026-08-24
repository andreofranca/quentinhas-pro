package com.quentinhas.backend.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.quentinhas.backend.dto.request.PedidoRequest;
import com.quentinhas.backend.dto.response.PedidoResponse;
import com.quentinhas.backend.exception.BusinessRuleException;
import com.quentinhas.backend.exception.IdempotencyException;
import com.quentinhas.backend.exception.StockEsgotadoException;
import org.springframework.dao.DataAccessException;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import java.math.BigDecimal;

@Service
public class PedidoService {

    private final JdbcTemplate jdbcTemplate;
    private final ObjectMapper snakeCaseMapper;

    public PedidoService(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
        this.snakeCaseMapper = new ObjectMapper()
                .setPropertyNamingStrategy(PropertyNamingStrategies.SNAKE_CASE);
    }

    public PedidoResponse criarPedido(PedidoRequest request) {
        validarRegras(request);

        String payloadJson;
        try {
            payloadJson = snakeCaseMapper.writeValueAsString(request);
        } catch (JsonProcessingException e) {
            throw new RuntimeException("Erro ao serializar payload", e);
        }

        try {
            String resultJson = jdbcTemplate.queryForObject(
                    "SELECT rpc_processar_pedido(cast(? as jsonb))",
                    String.class,
                    payloadJson
            );

            return snakeCaseMapper.readValue(resultJson, PedidoResponse.class);

        } catch (DataIntegrityViolationException e) {
            if (e.getMessage() != null && e.getMessage().contains("pedidos_provedor_evento_external_event_id_key")) {
                throw new IdempotencyException("Pedido duplicado. Evento já processado.");
            }
            throw e;
        } catch (DataAccessException e) {
            String rootMessage = e.getRootCause() != null ? e.getRootCause().getMessage() : e.getMessage();
            if (rootMessage != null) {
                if (rootMessage.contains("Estoque esgotado")) {
                    throw new StockEsgotadoException(rootMessage);
                }
                if (rootMessage.contains("Caixa") || rootMessage.contains("Quantidade inv") || rootMessage.contains("Estoque")) {
                    throw new BusinessRuleException(rootMessage);
                }
            }
            throw e;
        } catch (Exception e) {
            throw new RuntimeException("Erro ao processar pedido", e);
        }
    }

    private void validarRegras(PedidoRequest request) {
        // Validação de troco
        if (request.pagamento() != null && "DINHEIRO".equalsIgnoreCase(request.pagamento().formaPagamento())) {
            BigDecimal recebido = request.pagamento().valorRecebido();
            BigDecimal total = request.pagamento().valor();
            BigDecimal troco = request.pagamento().troco();

            if (recebido == null || recebido.compareTo(total) < 0) {
                throw new IllegalArgumentException("Valor recebido insuficiente para pagamento em dinheiro.");
            }
            if (troco == null || recebido.subtract(total).compareTo(troco) != 0) {
                throw new IllegalArgumentException("Cálculo de troco inválido.");
            }
        }
        
        // Validação de total (itens + taxa)
        BigDecimal somaItens = request.itens().stream()
                .map(i -> i.subtotal())
                .reduce(BigDecimal.ZERO, BigDecimal::add);
                
        if (somaItens.add(request.taxaEntrega()).compareTo(request.total()) != 0) {
            throw new IllegalArgumentException("O total do pedido não corresponde à soma dos itens e taxa.");
        }
    }
}
