package com.apptive.backend.domain.assignment.dto;

import java.time.OffsetDateTime;

import com.apptive.backend.domain.recording.entity.ProcessingStatus;
import com.apptive.backend.domain.recording.entity.Recording;

public record VoiceTodayAnswerResponse(
	String type,
	String recordingId,
	ProcessingStatus processingStatus,
	String originalAudioUrl,
	OffsetDateTime originalAudioExpiresAt,
	String sttText,
	String summaryText,
	String processingNotice
) implements TodayAnswerResponse {

	public static VoiceTodayAnswerResponse from(Recording recording) {
		return new VoiceTodayAnswerResponse(
			"VOICE",
			recording.getId(),
			recording.getProcessingStatus(),
			null,
			null,
			recording.getSttText(),
			recording.getSummaryText(),
			recording.getProcessingNotice()
		);
	}
}
