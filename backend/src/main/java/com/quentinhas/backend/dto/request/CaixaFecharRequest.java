package com.quentinhas.backend.dto.request;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import java.math.BigDecimal;

public record CaixaFecharRequest(
        @NotNull @PositiveOrZero BigDecimal saldoInformado
) {}
