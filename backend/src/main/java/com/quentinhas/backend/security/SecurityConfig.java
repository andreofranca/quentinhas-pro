package com.quentinhas.backend.security;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable()) // API REST não usa CSRF
            .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS)) // Sem sessão de servidor
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/health").permitAll() // Health endpoint deve ser público
                .requestMatchers("/api/health/error").permitAll() // Público temporariamente para facilitar o teste de erro no lab
                .anyRequest().authenticated() // Bloqueia todos os outros
            );
            
        // Por ora, sem implementar JWT auth ou login, manteremos o padrão seguro
        // Qualquer chamada não mapeada retornará 401 Unauthorized ou 403 Forbidden.
        
        return http.build();
    }
}
