package com.quentinhas.backend.dto.response;

import java.math.BigDecimal;
import java.util.UUID;

public record ItemPedidoResponse(
        UUID ofertaId,
        String nomeProduto,
        String siglaTamanho,
        Integer quantidade,
        BigDecimal precoUnitario,
        BigDecimal subtotal
) {}

