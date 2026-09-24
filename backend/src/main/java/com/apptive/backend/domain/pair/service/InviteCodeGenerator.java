package com.apptive.backend.domain.pair.service;

import java.security.SecureRandom;

import org.springframework.stereotype.Component;

@Component
public class InviteCodeGenerator {

	private static final int CODE_BOUND = 1_000_000;
	private final SecureRandom secureRandom = new SecureRandom();

	public String generate() {
		return "%06d".formatted(secureRandom.nextInt(CODE_BOUND));
	}
}
