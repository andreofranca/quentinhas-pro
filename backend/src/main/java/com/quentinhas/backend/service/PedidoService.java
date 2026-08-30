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
import java.util.List;
import java.util.UUID;
import com.fasterxml.jackson.core.type.TypeReference;
import com.quentinhas.backend.dto.response.PedidoDetalheResponse;

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

    public List<PedidoDetalheResponse> obterPedidos() {
        String sql = """
            SELECT json_agg(
                json_build_object(
                    'id', p.id,
                    'cliente_nome', c.nome,
                    'cliente_telefone', c.telefone,
                    'status_operacional', p.status_operacional,
                    'status_financeiro', p.status_financeiro,
                    'modalidade', p.modalidade,
                    'endereco_entrega', p.endereco_entrega,
                    'taxa_entrega', p.taxa_entrega,
                    'forma_pagamento', pg.forma_pagamento,
                    'troco', pg.troco,
                    'total', p.total,
                    'registrado_em', p.criado_em,
                    'itens', COALESCE((
                         SELECT json_agg(json_build_object(
                             'oferta_id', ip.oferta_id,
                             'nome_produto', pr.nome,
                             'sigla_tamanho', o.tamanho,
                             'quantidade', ip.quantidade,
                             'preco_unitario', ip.preco_unitario,
                             'subtotal', ip.subtotal
                         ))
                         FROM itens_pedido ip
                         LEFT JOIN ofertas o ON ip.oferta_id = o.id
                         LEFT JOIN produtos pr ON o.produto_id = pr.id
                         WHERE ip.pedido_id = p.id
                    ), '[]'::json)
                )
            )
            FROM pedidos p
            LEFT JOIN clientes c ON p.cliente_id = c.id
            LEFT JOIN pagamentos pg ON pg.pedido_id = p.id
            WHERE p.status_operacional != 'ENTREGUE' AND p.status_operacional != 'CANCELADO'
            """;

        String jsonResult = jdbcTemplate.queryForObject(sql, String.class);
        if (jsonResult == null || jsonResult.equals("null")) {
            return List.of();
        }
        
        try {
            return snakeCaseMapper.readValue(jsonResult, new TypeReference<List<PedidoDetalheResponse>>() {});
        } catch (JsonProcessingException e) {
            throw new RuntimeException("Erro ao converter json dos pedidos", e);
        }
    }

    public void atualizarStatusOperacional(UUID pedidoId, String status) {
        int updated = jdbcTemplate.update(
            "UPDATE pedidos SET status_operacional = ? WHERE id = ?",
            status, pedidoId
        );
        if (updated == 0) {
            throw new IllegalArgumentException("Pedido não encontrado");
        }
    }
}
