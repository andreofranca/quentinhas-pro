package com.quentinhas.backend.service;

import com.quentinhas.backend.dto.response.AdicionalResponse;
import com.quentinhas.backend.dto.response.CatalogoResponse;
import com.quentinhas.backend.dto.response.ProdutoCatalogoResponse;
import com.quentinhas.backend.dto.response.TamanhoCatalogoResponse;
import com.quentinhas.backend.dto.response.OfertaDetalheResponse;
import com.quentinhas.backend.model.Produto;
import com.quentinhas.backend.model.ProdutoVariacao;
import com.quentinhas.backend.model.Adicional;
import com.quentinhas.backend.repository.ProdutoVariacaoRepository;
import com.quentinhas.backend.repository.AdicionalRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class CatalogoService {

    private final ProdutoVariacaoRepository variacaoRepository;
    private final AdicionalRepository adicionalRepository;

    public CatalogoService(ProdutoVariacaoRepository variacaoRepository, AdicionalRepository adicionalRepository) {
        this.variacaoRepository = variacaoRepository;
        this.adicionalRepository = adicionalRepository;
    }

    public CatalogoResponse getCatalogoAtivo() {
        List<ProdutoVariacao> variacoesAtivas = variacaoRepository.findAll().stream()
                .filter(ProdutoVariacao::isAtivo)
                .collect(Collectors.toList());

        Map<Produto, List<ProdutoVariacao>> agrupadoPorProduto = variacoesAtivas.stream()
                .collect(Collectors.groupingBy(ProdutoVariacao::getProduto));

        List<ProdutoCatalogoResponse> produtosResponse = agrupadoPorProduto.entrySet().stream()
                .map(entry -> {
                    Produto produto = entry.getKey();
                    List<ProdutoVariacao> variacoesDoProduto = entry.getValue();

                    List<TamanhoCatalogoResponse> tamanhos = variacoesDoProduto.stream()
                            .map(variacao -> new TamanhoCatalogoResponse(
                                    variacao.getId(), 
                                    mapTamanhoToSigla(variacao.getTamanho()),
                                    variacao.getPreco(),
                                    produto.getEstoqueAtual() > 0
                            ))
                            .collect(Collectors.toList());

                    return new ProdutoCatalogoResponse(
                            produto.getId(),
                            produto.getNome(),
                            produto.getDescricao(),
                            produto.getCategoria(),
                              produto.getEstoqueAtual(),
                            tamanhos
                    );
                })
                .collect(Collectors.toList());

        List<AdicionalResponse> adicionais = adicionalRepository.findAll().stream()
                .filter(Adicional::isAtivo)
                .map(a -> new AdicionalResponse(a.getId(), a.getNome(), a.getPreco()))
                .collect(Collectors.toList());

        return new CatalogoResponse(produtosResponse, adicionais);
    }

    public OfertaDetalheResponse getOfertaDetalhe(UUID id) {
        ProdutoVariacao variacao = variacaoRepository.findById(id)
                .orElseThrow(() -> new java.util.NoSuchElementException("Variacao nao encontrada com id: " + id));

        return new OfertaDetalheResponse(
                variacao.getId(),
                variacao.getProduto().getId(),
                variacao.getProduto().getNome(),
                variacao.getProduto().getDescricao(),
                variacao.getProduto().getCategoria(),
                variacao.getTamanho(),
                variacao.getPreco(),
                variacao.getProduto().getEstoqueAtual() > 0
        );
    }

    private String mapTamanhoToSigla(String tamanho) {
        if (tamanho == null) return "";
        return switch (tamanho) {
            case "PEQUENA" -> "P";
            case "MEDIA" -> "M";
            case "GRANDE" -> "G";
            default -> tamanho.substring(0, 1);
        };
    }
}

