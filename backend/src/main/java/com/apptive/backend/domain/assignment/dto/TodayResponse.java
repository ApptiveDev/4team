package com.apptive.backend.domain.assignment.dto;

import com.apptive.backend.domain.assignment.entity.RevealStatus;
import com.apptive.backend.domain.assignment.entity.SubmissionStatus;
import com.apptive.backend.domain.user.entity.Role;

public record TodayResponse(
	TodayAssignmentResponse assignment,
	Role viewerRole,
	SubmissionStatus parentSubmissionStatus,
	SubmissionStatus childSubmissionStatus,
	RevealStatus revealStatus,
	boolean canViewPartnerAnswer,
	TodayAnswerResponse myAnswer
) {
}
