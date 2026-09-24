package com.apptive.backend.domain.assignment.service;

import java.time.Clock;
import java.time.LocalDate;
import java.time.OffsetDateTime;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.apptive.backend.common.auth.AuthenticatedUser;
import com.apptive.backend.common.exception.ApiException;
import com.apptive.backend.common.exception.ErrorCode;
import com.apptive.backend.common.id.IdGenerator;
import com.apptive.backend.domain.assignment.dto.TodayAssignmentResponse;
import com.apptive.backend.domain.assignment.dto.TodayQuestionResponse;
import com.apptive.backend.domain.assignment.dto.TodayResponse;
import com.apptive.backend.domain.assignment.entity.Assignment;
import com.apptive.backend.domain.assignment.entity.RevealStatus;
import com.apptive.backend.domain.assignment.entity.SubmissionStatus;
import com.apptive.backend.domain.assignment.repository.AssignmentRepository;
import com.apptive.backend.domain.pair.entity.FamilyPair;
import com.apptive.backend.domain.pair.repository.FamilyPairRepository;
import com.apptive.backend.domain.question.entity.Question;
import com.apptive.backend.domain.question.repository.QuestionRepository;

@Service
public class TodayService {

	private final FamilyPairRepository familyPairRepository;
	private final AssignmentRepository assignmentRepository;
	private final QuestionRepository questionRepository;
	private final IdGenerator idGenerator;
	private final Clock clock;

	public TodayService(
		FamilyPairRepository familyPairRepository,
		AssignmentRepository assignmentRepository,
		QuestionRepository questionRepository,
		IdGenerator idGenerator,
		Clock clock
	) {
		this.familyPairRepository = familyPairRepository;
		this.assignmentRepository = assignmentRepository;
		this.questionRepository = questionRepository;
		this.idGenerator = idGenerator;
		this.clock = clock;
	}

	@Transactional
	public TodayResponse getToday(AuthenticatedUser authenticatedUser) {
		FamilyPair familyPair = familyPairRepository.findByMemberIdForUpdate(authenticatedUser.userId())
			.orElseThrow(() -> new ApiException(ErrorCode.PAIR_NOT_FOUND));
		LocalDate today = LocalDate.now(clock);
		Assignment assignment = assignmentRepository
			.findByFamilyPair_IdAndAssignedDate(familyPair.getId(), today)
			.orElseGet(() -> createAssignment(familyPair, today));

		return toResponse(assignment, authenticatedUser);
	}

	private Assignment createAssignment(FamilyPair familyPair, LocalDate today) {
		Question question = questionRepository.findByScheduledDateAndActiveTrue(today)
			.orElseThrow(() -> new ApiException(ErrorCode.TODAY_ASSIGNMENT_NOT_FOUND));
		return assignmentRepository.save(new Assignment(
			idGenerator.generate("asg"),
			familyPair,
			question,
			today,
			OffsetDateTime.now(clock)
		));
	}

	private TodayResponse toResponse(Assignment assignment, AuthenticatedUser authenticatedUser) {
		Question question = assignment.getQuestion();
		return new TodayResponse(
			new TodayAssignmentResponse(
				assignment.getId(),
				assignment.getAssignedDate(),
				new TodayQuestionResponse(
					question.getId(),
					question.getText(),
					question.getCategory(),
					question.getAudioUrl()
				)
			),
			authenticatedUser.role(),
			SubmissionStatus.NOT_SUBMITTED,
			SubmissionStatus.NOT_SUBMITTED,
			RevealStatus.WAITING_FOR_BOTH,
			false,
			null
		);
	}
}
