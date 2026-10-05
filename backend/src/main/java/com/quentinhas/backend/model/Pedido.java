package com.quentinhas.backend.model;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "pedidos")
public class Pedido {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "caixa_id")
    private UUID caixaId;

    @Column(name = "cliente_id")
    private UUID clienteId;

    @Column(name = "numero_comercial")
    private String numeroComercial;

    @Column(nullable = false)
    private BigDecimal total = BigDecimal.ZERO;

    @Column(name = "status_operacional", nullable = false)
    private String statusOperacional = "CONFIRMADO";

    @Column(name = "status_financeiro", nullable = false)
    private String statusFinanceiro = "PENDENTE";

    @Column(nullable = false)
    private String modalidade;

    @Column(name = "taxa_entrega", nullable = false)
    private BigDecimal taxaEntrega = BigDecimal.ZERO;

    @Column(name = "endereco_entrega")
    private String enderecoEntrega;

    private String observacoes;

    @Column(name = "provedor_evento")
    private String provedorEvento;

    @Column(name = "external_event_id")
    private String externalEventId;

    @Column(name = "criado_em")
    private OffsetDateTime criadoEm = OffsetDateTime.now();

    @OneToMany(mappedBy = "pedido", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<ItemPedido> itens = new ArrayList<>();

    @OneToMany(mappedBy = "pedido", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Pagamento> pagamentos = new ArrayList<>();

    public Pedido() {}

    public void adicionarItem(ItemPedido item) {
        itens.add(item);
        item.setPedido(this);
    }

    public void adicionarPagamento(Pagamento pagamento) {
        pagamentos.add(pagamento);
        pagamento.setPedido(this);
    }

    // Getters and Setters
    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getCaixaId() { return caixaId; }
    public void setCaixaId(UUID caixaId) { this.caixaId = caixaId; }
    public UUID getClienteId() { return clienteId; }
    public void setClienteId(UUID clienteId) { this.clienteId = clienteId; }
    public String getNumeroComercial() { return numeroComercial; }
    public void setNumeroComercial(String numeroComercial) { this.numeroComercial = numeroComercial; }
    public BigDecimal getTotal() { return total; }
    public void setTotal(BigDecimal total) { this.total = total; }
    public String getStatusOperacional() { return statusOperacional; }
    public void setStatusOperacional(String statusOperacional) { this.statusOperacional = statusOperacional; }
    public String getStatusFinanceiro() { return statusFinanceiro; }
    public void setStatusFinanceiro(String statusFinanceiro) { this.statusFinanceiro = statusFinanceiro; }
    public String getModalidade() { return modalidade; }
    public void setModalidade(String modalidade) { this.modalidade = modalidade; }
    public BigDecimal getTaxaEntrega() { return taxaEntrega; }
    public void setTaxaEntrega(BigDecimal taxaEntrega) { this.taxaEntrega = taxaEntrega; }
    public String getEnderecoEntrega() { return enderecoEntrega; }
    public void setEnderecoEntrega(String enderecoEntrega) { this.enderecoEntrega = enderecoEntrega; }
    public String getObservacoes() { return observacoes; }
    public void setObservacoes(String observacoes) { this.observacoes = observacoes; }
    public String getProvedorEvento() { return provedorEvento; }
    public void setProvedorEvento(String provedorEvento) { this.provedorEvento = provedorEvento; }
    public String getExternalEventId() { return externalEventId; }
    public void setExternalEventId(String externalEventId) { this.externalEventId = externalEventId; }
    public OffsetDateTime getCriadoEm() { return criadoEm; }
    public void setCriadoEm(OffsetDateTime criadoEm) { this.criadoEm = criadoEm; }
    public List<ItemPedido> getItens() { return itens; }
    public void setItens(List<ItemPedido> itens) { this.itens = itens; }
    public List<Pagamento> getPagamentos() { return pagamentos; }
    public void setPagamentos(List<Pagamento> pagamentos) { this.pagamentos = pagamentos; }
}
