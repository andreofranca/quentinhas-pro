package com.quentinhas.backend.repository;

import com.quentinhas.backend.model.Produto;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ProdutoRepository extends JpaRepository<Produto, UUID> {
    List<Produto> findAllByOrderByNomeAsc();
    List<Produto> findByAtivoTrueOrderByNomeAsc();
}
