package com.quentinhas.backend.model;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.util.UUID;

@Entity
@Table(name = "produto_variacoes")
public class ProdutoVariacao {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "produto_id", nullable = false)
    private Produto produto;

    @Column(nullable = false)
    private String tamanho;

    @Column(nullable = false)
    private BigDecimal preco;

    @Column(nullable = false)
    private boolean ativo = true;

    public ProdutoVariacao() {}

    public UUID getId() { return id; }
    public Produto getProduto() { return produto; }
    public String getTamanho() { return tamanho; }
    public BigDecimal getPreco() { return preco; }
    public boolean isAtivo() { return ativo; }

    public void setId(UUID id) { this.id = id; }
    public void setProduto(Produto produto) { this.produto = produto; }
    public void setTamanho(String tamanho) { this.tamanho = tamanho; }
    public void setPreco(BigDecimal preco) { this.preco = preco; }
    public void setAtivo(boolean ativo) { this.ativo = ativo; }
}
