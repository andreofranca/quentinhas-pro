package com.quentinhas.backend.model;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.util.UUID;

@Entity
@Table(name = "adicionais")
public class Adicional {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false)
    private String nome;

    @Column(nullable = false)
    private BigDecimal preco;

    @Column(nullable = false)
    private boolean ativo = true;

    public Adicional() {}

    public UUID getId() { return id; }
    public String getNome() { return nome; }
    public BigDecimal getPreco() { return preco; }
    public boolean isAtivo() { return ativo; }

    public void setId(UUID id) { this.id = id; }
    public void setNome(String nome) { this.nome = nome; }
    public void setPreco(BigDecimal preco) { this.preco = preco; }
    public void setAtivo(boolean ativo) { this.ativo = ativo; }
}
