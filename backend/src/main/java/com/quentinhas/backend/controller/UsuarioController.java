package com.quentinhas.backend.controller;

import com.quentinhas.backend.dto.request.UsuarioAdminRequest;
import com.quentinhas.backend.dto.response.UsuarioResponse;
import com.quentinhas.backend.model.Usuario;
import com.quentinhas.backend.repository.UsuarioRepository;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/gestao/usuarios")
@PreAuthorize("hasRole('ADMIN')")
public class UsuarioController {
  private final UsuarioRepository repository; private final PasswordEncoder encoder;
  public UsuarioController(UsuarioRepository repository, PasswordEncoder encoder) { this.repository = repository; this.encoder = encoder; }
  @GetMapping public List<UsuarioResponse> listar() { return repository.findAll().stream().map(this::response).toList(); }
  @PostMapping @ResponseStatus(HttpStatus.CREATED) public UsuarioResponse criar(@RequestBody @Valid UsuarioAdminRequest r) {
    if (repository.existsByEmail(r.email())) throw new IllegalArgumentException("E-mail já cadastrado");
    if (r.senha() == null || r.senha().isBlank()) throw new IllegalArgumentException("Senha é obrigatória");
    Usuario u = new Usuario(r.nome(), r.email(), encoder.encode(r.senha()), r.role()); if (r.ativo()!=null) u.setAtivo(r.ativo()); return response(repository.save(u)); }
  @PutMapping("/{id}") public UsuarioResponse atualizar(@PathVariable UUID id, @RequestBody @Valid UsuarioAdminRequest r) {
    Usuario u=repository.findById(id).orElseThrow(()->new java.util.NoSuchElementException("Usuário não encontrado")); u.setNome(r.nome()); u.setEmail(r.email()); u.setRole(r.role()); if(r.senha()!=null&&!r.senha().isBlank())u.setPasswordHash(encoder.encode(r.senha())); if(r.ativo()!=null)u.setAtivo(r.ativo()); return response(repository.save(u)); }
  private UsuarioResponse response(Usuario u) { return new UsuarioResponse(u.getId(),u.getNome(),u.getEmail(),u.getRole(),u.isAtivo()); }
}
