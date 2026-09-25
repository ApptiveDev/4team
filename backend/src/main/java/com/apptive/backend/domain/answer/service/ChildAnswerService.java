package com.apptive.backend.domain.answer.service;

import java.time.Clock;
import java.time.OffsetDateTime;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.apptive.backend.common.auth.AuthenticatedUser;
import com.apptive.backend.common.exception.ApiException;
import com.apptive.backend.common.exception.ErrorCode;
import com.apptive.backend.common.id.IdGenerator;
import com.apptive.backend.domain.answer.dto.ChildAnswerResponse;
import com.apptive.backend.domain.answer.entity.ChildAnswer;
import com.apptive.backend.domain.answer.entity.TtsStatus;
import com.apptive.backend.domain.answer.repository.ChildAnswerRepository;
import com.apptive.backend.domain.assignment.entity.Assignment;
import com.apptive.backend.domain.assignment.entity.SubmissionStatus;
import com.apptive.backend.domain.assignment.repository.AssignmentRepository;
import com.apptive.backend.domain.user.entity.Role;

@Service
public class ChildAnswerService {

	private static final int MAX_TEXT_LENGTH = 1000;

	private final AssignmentRepository assignmentRepository;
	private final ChildAnswerRepository childAnswerRepository;
	private final IdGenerator idGenerator;
	private final Clock clock;

	public ChildAnswerService(
		AssignmentRepository assignmentRepository,
		ChildAnswerRepository childAnswerRepository,
		IdGenerator idGenerator,
		Clock clock
	) {
		this.assignmentRepository = assignmentRepository;
		this.childAnswerRepository = childAnswerRepository;
		this.idGenerator = idGenerator;
		this.clock = clock;
	}

	@Transactional
	public ChildAnswerResponse put(
		String assignmentId,
		String rawText,
		AuthenticatedUser authenticatedUser
	) {
		if (authenticatedUser.role() != Role.CHILD) {
			throw new ApiException(ErrorCode.ROLE_NOT_ALLOWED);
		}

		Assignment assignment = assignmentRepository.findByIdForUpdate(assignmentId)
			.orElseThrow(() -> new ApiException(ErrorCode.ASSIGNMENT_NOT_FOUND));
		if (!assignment.getFamilyPair().getChild().getId().equals(authenticatedUser.userId())) {
			throw new ApiException(ErrorCode.PAIR_ACCESS_DENIED);
		}

		String text = rawText.trim();
		if (text.isEmpty() || text.length() > MAX_TEXT_LENGTH) {
			throw new ApiException(ErrorCode.VALIDATION_ERROR);
		}

		OffsetDateTime now = OffsetDateTime.now(clock);
		ChildAnswer answer = childAnswerRepository.findByAssignment_Id(assignmentId)
			.map(existing -> {
				existing.update(text, now);
				return existing;
			})
			.orElseGet(() -> new ChildAnswer(
				idGenerator.generate("ans"),
				assignment,
				text,
				TtsStatus.PROCESSING,
				now,
				now
			));

		return toResponse(childAnswerRepository.save(answer));
	}

	private ChildAnswerResponse toResponse(ChildAnswer answer) {
		return new ChildAnswerResponse(
			answer.getId(),
			answer.getAssignment().getId(),
			answer.getText(),
			SubmissionStatus.SUBMITTED,
			answer.getTtsStatus(),
			answer.getSubmittedAt(),
			answer.getUpdatedAt()
		);
	}
}
