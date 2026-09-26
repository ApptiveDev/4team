package com.apptive.backend.domain.recording.service;

public interface SpeechTranscriber {

	String transcribe(AudioSource audioSource);
}
