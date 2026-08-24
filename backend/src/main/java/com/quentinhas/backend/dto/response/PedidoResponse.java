package com.quentinhas.backend.dto.response;

import java.util.UUID;

public record PedidoResponse(
        UUID pedidoId,
        String status
) {}
