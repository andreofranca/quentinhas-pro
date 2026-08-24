package com.quentinhas.backend.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import java.math.BigDecimal;

public record PagamentoRequest(
        @NotBlank String formaPagamento,
        @NotNull @Positive BigDecimal valor,
        BigDecimal valorRecebido,
        BigDecimal troco
) {}
