package com.quentinhas.backend.dto.request;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import java.util.List;
import java.util.UUID;

public record ItemPedidoRequest(
        @NotNull UUID variacaoId,
        @NotNull @Positive Integer quantidade,
        List<UUID> adicionaisIds,
        String observacoes
) {}
