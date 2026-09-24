package com.apptive.backend.domain.health.dto;

import java.time.OffsetDateTime;

public record HealthResponse(String status, OffsetDateTime timestamp) {
}
