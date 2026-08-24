package com.quentinhas.backend.controller;

import com.quentinhas.backend.dto.response.CatalogoResponse;
import com.quentinhas.backend.dto.response.OfertaDetalheResponse;
import com.quentinhas.backend.service.CatalogoService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api")
public class CatalogoController {

    private final CatalogoService catalogoService;

    public CatalogoController(CatalogoService catalogoService) {
        this.catalogoService = catalogoService;
    }

    @GetMapping("/catalogo")
    public ResponseEntity<CatalogoResponse> getCatalogo() {
        return ResponseEntity.ok(catalogoService.getCatalogoAtivo());
    }

    @GetMapping("/ofertas/{id}")
    public ResponseEntity<OfertaDetalheResponse> getOfertaDetalhe(@PathVariable UUID id) {
        return ResponseEntity.ok(catalogoService.getOfertaDetalhe(id));
    }
}
