package com.quentinhas.backend.controller;

import com.quentinhas.backend.dto.response.CaixaResponse;
import com.quentinhas.backend.model.Caixa;
import com.quentinhas.backend.model.Usuario;
import com.quentinhas.backend.repository.CaixaRepository;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

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
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Nenhum caixa aberto encontrado para o usuário atual"));

        return ResponseEntity.ok(new CaixaResponse(
                caixa.getId(),
                caixa.getTerminalId(),
                caixa.getAbertoEm(),
                caixa.getStatus()
        ));
    }
}
