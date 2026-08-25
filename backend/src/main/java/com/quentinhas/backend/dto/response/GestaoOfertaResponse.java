package com.quentinhas.backend.dto.response;

import java.math.BigDecimal;
import java.util.UUID;

public record GestaoOfertaResponse(
        UUID id,
        UUID produtoId,
        String produtoNome,
        String tamanho,
        BigDecimal precoVigente,
        Integer limiteProducao,
        Integer reservadoAtual,
        Boolean ativo
) {}
