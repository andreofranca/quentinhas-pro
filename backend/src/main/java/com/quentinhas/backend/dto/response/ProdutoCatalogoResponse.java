package com.quentinhas.backend.dto.response;

import java.util.List;
import java.util.UUID;

public record ProdutoCatalogoResponse(
        UUID id,
        String nome,
        String descricao,
        String categoria,
        Integer estoqueAtual,
        List<TamanhoCatalogoResponse> tamanhos
) {}

