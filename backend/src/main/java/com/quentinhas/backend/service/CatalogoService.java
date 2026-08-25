package com.quentinhas.backend.service;

import com.quentinhas.backend.dto.response.CatalogoResponse;
import com.quentinhas.backend.dto.response.OfertaDetalheResponse;
import com.quentinhas.backend.dto.response.ProdutoCatalogoResponse;
import com.quentinhas.backend.dto.response.TamanhoCatalogoResponse;
import com.quentinhas.backend.model.Oferta;
import com.quentinhas.backend.model.Produto;
import com.quentinhas.backend.repository.OfertaRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class CatalogoService {

    private final OfertaRepository ofertaRepository;

    public CatalogoService(OfertaRepository ofertaRepository) {
        this.ofertaRepository = ofertaRepository;
    }

    public CatalogoResponse getCatalogoAtivo() {
        List<Oferta> ofertasAtivas = ofertaRepository.findOfertasAtivas();

        Map<Produto, List<Oferta>> agrupadoPorProduto = ofertasAtivas.stream()
                .collect(Collectors.groupingBy(Oferta::getProduto));

        List<ProdutoCatalogoResponse> produtosResponse = agrupadoPorProduto.entrySet().stream()
                .map(entry -> {
                    Produto produto = entry.getKey();
                    List<Oferta> ofertasDoProduto = entry.getValue();

                    List<TamanhoCatalogoResponse> tamanhos = ofertasDoProduto.stream()
                            .filter(oferta -> oferta.getAtivo() != null && oferta.getAtivo())
                            .map(oferta -> new TamanhoCatalogoResponse(
                                    oferta.getId(),
                                    mapTamanhoToSigla(oferta.getTamanho()),
                                    oferta.getPrecoVigente(),
                                    oferta.isDisponivel()
                            ))
                            .collect(Collectors.toList());

                    return new ProdutoCatalogoResponse(
                            produto.getId(),
                            produto.getNome(),
                            produto.getDescricao(),
                            produto.getCategoria(),
                            tamanhos
                    );
                })
                .filter(produtoCatalogo -> !produtoCatalogo.tamanhos().isEmpty())
                .collect(Collectors.toList());

        return new CatalogoResponse(produtosResponse);
    }

    public OfertaDetalheResponse getOfertaDetalhe(UUID id) {
        Oferta oferta = ofertaRepository.findByIdWithProduto(id)
                .orElseThrow(() -> new java.util.NoSuchElementException("Oferta não encontrada com id: " + id));

        return new OfertaDetalheResponse(
                oferta.getId(),
                oferta.getProduto().getId(),
                oferta.getProduto().getNome(),
                oferta.getProduto().getDescricao(),
                oferta.getProduto().getCategoria(),
                oferta.getTamanho(),
                oferta.getPrecoVigente(),
                oferta.isDisponivel()
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
