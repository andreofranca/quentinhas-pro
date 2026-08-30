package com.quentinhas.backend.dto.response;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

public record PedidoDetalheResponse(
        UUID id,
        String clienteNome,
        String clienteTelefone,
        String statusOperacional,
        String statusFinanceiro,
        String modalidade,
        String enderecoEntrega,
        BigDecimal taxaEntrega,
        String formaPagamento,
        BigDecimal troco,
        BigDecimal total,
        String registradoEm,
        List<ItemPedidoResponse> itens
) {}

