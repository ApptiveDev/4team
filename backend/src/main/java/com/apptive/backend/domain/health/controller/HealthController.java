package com.apptive.backend.domain.health.controller;

import java.time.Clock;
import java.time.OffsetDateTime;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.apptive.backend.domain.health.dto.HealthResponse;

@RestController
@RequestMapping("/api/v1/health")
public class HealthController {

	private final Clock clock;

	public HealthController(Clock clock) {
		this.clock = clock;
	}

	@GetMapping
	public HealthResponse health() {
		return new HealthResponse("UP", OffsetDateTime.now(clock));
	}
}
