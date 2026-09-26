package com.apptive.backend.infra.storage;

import java.time.OffsetDateTime;

public record SignedAudioUrl(String url, OffsetDateTime expiresAt) {
}
