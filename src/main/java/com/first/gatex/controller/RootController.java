package com.first.gatex.controller;


import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class RootController {

    @GetMapping("/")
    public Map<String, Object> root() {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("service", "GateX");
        body.put("description", "Lightweight API Gateway for Microservices");
        body.put("routes", List.of("/api/users/**", "/api/reports/**"));
        body.put("health", "/health");
        return body;
    }
}