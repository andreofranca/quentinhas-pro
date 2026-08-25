package com.quentinhas.backend.model;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.util.UUID;

@Entity
@Table(name = "ofertas")
public class Oferta {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "cardapio_id")
    private Cardapio cardapio;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "produto_id")
    private Produto produto;

    private String tamanho;

    @Column(name = "preco_vigente")
    private BigDecimal precoVigente;

    @Column(name = "limite_producao")
    private Integer limiteProducao;

    @Column(name = "reservado_atual")
    private Integer reservadoAtual;

    @Column(name = "ativo")
    private Boolean ativo = true;

    public Oferta() {}

    public boolean isDisponivel() {
        if (ativo != null && !ativo) return false;
        if (limiteProducao == null) return true;
        return (reservadoAtual != null ? reservadoAtual : 0) < limiteProducao;
    }

    public UUID getId() { return id; }
    public Cardapio getCardapio() { return cardapio; }
    public Produto getProduto() { return produto; }
    public String getTamanho() { return tamanho; }
    public BigDecimal getPrecoVigente() { return precoVigente; }
    public Integer getLimiteProducao() { return limiteProducao; }
    public Integer getReservadoAtual() { return reservadoAtual; }
    public Boolean getAtivo() { return ativo; }

    public void setId(UUID id) { this.id = id; }
    public void setCardapio(Cardapio cardapio) { this.cardapio = cardapio; }
    public void setProduto(Produto produto) { this.produto = produto; }
    public void setTamanho(String tamanho) { this.tamanho = tamanho; }
    public void setPrecoVigente(BigDecimal precoVigente) { this.precoVigente = precoVigente; }
    public void setLimiteProducao(Integer limiteProducao) { this.limiteProducao = limiteProducao; }
    public void setReservadoAtual(Integer reservadoAtual) { this.reservadoAtual = reservadoAtual; }
    public void setAtivo(Boolean ativo) { this.ativo = ativo; }
}
