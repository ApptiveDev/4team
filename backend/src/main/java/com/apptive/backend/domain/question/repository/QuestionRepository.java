package com.apptive.backend.domain.question.repository;

import java.time.LocalDate;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.apptive.backend.domain.question.entity.Question;

public interface QuestionRepository extends JpaRepository<Question, String> {

	Optional<Question> findByScheduledDateAndActiveTrue(LocalDate scheduledDate);
}
