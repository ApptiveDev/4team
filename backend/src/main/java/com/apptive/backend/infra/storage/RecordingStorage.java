package com.apptive.backend.infra.storage;

import java.util.Optional;

import org.springframework.web.multipart.MultipartFile;

public interface RecordingStorage {

	String store(String recordingId, MultipartFile file);

	byte[] read(String objectKey);

	Optional<SignedAudioUrl> createSignedReadUrl(String objectKey);

	void delete(String objectKey);
}
