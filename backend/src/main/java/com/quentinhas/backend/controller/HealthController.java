package com.quentinhas.backend.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import java.util.Map;

@RestController
@RequestMapping("/api/health")
public class HealthController {

    @GetMapping
    public Map<String, String> healthCheck() {
        return Map.of(
            "status", "UP",
            "service", "quentinhas-pro-api"
        );
    }

    @GetMapping("/error")
    public Map<String, String> testError() {
        throw new RuntimeException("Test exception for problem detail");
    }
}
