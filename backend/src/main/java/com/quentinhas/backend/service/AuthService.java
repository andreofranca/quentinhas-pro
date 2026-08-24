package com.quentinhas.backend.service;

import com.quentinhas.backend.dto.request.LoginRequest;
import com.quentinhas.backend.dto.request.RegisterRequest;
import com.quentinhas.backend.dto.response.AuthResponse;
import com.quentinhas.backend.dto.response.UsuarioResponse;
import com.quentinhas.backend.model.Usuario;
import com.quentinhas.backend.repository.UsuarioRepository;
import com.quentinhas.backend.security.JwtService;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class AuthService {

    private final UsuarioRepository repository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final AuthenticationManager authenticationManager;

    public AuthService(
            UsuarioRepository repository,
            PasswordEncoder passwordEncoder,
            JwtService jwtService,
            AuthenticationManager authenticationManager
    ) {
        this.repository = repository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
        this.authenticationManager = authenticationManager;
    }

    public AuthResponse register(RegisterRequest request) {
        if (repository.existsByEmail(request.email())) {
            throw new IllegalArgumentException("E-mail já cadastrado");
        }

        Usuario usuario = new Usuario(
                request.nome(),
                request.email(),
                passwordEncoder.encode(request.senha()),
                request.role()
        );

        repository.save(usuario);
        String jwtToken = jwtService.generateToken(usuario);

        return new AuthResponse(
                jwtToken,
                new UsuarioResponse(usuario.getId(), usuario.getNome(), usuario.getEmail(), usuario.getRole())
        );
    }

    public AuthResponse login(LoginRequest request) {
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        request.email(),
                        request.senha()
                )
        );

        Usuario usuario = repository.findByEmail(request.email())
                .orElseThrow(() -> new IllegalArgumentException("E-mail ou senha inválidos"));

        String jwtToken = jwtService.generateToken(usuario);

        return new AuthResponse(
                jwtToken,
                new UsuarioResponse(usuario.getId(), usuario.getNome(), usuario.getEmail(), usuario.getRole())
        );
    }
}
