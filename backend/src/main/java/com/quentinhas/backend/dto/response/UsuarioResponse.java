package com.quentinhas.backend.dto.response;

import java.util.UUID;

public record UsuarioResponse(
        UUID id,
        String nome,
        String email,
        String role,
        boolean ativo
) {}
