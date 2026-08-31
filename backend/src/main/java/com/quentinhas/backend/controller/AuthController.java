package com.quentinhas.backend.controller;

import com.quentinhas.backend.dto.request.LoginRequest;
import com.quentinhas.backend.dto.request.RegisterRequest;
import com.quentinhas.backend.dto.response.AuthResponse;
import com.quentinhas.backend.dto.response.UsuarioResponse;
import com.quentinhas.backend.model.Usuario;
import com.quentinhas.backend.service.AuthService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest request) {
        return ResponseEntity.ok(authService.register(request));
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        return ResponseEntity.ok(authService.login(request));
    }

    @GetMapping("/me")
    public ResponseEntity<UsuarioResponse> getMe(@AuthenticationPrincipal Usuario currentUser) {
        return ResponseEntity.ok(
                new UsuarioResponse(
                        currentUser.getId(),
                        currentUser.getNome(),
                        currentUser.getEmail(),
                        currentUser.getRole(),
                        currentUser.isAtivo()
                )
        );
    }
}
