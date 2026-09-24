package com.apptive.backend.domain.pair.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.apptive.backend.domain.pair.entity.FamilyPair;

public interface FamilyPairRepository extends JpaRepository<FamilyPair, String> {

	@Query("select (count(p) > 0) from FamilyPair p where p.parent.id = :userId or p.child.id = :userId")
	boolean existsByMemberId(@Param("userId") String userId);
}
