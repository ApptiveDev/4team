package com.apptive.backend.domain.assignment.service;

import org.springframework.stereotype.Component;

import com.apptive.backend.domain.assignment.entity.RevealStatus;
import com.apptive.backend.domain.assignment.entity.SubmissionStatus;

@Component
public class RevealPolicy {

	public RevealStatus resolve(SubmissionStatus parentStatus, SubmissionStatus childStatus) {
		boolean parentSubmitted = parentStatus == SubmissionStatus.SUBMITTED;
		boolean childSubmitted = childStatus == SubmissionStatus.SUBMITTED;

		if (parentSubmitted && childSubmitted) {
			return RevealStatus.REVEALED;
		}
		if (parentSubmitted) {
			return RevealStatus.WAITING_FOR_CHILD;
		}
		if (childSubmitted) {
			return RevealStatus.WAITING_FOR_PARENT;
		}
		return RevealStatus.WAITING_FOR_BOTH;
	}
}
