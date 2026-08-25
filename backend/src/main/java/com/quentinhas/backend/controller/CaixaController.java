package com.quentinhas.backend.controller;

import com.quentinhas.backend.dto.request.CaixaAbrirRequest;
import com.quentinhas.backend.dto.response.CaixaResponse;
import com.quentinhas.backend.model.Caixa;
import com.quentinhas.backend.model.Usuario;
import com.quentinhas.backend.repository.CaixaRepository;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.time.OffsetDateTime;

@RestController
@RequestMapping("/api/caixas")
public class CaixaController {

    private final CaixaRepository caixaRepository;

    public CaixaController(CaixaRepository caixaRepository) {
        this.caixaRepository = caixaRepository;
    }

    @GetMapping("/ativo")
    public ResponseEntity<CaixaResponse> getAtivo(@AuthenticationPrincipal Usuario currentUser) {
        Caixa caixa = caixaRepository.findFirstByOperadorIdAndStatus(currentUser.getId(), "ABERTO")
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Nenhum caixa aberto encontrado para o usurio atual"));

        return ResponseEntity.ok(new CaixaResponse(
                caixa.getId(),
                caixa.getTerminalId(),
                caixa.getAbertoEm(),
                caixa.getStatus()
        ));
    }

    @PostMapping("/abrir")
    public ResponseEntity<CaixaResponse> abrirCaixa(@RequestBody CaixaAbrirRequest request, @AuthenticationPrincipal Usuario currentUser) {
        if (request.getSaldoInicial() == null || request.getSaldoInicial().compareTo(java.math.BigDecimal.ZERO) < 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Saldo inicial invalido");
        }

        if (caixaRepository.findFirstByOperadorIdAndStatus(currentUser.getId(), "ABERTO").isPresent()) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "J existe um caixa aberto para este operador");
        }

        Caixa novoCaixa = new Caixa();
        novoCaixa.setOperadorId(currentUser.getId());
        novoCaixa.setTerminalId("PDV-01");
        novoCaixa.setStatus("ABERTO");
        novoCaixa.setAbertoEm(OffsetDateTime.now());
        novoCaixa.setSaldoInicial(request.getSaldoInicial());

        caixaRepository.save(novoCaixa);

        return ResponseEntity.status(HttpStatus.CREATED).body(new CaixaResponse(
                novoCaixa.getId(),
                novoCaixa.getTerminalId(),
                novoCaixa.getAbertoEm(),
                novoCaixa.getStatus()
        ));
    }
}
