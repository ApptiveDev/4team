package com.apptive.backend.common.auth;

import java.time.OffsetDateTime;

public record IssuedToken(String value, OffsetDateTime expiresAt) {
}
