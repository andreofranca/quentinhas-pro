package com.quentinhas.backend.dto.response;

import java.math.BigDecimal;
import java.util.UUID;

public record ProdutoResponse(
    UUID id,
    String nome,
    String descricao,
    String categoria,
    BigDecimal precoBase,
    int estoqueAtual,
    int estoqueMinimo,
    boolean ativo
) {}
