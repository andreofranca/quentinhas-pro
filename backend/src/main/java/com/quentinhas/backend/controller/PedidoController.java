package com.quentinhas.backend.controller;

import com.quentinhas.backend.dto.request.PedidoRequest;
import com.quentinhas.backend.dto.response.PedidoResponse;
import com.quentinhas.backend.service.PedidoService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import java.util.List;
import java.util.UUID;
import com.quentinhas.backend.dto.response.PedidoDetalheResponse;
import com.quentinhas.backend.dto.request.TransicaoStatusRequest;

@RestController
@RequestMapping("/api/pedidos")
public class PedidoController {

    private final PedidoService pedidoService;

    public PedidoController(PedidoService pedidoService) {
        this.pedidoService = pedidoService;
    }

    @PostMapping
    public ResponseEntity<PedidoResponse> criarPedido(@RequestBody @Valid PedidoRequest request) {
        return ResponseEntity.ok(pedidoService.criarPedido(request));
    }

    @GetMapping
    public ResponseEntity<List<PedidoDetalheResponse>> obterPedidos() {
        return ResponseEntity.ok(pedidoService.obterPedidos());
    }

    @PostMapping("/{id}/transicao")
    public ResponseEntity<Void> transicao(@PathVariable UUID id, @RequestBody @Valid TransicaoStatusRequest request) {
        pedidoService.atualizarStatusOperacional(id, request.status());
        return ResponseEntity.ok().build();
    }
}
