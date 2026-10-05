package com.quentinhas.backend.repository;

import com.quentinhas.backend.model.Caixa;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface CaixaRepository extends JpaRepository<Caixa, UUID> {
    Optional<Caixa> findFirstByOperadorIdAndStatus(UUID operadorId, String status);
    Optional<Caixa> findFirstByTerminalIdAndStatus(String terminalId, String status);
}

