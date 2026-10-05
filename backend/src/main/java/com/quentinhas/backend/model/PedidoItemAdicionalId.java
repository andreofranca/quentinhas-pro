package com.quentinhas.backend.model;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import java.io.Serializable;
import java.util.Objects;
import java.util.UUID;

@Embeddable
public class PedidoItemAdicionalId implements Serializable {
    @Column(name = "item_pedido_id")
    private UUID itemPedidoId;

    @Column(name = "adicional_id")
    private UUID adicionalId;

    public PedidoItemAdicionalId() {}

    public PedidoItemAdicionalId(UUID itemPedidoId, UUID adicionalId) {
        this.itemPedidoId = itemPedidoId;
        this.adicionalId = adicionalId;
    }

    public UUID getItemPedidoId() { return itemPedidoId; }
    public void setItemPedidoId(UUID itemPedidoId) { this.itemPedidoId = itemPedidoId; }
    public UUID getAdicionalId() { return adicionalId; }
    public void setAdicionalId(UUID adicionalId) { this.adicionalId = adicionalId; }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        PedidoItemAdicionalId that = (PedidoItemAdicionalId) o;
        return Objects.equals(itemPedidoId, that.itemPedidoId) &&
               Objects.equals(adicionalId, that.adicionalId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(itemPedidoId, adicionalId);
    }
}
