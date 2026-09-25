package com.apptive.backend.infra.storage;

import org.springframework.web.multipart.MultipartFile;

public interface RecordingStorage {

	String store(String recordingId, MultipartFile file);

	void delete(String objectKey);
}
