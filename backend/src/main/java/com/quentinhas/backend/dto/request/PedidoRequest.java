package com.quentinhas.backend.dto.request;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

public record PedidoRequest(
        @NotNull UUID caixaId,
        @Valid ClienteRequest cliente,
        @NotBlank String modalidade,
        @NotNull @PositiveOrZero BigDecimal taxaEntrega,
        String enderecoEntrega,
        String observacoes,
        @NotNull @PositiveOrZero BigDecimal total,
        @NotEmpty @Valid List<ItemPedidoRequest> itens,
        @Valid PagamentoRequest pagamento,
        @NotBlank String provedorEvento,
        @NotBlank String externalEventId
) {}
