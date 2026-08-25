package com.quentinhas.backend.dto.request;

import java.math.BigDecimal;

public class CaixaAbrirRequest {
    private BigDecimal saldoInicial;

    public CaixaAbrirRequest() {}

    public CaixaAbrirRequest(BigDecimal saldoInicial) {
        this.saldoInicial = saldoInicial;
    }

    public BigDecimal getSaldoInicial() {
        return saldoInicial;
    }

    public void setSaldoInicial(BigDecimal saldoInicial) {
        this.saldoInicial = saldoInicial;
    }
}
