package com.apptive.backend.domain.assignment.repository;

import java.time.LocalDate;
import java.util.Optional;

import jakarta.persistence.LockModeType;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.apptive.backend.domain.assignment.entity.Assignment;

public interface AssignmentRepository extends JpaRepository<Assignment, String> {

	Optional<Assignment> findByFamilyPair_IdAndAssignedDate(String pairId, LocalDate assignedDate);

	@Lock(LockModeType.PESSIMISTIC_WRITE)
	@Query("select a from Assignment a join fetch a.familyPair where a.id = :assignmentId")
	Optional<Assignment> findByIdForUpdate(@Param("assignmentId") String assignmentId);
}
