package com.apptive.backend.domain.answer.entity;

import java.time.OffsetDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

import com.apptive.backend.domain.assignment.entity.Assignment;

@Entity
@Table(
	name = "child_answers",
	uniqueConstraints = @UniqueConstraint(
		name = "uk_child_answers_assignment",
		columnNames = "assignment_id"
	)
)
public class ChildAnswer {

	@Id
	@Column(length = 40, nullable = false, updatable = false)
	private String id;

	@OneToOne(fetch = FetchType.LAZY, optional = false)
	@JoinColumn(name = "assignment_id", nullable = false, updatable = false)
	private Assignment assignment;

	@Column(length = 1000, nullable = false)
	private String text;

	@Enumerated(EnumType.STRING)
	@Column(name = "tts_status", length = 20, nullable = false)
	private TtsStatus ttsStatus;

	@Column(name = "submitted_at", nullable = false, updatable = false)
	private OffsetDateTime submittedAt;

	@Column(name = "updated_at", nullable = false)
	private OffsetDateTime updatedAt;

	protected ChildAnswer() {
	}

	public ChildAnswer(
		String id,
		Assignment assignment,
		String text,
		TtsStatus ttsStatus,
		OffsetDateTime submittedAt,
		OffsetDateTime updatedAt
	) {
		this.id = id;
		this.assignment = assignment;
		this.text = text;
		this.ttsStatus = ttsStatus;
		this.submittedAt = submittedAt;
		this.updatedAt = updatedAt;
	}

	public void update(String text, OffsetDateTime updatedAt) {
		this.text = text;
		this.ttsStatus = TtsStatus.PROCESSING;
		this.updatedAt = updatedAt;
	}

	public String getId() {
		return id;
	}

	public Assignment getAssignment() {
		return assignment;
	}

	public String getText() {
		return text;
	}

	public TtsStatus getTtsStatus() {
		return ttsStatus;
	}

	public OffsetDateTime getSubmittedAt() {
		return submittedAt;
	}

	public OffsetDateTime getUpdatedAt() {
		return updatedAt;
	}
}
