package com.quentinhas.backend.controller;

import com.quentinhas.backend.dto.request.EstoqueRequest;
import com.quentinhas.backend.dto.response.EstoqueResponse;
import com.quentinhas.backend.model.Produto;
import com.quentinhas.backend.repository.ProdutoRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/gestao/estoque")
public class EstoqueController {

    private final ProdutoRepository produtoRepository;

    public EstoqueController(ProdutoRepository produtoRepository) {
        this.produtoRepository = produtoRepository;
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'ATENDENTE')")
    public ResponseEntity<List<EstoqueResponse>> listarEstoque() {
        List<EstoqueResponse> response = produtoRepository.findAll().stream()
                .filter(Produto::isAtivo)
                .map(this::toResponse)
                .collect(Collectors.toList());
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'ATENDENTE')")
    public ResponseEntity<EstoqueResponse> getEstoque(@PathVariable UUID id) {
        return produtoRepository.findById(id)
                .filter(Produto::isAtivo)
                .map(p -> ResponseEntity.ok(toResponse(p)))
                .orElse(ResponseEntity.notFound().build());
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<EstoqueResponse> atualizarEstoque(@PathVariable UUID id, @RequestBody EstoqueRequest request) {
        return produtoRepository.findById(id)
                .filter(Produto::isAtivo)
                .map(p -> {
                    p.setEstoqueAtual(request.getEstoqueAtual());
                    p.setEstoqueMinimo(request.getEstoqueMinimo());
                    produtoRepository.save(p);
                    return ResponseEntity.ok(toResponse(p));
                })
                .orElse(ResponseEntity.notFound().build());
    }

    private EstoqueResponse toResponse(Produto p) {
        return new EstoqueResponse(p.getId(), p.getNome(), p.getCategoria(), p.getEstoqueAtual(), p.getEstoqueMinimo());
    }
}
