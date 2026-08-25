package com.quentinhas.backend.model;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Column;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "caixas")
public class Caixa {

    @Id
    private UUID id = UUID.randomUUID();

    @Column(name = "operador_id", nullable = false)
    private UUID operadorId;

    @Column(name = "terminal_id", nullable = false)
    private String terminalId = "CAIXA_BALCAO";

    @Column(name = "aberto_em", updatable = false)
    private OffsetDateTime abertoEm = OffsetDateTime.now();

    @Column(name = "fechado_em")
    private OffsetDateTime fechadoEm;

    @Column(nullable = false)
    private String status = "ABERTO";

    @Column(name = "saldo_inicial")
    private BigDecimal saldoInicial = BigDecimal.ZERO;

    @Column(name = "saldo_informado")
    private BigDecimal saldoInformado;

    public Caixa() {}

    public Caixa(UUID operadorId, String terminalId) {
        this.operadorId = operadorId;
        if (terminalId != null) {
            this.terminalId = terminalId;
        }
    }

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public UUID getOperadorId() {
        return operadorId;
    }

    public void setOperadorId(UUID operadorId) {
        this.operadorId = operadorId;
    }

    public String getTerminalId() {
        return terminalId;
    }

    public void setTerminalId(String terminalId) {
        this.terminalId = terminalId;
    }

    public OffsetDateTime getAbertoEm() {
        return abertoEm;
    }

    public void setAbertoEm(OffsetDateTime abertoEm) {
        this.abertoEm = abertoEm;
    }

    public OffsetDateTime getFechadoEm() {
        return fechadoEm;
    }

    public void setFechadoEm(OffsetDateTime fechadoEm) {
        this.fechadoEm = fechadoEm;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public BigDecimal getSaldoInicial() {
        return saldoInicial;
    }

    public void setSaldoInicial(BigDecimal saldoInicial) {
        this.saldoInicial = saldoInicial;
    }

    public BigDecimal getSaldoInformado() {
        return saldoInformado;
    }

    public void setSaldoInformado(BigDecimal saldoInformado) {
        this.saldoInformado = saldoInformado;
    }
}
