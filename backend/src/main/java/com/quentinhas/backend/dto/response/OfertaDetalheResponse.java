package com.quentinhas.backend.dto.response;

import java.math.BigDecimal;
import java.util.UUID;

public record OfertaDetalheResponse(
        UUID id,
        UUID produtoId,
        String nomeProduto,
        String descricaoProduto,
        String categoria,
        String tamanho,
        BigDecimal preco,
        boolean disponivel
) {}
