package com.quentinhas.backend.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record UsuarioAdminRequest(
    @NotBlank String nome,
    @NotBlank @Email String email,
    String senha,
    @NotBlank @Pattern(regexp = "ADMIN|GERENTE|ATENDENTE|COZINHA|CAIXA") String role,
    Boolean ativo
) {}
