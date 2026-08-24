package com.quentinhas.backend.repository;

import com.quentinhas.backend.model.Oferta;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface OfertaRepository extends JpaRepository<Oferta, UUID> {
    
    @Query("SELECT o FROM Oferta o JOIN FETCH o.produto p JOIN o.cardapio c WHERE c.status = 'ABERTO'")
    List<Oferta> findOfertasAtivas();
    
    @Query("SELECT o FROM Oferta o JOIN FETCH o.produto WHERE o.id = :id")
    Optional<Oferta> findByIdWithProduto(@Param("id") UUID id);
}
