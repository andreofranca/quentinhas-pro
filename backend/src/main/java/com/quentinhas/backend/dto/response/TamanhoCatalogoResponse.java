package com.quentinhas.backend.dto.response;

import java.math.BigDecimal;
import java.util.UUID;

public record TamanhoCatalogoResponse(
        UUID ofertaId,
        String sigla,
        BigDecimal preco,
        boolean disponivel
) {}
