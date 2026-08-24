package com.quentinhas.backend.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record RegisterRequest(
        @NotBlank(message = "Nome é obrigatório")
        String nome,
        
        @NotBlank(message = "E-mail é obrigatório")
        @Email(message = "E-mail inválido")
        String email,
        
        @NotBlank(message = "Senha é obrigatória")
        String senha,
        
        @NotBlank(message = "Role é obrigatória")
        @Pattern(regexp = "ADMIN|GERENTE|ATENDENTE|COZINHA|CAIXA", message = "Role inválida")
        String role
) {}
