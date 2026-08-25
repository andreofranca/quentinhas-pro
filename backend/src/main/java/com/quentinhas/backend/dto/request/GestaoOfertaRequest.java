package com.quentinhas.backend.dto.request;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import java.math.BigDecimal;
import java.util.UUID;

public record GestaoOfertaRequest(
        UUID produtoId,
        String tamanho,
        @NotNull @PositiveOrZero BigDecimal precoVigente,
        @PositiveOrZero Integer limiteProducao,
        @NotNull Boolean ativo
) {}
