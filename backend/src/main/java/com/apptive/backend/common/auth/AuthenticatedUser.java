package com.apptive.backend.common.auth;

import com.apptive.backend.domain.user.entity.Role;

public record AuthenticatedUser(String userId, Role role) {
}
