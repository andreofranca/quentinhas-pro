package com.quentinhas.backend.model;

import jakarta.persistence.*;
import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "cardapios")
public class Cardapio {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;
    
    @Column(name = "data_referencia")
    private LocalDate dataReferencia;
    
    private String status;

    public Cardapio() {}

    public UUID getId() { return id; }
    public LocalDate getDataReferencia() { return dataReferencia; }
    public String getStatus() { return status; }

    public void setId(UUID id) { this.id = id; }
    public void setDataReferencia(LocalDate dataReferencia) { this.dataReferencia = dataReferencia; }
    public void setStatus(String status) { this.status = status; }
}
