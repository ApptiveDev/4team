package com.apptive.backend.domain.recording.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

@Component
public class MockRecordingProcessor {

	private final RecordingStatusService statusService;
	private final long delayMs;

	public MockRecordingProcessor(
		RecordingStatusService statusService,
		@Value("${app.recording.mock-processing-delay-ms:300}") long delayMs
	) {
		this.statusService = statusService;
		this.delayMs = delayMs;
	}

	@Async("recordingTaskExecutor")
	@TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
	public void process(RecordingUploadedEvent event) {
		try {
			pause();
			if (!statusService.markSttProcessing(event.recordingId(), event.processingVersion())) {
				return;
			}
			pause();
			if (!statusService.markSttDone(
				event.recordingId(),
				event.processingVersion(),
				"Mock STT 처리 결과입니다."
			)) {
				return;
			}
			pause();
			if (!statusService.markLlmProcessing(event.recordingId(), event.processingVersion())) {
				return;
			}
			pause();
			statusService.markReady(
				event.recordingId(),
				event.processingVersion(),
				"Mock으로 정리된 이야기입니다."
			);
		} catch (InterruptedException exception) {
			Thread.currentThread().interrupt();
			statusService.markFailed(
				event.recordingId(),
				event.processingVersion(),
				"MOCK",
				"PROCESSING_INTERRUPTED"
			);
		} catch (RuntimeException exception) {
			statusService.markFailed(
				event.recordingId(),
				event.processingVersion(),
				"MOCK",
				"MOCK_PROCESSING_FAILED"
			);
		}
	}

	private void pause() throws InterruptedException {
		Thread.sleep(delayMs);
	}
}
