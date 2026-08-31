package com.quentinhas.backend.model;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.util.UUID;

@Entity
@Table(name = "produtos")
public class Produto {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;
    
    private String nome;
    private String descricao;
    private String categoria;
    
    @Column(name = "preco_base")
    private BigDecimal precoBase;

    @Column(nullable = false)
    private boolean ativo = true;

    @Column(name = "estoque_atual", nullable = false)
    private int estoqueAtual = 0;

    @Column(name = "estoque_minimo", nullable = false)
    private int estoqueMinimo = 8;

    public Produto() {}

    public UUID getId() { return id; }
    public String getNome() { return nome; }
    public String getDescricao() { return descricao; }
    public String getCategoria() { return categoria; }
    public BigDecimal getPrecoBase() { return precoBase; }
    public boolean isAtivo() { return ativo; }
    public int getEstoqueAtual() { return estoqueAtual; }
    public int getEstoqueMinimo() { return estoqueMinimo; }

    public void setId(UUID id) { this.id = id; }
    public void setNome(String nome) { this.nome = nome; }
    public void setDescricao(String descricao) { this.descricao = descricao; }
    public void setCategoria(String categoria) { this.categoria = categoria; }
    public void setPrecoBase(BigDecimal precoBase) { this.precoBase = precoBase; }
    public void setAtivo(boolean ativo) { this.ativo = ativo; }
    public void setEstoqueAtual(int estoqueAtual) { this.estoqueAtual = estoqueAtual; }
    public void setEstoqueMinimo(int estoqueMinimo) { this.estoqueMinimo = estoqueMinimo; }
}
