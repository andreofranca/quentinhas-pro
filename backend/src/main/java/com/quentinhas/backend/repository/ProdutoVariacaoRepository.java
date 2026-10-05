package com.quentinhas.backend.repository;

import com.quentinhas.backend.model.ProdutoVariacao;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface ProdutoVariacaoRepository extends JpaRepository<ProdutoVariacao, UUID> {
}
