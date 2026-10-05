package com.quentinhas.backend.model;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "pagamentos")
public class Pagamento {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "pedido_id", nullable = false)
    private Pedido pedido;

    @Column(name = "forma_pagamento", nullable = false)
    private String formaPagamento;

    @Column(nullable = false)
    private BigDecimal valor;

    @Column(name = "valor_recebido")
    private BigDecimal valorRecebido;

    private BigDecimal troco;

    @Column(name = "status_financeiro", nullable = false)
    private String statusFinanceiro = "CONCLUIDO";

    @Column(name = "registrado_em")
    private OffsetDateTime registradoEm = OffsetDateTime.now();

    public Pagamento() {}

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public Pedido getPedido() { return pedido; }
    public void setPedido(Pedido pedido) { this.pedido = pedido; }
    public String getFormaPagamento() { return formaPagamento; }
    public void setFormaPagamento(String formaPagamento) { this.formaPagamento = formaPagamento; }
    public BigDecimal getValor() { return valor; }
    public void setValor(BigDecimal valor) { this.valor = valor; }
    public BigDecimal getValorRecebido() { return valorRecebido; }
    public void setValorRecebido(BigDecimal valorRecebido) { this.valorRecebido = valorRecebido; }
    public BigDecimal getTroco() { return troco; }
    public void setTroco(BigDecimal troco) { this.troco = troco; }
    public String getStatusFinanceiro() { return statusFinanceiro; }
    public void setStatusFinanceiro(String statusFinanceiro) { this.statusFinanceiro = statusFinanceiro; }
    public OffsetDateTime getRegistradoEm() { return registradoEm; }
    public void setRegistradoEm(OffsetDateTime registradoEm) { this.registradoEm = registradoEm; }
}
