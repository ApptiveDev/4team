package com.apptive.backend.infra.storage;

import java.util.Optional;

import org.springframework.web.multipart.MultipartFile;

public interface RecordingStorage {

	String store(String recordingId, MultipartFile file);

	String storeAnswerAudio(String answerId, byte[] audio);

	byte[] read(String objectKey);

	Optional<SignedAudioUrl> createSignedReadUrl(String objectKey);

	void delete(String objectKey);
}
