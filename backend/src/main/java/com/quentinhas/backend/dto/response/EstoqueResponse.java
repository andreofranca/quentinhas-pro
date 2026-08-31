package com.quentinhas.backend.dto.response;

import java.util.UUID;

public class EstoqueResponse {
    private UUID produtoId;
    private String nome;
    private String categoria;
    private int estoqueAtual;
    private int estoqueMinimo;

    public EstoqueResponse() {}

    public EstoqueResponse(UUID produtoId, String nome, String categoria, int estoqueAtual, int estoqueMinimo) {
        this.produtoId = produtoId;
        this.nome = nome;
        this.categoria = categoria;
        this.estoqueAtual = estoqueAtual;
        this.estoqueMinimo = estoqueMinimo;
    }

    public UUID getProdutoId() { return produtoId; }
    public void setProdutoId(UUID produtoId) { this.produtoId = produtoId; }
    public String getNome() { return nome; }
    public void setNome(String nome) { this.nome = nome; }
    public String getCategoria() { return categoria; }
    public void setCategoria(String categoria) { this.categoria = categoria; }
    public int getEstoqueAtual() { return estoqueAtual; }
    public void setEstoqueAtual(int estoqueAtual) { this.estoqueAtual = estoqueAtual; }
    public int getEstoqueMinimo() { return estoqueMinimo; }
    public void setEstoqueMinimo(int estoqueMinimo) { this.estoqueMinimo = estoqueMinimo; }
}
