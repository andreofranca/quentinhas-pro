package com.quentinhas.backend.dto.response;

public record AuthResponse(
        String token,
        UsuarioResponse usuario
) {}
