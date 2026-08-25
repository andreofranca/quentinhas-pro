package com.quentinhas.backend.dto.response;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

public record CaixaFechamentoResponse(
        UUID id,
        String terminalId,
        OffsetDateTime fechadoEm,
        BigDecimal saldoInicial,
        BigDecimal faturamentoSistema,
        BigDecimal saldoInformado,
        BigDecimal diferenca
) {}
