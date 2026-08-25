package com.quentinhas.backend.repository;

import com.quentinhas.backend.model.Cardapio;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface CardapioRepository extends JpaRepository<Cardapio, UUID> {
    Optional<Cardapio> findFirstByStatusOrderByDataReferenciaDesc(String status);
}
