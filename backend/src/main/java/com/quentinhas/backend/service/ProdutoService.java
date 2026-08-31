package com.quentinhas.backend.service;

import com.quentinhas.backend.dto.request.ProdutoRequest;
import com.quentinhas.backend.dto.response.ProdutoResponse;
import com.quentinhas.backend.model.Produto;
import com.quentinhas.backend.repository.ProdutoRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class ProdutoService {

    private final ProdutoRepository produtoRepository;

    public ProdutoService(ProdutoRepository produtoRepository) {
        this.produtoRepository = produtoRepository;
    }

    public List<ProdutoResponse> listarTodos() {
        return produtoRepository.findAllByOrderByNomeAsc().stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    public List<ProdutoResponse> listarAtivos() {
        return produtoRepository.findByAtivoTrueOrderByNomeAsc().stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    public ProdutoResponse buscarPorId(UUID id) {
        Produto produto = produtoRepository.findById(id)
                .orElseThrow(() -> new java.util.NoSuchElementException("Produto não encontrado."));
        return toResponse(produto);
    }

    @Transactional
    public ProdutoResponse criar(ProdutoRequest request) {
        Produto produto = new Produto();
        produto.setNome(request.nome());
        produto.setDescricao(request.descricao());
        produto.setCategoria(request.categoria());
        produto.setPrecoBase(request.precoBase());
        if (request.estoqueAtual() != null) produto.setEstoqueAtual(request.estoqueAtual());
        if (request.estoqueMinimo() != null) produto.setEstoqueMinimo(request.estoqueMinimo());
        if (request.ativo() != null) produto.setAtivo(request.ativo());
        
        produtoRepository.save(produto);
        return toResponse(produto);
    }

    @Transactional
    public ProdutoResponse atualizar(UUID id, ProdutoRequest request) {
        Produto produto = produtoRepository.findById(id)
                .orElseThrow(() -> new java.util.NoSuchElementException("Produto não encontrado."));
        
        produto.setNome(request.nome());
        produto.setDescricao(request.descricao());
        produto.setCategoria(request.categoria());
        produto.setPrecoBase(request.precoBase());
        if (request.estoqueAtual() != null) produto.setEstoqueAtual(request.estoqueAtual());
        if (request.estoqueMinimo() != null) produto.setEstoqueMinimo(request.estoqueMinimo());
        if (request.ativo() != null) produto.setAtivo(request.ativo());

        produtoRepository.save(produto);
        return toResponse(produto);
    }

    @Transactional
    public void desativar(UUID id) {
        Produto produto = produtoRepository.findById(id)
                .orElseThrow(() -> new java.util.NoSuchElementException("Produto não encontrado."));
        produto.setAtivo(false);
        produtoRepository.save(produto);
    }

    private ProdutoResponse toResponse(Produto produto) {
        return new ProdutoResponse(
                produto.getId(),
                produto.getNome(),
                produto.getDescricao(),
                produto.getCategoria(),
                produto.getPrecoBase(),
                produto.getEstoqueAtual(),
                produto.getEstoqueMinimo(),
                produto.isAtivo()
        );
    }
}
