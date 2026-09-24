package com.apptive.backend.common.exception;

public record FieldErrorResponse(String field, String reason) {
}
