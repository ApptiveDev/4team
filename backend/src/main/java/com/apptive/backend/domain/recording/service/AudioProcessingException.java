package com.apptive.backend.domain.recording.service;

public class AudioProcessingException extends RuntimeException {

	private final String failedStage;
	private final String failureCode;

	public AudioProcessingException(String failedStage, String failureCode, Throwable cause) {
		super(failureCode, cause);
		this.failedStage = failedStage;
		this.failureCode = failureCode;
	}

	public AudioProcessingException(String failedStage, String failureCode) {
		this(failedStage, failureCode, null);
	}

	public String failedStage() {
		return failedStage;
	}

	public String failureCode() {
		return failureCode;
	}
}
