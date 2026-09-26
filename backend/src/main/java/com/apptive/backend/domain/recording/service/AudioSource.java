package com.apptive.backend.domain.recording.service;

public record AudioSource(byte[] content, String filename, String contentType) {
}
