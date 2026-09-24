package com.apptive.backend.domain.assignment.repository;

import java.time.LocalDate;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.apptive.backend.domain.assignment.entity.Assignment;

public interface AssignmentRepository extends JpaRepository<Assignment, String> {

	Optional<Assignment> findByFamilyPair_IdAndAssignedDate(String pairId, LocalDate assignedDate);
}
