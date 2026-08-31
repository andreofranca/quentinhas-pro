package com.quentinhas.backend.dto.request;

import java.math.BigDecimal;

public record ProdutoRequest(
    String nome,
    String descricao,
    String categoria,
    BigDecimal precoBase,
    Integer estoqueAtual,
    Integer estoqueMinimo,
    Boolean ativo
) {}
