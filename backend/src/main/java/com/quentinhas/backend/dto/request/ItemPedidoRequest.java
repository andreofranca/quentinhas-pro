package com.quentinhas.backend.dto.request;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import java.math.BigDecimal;
import java.util.UUID;

public record ItemPedidoRequest(
        @NotNull UUID ofertaId,
        @NotNull @Positive Integer quantidade,
        @NotNull @Positive BigDecimal precoUnitario,
        @NotNull @Positive BigDecimal subtotal
) {}
