package com.apptive.backend.domain.pair.dto;

import java.time.OffsetDateTime;

public record InvitationResponse(String invitationId, String inviteCode, OffsetDateTime expiresAt) {
}
