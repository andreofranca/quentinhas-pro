package com.quentinhas.backend.model;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "itens_pedido")
public class ItemPedido {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "pedido_id", nullable = false)
    private Pedido pedido;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "variacao_id")
    private ProdutoVariacao variacao;

    @Column(nullable = false)
    private int quantidade;

    @Column(name = "preco_unitario", nullable = false)
    private BigDecimal precoUnitario = BigDecimal.ZERO;

    @Column(nullable = false)
    private BigDecimal subtotal = BigDecimal.ZERO;

    @Column(name = "preco_unitario_aplicado")
    private BigDecimal precoUnitarioAplicado = BigDecimal.ZERO;

    @Column(name = "subtotal_aplicado")
    private BigDecimal subtotalAplicado = BigDecimal.ZERO;

    private String observacoes;

    @OneToMany(mappedBy = "itemPedido", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<PedidoItemAdicional> adicionais = new ArrayList<>();

    public ItemPedido() {}

    public void adicionarAdicional(PedidoItemAdicional adicional) {
        adicionais.add(adicional);
        adicional.setItemPedido(this);
    }

    // Getters and Setters
    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public Pedido getPedido() { return pedido; }
    public void setPedido(Pedido pedido) { this.pedido = pedido; }
    public ProdutoVariacao getVariacao() { return variacao; }
    public void setVariacao(ProdutoVariacao variacao) { this.variacao = variacao; }
    public int getQuantidade() { return quantidade; }
    public void setQuantidade(int quantidade) { this.quantidade = quantidade; }
    public BigDecimal getPrecoUnitario() { return precoUnitario; }
    public void setPrecoUnitario(BigDecimal precoUnitario) { this.precoUnitario = precoUnitario; }
    public BigDecimal getSubtotal() { return subtotal; }
    public void setSubtotal(BigDecimal subtotal) { this.subtotal = subtotal; }
    public BigDecimal getPrecoUnitarioAplicado() { return precoUnitarioAplicado; }
    public void setPrecoUnitarioAplicado(BigDecimal precoUnitarioAplicado) { this.precoUnitarioAplicado = precoUnitarioAplicado; }
    public BigDecimal getSubtotalAplicado() { return subtotalAplicado; }
    public void setSubtotalAplicado(BigDecimal subtotalAplicado) { this.subtotalAplicado = subtotalAplicado; }
    public String getObservacoes() { return observacoes; }
    public void setObservacoes(String observacoes) { this.observacoes = observacoes; }
    public List<PedidoItemAdicional> getAdicionais() { return adicionais; }
    public void setAdicionais(List<PedidoItemAdicional> adicionais) { this.adicionais = adicionais; }
}
