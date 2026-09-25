package com.apptive.backend.domain.answer.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.apptive.backend.domain.answer.entity.ChildAnswer;

public interface ChildAnswerRepository extends JpaRepository<ChildAnswer, String> {

	Optional<ChildAnswer> findByAssignment_Id(String assignmentId);
}
