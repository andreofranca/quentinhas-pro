package com.quentinhas.backend.dto.request;

import jakarta.validation.constraints.NotBlank;

public record TransicaoStatusRequest(
        @NotBlank String status
) {}

