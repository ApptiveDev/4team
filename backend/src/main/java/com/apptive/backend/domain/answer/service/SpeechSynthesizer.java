package com.apptive.backend.domain.answer.service;

public interface SpeechSynthesizer {

	byte[] synthesize(String text);
}
