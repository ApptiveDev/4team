package com.apptive.backend.common.id;

import java.util.UUID;

import org.springframework.stereotype.Component;

@Component
public class IdGenerator {

	public String generate(String prefix) {
		return prefix + "_" + UUID.randomUUID().toString().replace("-", "");
	}
}
