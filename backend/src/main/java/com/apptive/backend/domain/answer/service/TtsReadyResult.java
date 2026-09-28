package com.apptive.backend.domain.answer.service;

public record TtsReadyResult(boolean accepted, String previousObjectKey) {

	public static TtsReadyResult stale() {
		return new TtsReadyResult(false, null);
	}

	public static TtsReadyResult accepted(String previousObjectKey) {
		return new TtsReadyResult(true, previousObjectKey);
	}
}
