package com.apptive.backend.domain.user.service;

import com.apptive.backend.domain.user.dto.CreateUserResponse;

public record UserRegistrationResult(CreateUserResponse response, boolean created) {
}
