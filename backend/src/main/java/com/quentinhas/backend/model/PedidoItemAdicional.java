package com.quentinhas.backend.model;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.util.UUID;

@Entity
@Table(name = "pedido_item_adicionais")
public class PedidoItemAdicional {
    @EmbeddedId
    private PedidoItemAdicionalId id = new PedidoItemAdicionalId();

    @ManyToOne(fetch = FetchType.LAZY)
    @MapsId("itemPedidoId")
    @JoinColumn(name = "item_pedido_id", nullable = false)
    private ItemPedido itemPedido;

    @ManyToOne(fetch = FetchType.LAZY)
    @MapsId("adicionalId")
    @JoinColumn(name = "adicional_id", nullable = false)
    private Adicional adicional;

    @Column(name = "preco_aplicado", nullable = false)
    private BigDecimal precoAplicado;

    public PedidoItemAdicional() {}

    public PedidoItemAdicionalId getId() { return id; }
    public ItemPedido getItemPedido() { return itemPedido; }
    public Adicional getAdicional() { return adicional; }
    public BigDecimal getPrecoAplicado() { return precoAplicado; }

    public void setId(PedidoItemAdicionalId id) { this.id = id; }
    public void setItemPedido(ItemPedido itemPedido) { this.itemPedido = itemPedido; }
    public void setAdicional(Adicional adicional) { this.adicional = adicional; }
    public void setPrecoAplicado(BigDecimal precoAplicado) { this.precoAplicado = precoAplicado; }
}
