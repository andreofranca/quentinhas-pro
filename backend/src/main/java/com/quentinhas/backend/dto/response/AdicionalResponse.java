package com.quentinhas.backend.dto.response;

import java.math.BigDecimal;
import java.util.UUID;

public record AdicionalResponse(
        UUID id,
        String nome,
        BigDecimal preco
) {}
