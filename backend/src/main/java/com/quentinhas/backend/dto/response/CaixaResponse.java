package com.quentinhas.backend.dto.response;

import java.time.OffsetDateTime;
import java.util.UUID;

public record CaixaResponse(
        UUID id,
        String terminalId,
        OffsetDateTime abertoEm,
        String status
) {}
