package com.quentinhas.backend.controller;

import com.quentinhas.backend.dto.request.GestaoOfertaRequest;
import com.quentinhas.backend.dto.response.GestaoOfertaResponse;
import com.quentinhas.backend.model.Cardapio;
import com.quentinhas.backend.model.Oferta;
import com.quentinhas.backend.model.Produto;
import com.quentinhas.backend.repository.CardapioRepository;
import com.quentinhas.backend.repository.OfertaRepository;
import com.quentinhas.backend.repository.ProdutoRepository;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/gestao/ofertas")
@PreAuthorize("hasAnyRole('ADMIN', 'GERENTE')")
public class GestaoCardapioController {

    private final OfertaRepository ofertaRepository;
    private final ProdutoRepository produtoRepository;
    private final CardapioRepository cardapioRepository;

    public GestaoCardapioController(OfertaRepository ofertaRepository, ProdutoRepository produtoRepository, CardapioRepository cardapioRepository) {
        this.ofertaRepository = ofertaRepository;
        this.produtoRepository = produtoRepository;
        this.cardapioRepository = cardapioRepository;
    }

    @GetMapping
    public ResponseEntity<List<GestaoOfertaResponse>> listarOfertas() {
        List<GestaoOfertaResponse> response = ofertaRepository.findOfertasAtivas().stream()
                .map(o -> new GestaoOfertaResponse(
                        o.getId(),
                        o.getProduto().getId(),
                        o.getProduto().getNome(),
                        o.getTamanho(),
                        o.getPrecoVigente(),
                        o.getLimiteProducao(),
                        o.getReservadoAtual(),
                        o.getAtivo()
                ))
                .collect(Collectors.toList());

        return ResponseEntity.ok(response);
    }

    @PostMapping
    public ResponseEntity<GestaoOfertaResponse> criarOferta(@RequestBody @Valid GestaoOfertaRequest request) {
        Cardapio cardapio = cardapioRepository.findFirstByStatusOrderByDataReferenciaDesc("ABERTO")
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Nenhum cardápio aberto"));

        Produto produto = produtoRepository.findById(request.produtoId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Produto não encontrado"));

        Oferta oferta = new Oferta();
        oferta.setCardapio(cardapio);
        oferta.setProduto(produto);
        oferta.setTamanho(request.tamanho());
        oferta.setPrecoVigente(request.precoVigente());
        oferta.setLimiteProducao(request.limiteProducao());
        oferta.setReservadoAtual(0);
        oferta.setAtivo(request.ativo() != null ? request.ativo() : true);

        ofertaRepository.save(oferta);

        return ResponseEntity.status(HttpStatus.CREATED).body(new GestaoOfertaResponse(
                oferta.getId(),
                produto.getId(),
                produto.getNome(),
                oferta.getTamanho(),
                oferta.getPrecoVigente(),
                oferta.getLimiteProducao(),
                oferta.getReservadoAtual(),
                oferta.getAtivo()
        ));
    }

    @PutMapping("/{id}")
    public ResponseEntity<GestaoOfertaResponse> editarOferta(@PathVariable UUID id, @RequestBody @Valid GestaoOfertaRequest request) {
        Oferta oferta = ofertaRepository.findByIdWithProduto(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Oferta não encontrada"));

        // Se o limiteProducao diminuir abaixo do reservado, rejeita
        if (request.limiteProducao() != null && request.limiteProducao() < (oferta.getReservadoAtual() != null ? oferta.getReservadoAtual() : 0)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Limite de produção não pode ser menor que a quantidade já reservada (" + oferta.getReservadoAtual() + ")");
        }

        oferta.setPrecoVigente(request.precoVigente());
        oferta.setLimiteProducao(request.limiteProducao());
        oferta.setAtivo(request.ativo());
        // produtoId e tamanho não mudam para uma oferta existente para não quebrar rastreabilidade

        ofertaRepository.save(oferta);

        return ResponseEntity.ok(new GestaoOfertaResponse(
                oferta.getId(),
                oferta.getProduto().getId(),
                oferta.getProduto().getNome(),
                oferta.getTamanho(),
                oferta.getPrecoVigente(),
                oferta.getLimiteProducao(),
                oferta.getReservadoAtual(),
                oferta.getAtivo()
        ));
    }
}
