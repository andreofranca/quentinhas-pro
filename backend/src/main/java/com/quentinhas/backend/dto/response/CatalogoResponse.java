package com.quentinhas.backend.dto.response;

import java.util.List;

public record CatalogoResponse(
        List<ProdutoCatalogoResponse> produtos,
        List<AdicionalResponse> adicionais
) {}
