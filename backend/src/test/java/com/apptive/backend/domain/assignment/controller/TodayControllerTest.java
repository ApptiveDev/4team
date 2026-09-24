package com.apptive.backend.domain.assignment.controller;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.time.Clock;
import java.time.LocalDate;
import java.time.OffsetDateTime;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.transaction.annotation.Transactional;

import com.apptive.backend.common.auth.JwtTokenProvider;
import com.apptive.backend.domain.assignment.repository.AssignmentRepository;
import com.apptive.backend.domain.pair.entity.FamilyPair;
import com.apptive.backend.domain.pair.repository.FamilyPairRepository;
import com.apptive.backend.domain.pair.repository.PairInvitationRepository;
import com.apptive.backend.domain.question.entity.Question;
import com.apptive.backend.domain.question.repository.QuestionRepository;
import com.apptive.backend.domain.user.entity.Role;
import com.apptive.backend.domain.user.entity.User;
import com.apptive.backend.domain.user.repository.UserRepository;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
class TodayControllerTest {

	@Autowired
	private MockMvc mockMvc;

	@Autowired
	private JwtTokenProvider tokenProvider;

	@Autowired
	private AssignmentRepository assignmentRepository;

	@Autowired
	private PairInvitationRepository invitationRepository;

	@Autowired
	private FamilyPairRepository familyPairRepository;

	@Autowired
	private UserRepository userRepository;

	@Autowired
	private QuestionRepository questionRepository;

	@Autowired
	private Clock clock;

	private User parent;
	private User child;

	@BeforeEach
	void setUp() {
		assignmentRepository.deleteAll();
		invitationRepository.deleteAll();
		familyPairRepository.deleteAll();
		userRepository.deleteAll();

		OffsetDateTime now = OffsetDateTime.now(clock);
		parent = userRepository.save(new User("usr_today_parent", "부모", Role.PARENT, "today-parent", now));
		child = userRepository.save(new User("usr_today_child", "자녀", Role.CHILD, "today-child", now));
		familyPairRepository.save(new FamilyPair("pair_today", parent, child, now));

		LocalDate today = LocalDate.now(clock);
		Question question = questionRepository.findByScheduledDateAndActiveTrue(today)
			.orElseGet(() -> new Question(
				"qst_today_test",
				today,
				"오늘의 테스트 질문은 무엇인가요?",
				"TEST",
				null,
				true
			));
		question.updateFromSeed(today, "오늘의 테스트 질문은 무엇인가요?", "TEST", null, true);
		questionRepository.save(question);
	}

	@Test
	void pairedMembersReceiveSameTodayAssignment() throws Exception {
		MvcResult childResult = mockMvc.perform(get("/api/v1/today")
				.header("Authorization", bearer(child)))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.assignment.id").isNotEmpty())
			.andExpect(jsonPath("$.assignment.assignedDate").value(LocalDate.now(clock).toString()))
			.andExpect(jsonPath("$.assignment.question.text").value("오늘의 테스트 질문은 무엇인가요?"))
			.andExpect(jsonPath("$.assignment.question.category").value("TEST"))
			.andExpect(jsonPath("$.assignment.question.audioUrl").value((Object) null))
			.andExpect(jsonPath("$.viewerRole").value("CHILD"))
			.andExpect(jsonPath("$.parentSubmissionStatus").value("NOT_SUBMITTED"))
			.andExpect(jsonPath("$.childSubmissionStatus").value("NOT_SUBMITTED"))
			.andExpect(jsonPath("$.revealStatus").value("WAITING_FOR_BOTH"))
			.andExpect(jsonPath("$.canViewPartnerAnswer").value(false))
			.andExpect(jsonPath("$.myAnswer").value((Object) null))
			.andExpect(jsonPath("$.partnerAnswer").doesNotExist())
			.andReturn();

		String childAssignmentId = com.jayway.jsonpath.JsonPath.read(
			childResult.getResponse().getContentAsString(),
			"$.assignment.id"
		);
		mockMvc.perform(get("/api/v1/today")
				.header("Authorization", bearer(parent)))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.assignment.id").value(childAssignmentId))
			.andExpect(jsonPath("$.viewerRole").value("PARENT"));

		org.assertj.core.api.Assertions.assertThat(assignmentRepository.count()).isEqualTo(1);
	}

	@Test
	void unpairedUserReceivesPairNotFound() throws Exception {
		User unpaired = userRepository.save(new User(
			"usr_unpaired",
			"미페어링",
			Role.CHILD,
			"unpaired-device",
			OffsetDateTime.now(clock)
		));

		mockMvc.perform(get("/api/v1/today")
				.header("Authorization", bearer(unpaired)))
			.andExpect(status().isConflict())
			.andExpect(jsonPath("$.errorCode").value("PAIR_NOT_FOUND"));
	}

	@Test
	void missingQuestionReceivesTodayAssignmentNotFound() throws Exception {
		assignmentRepository.deleteAll();
		questionRepository.findByScheduledDateAndActiveTrue(LocalDate.now(clock))
			.ifPresent(questionRepository::delete);

		mockMvc.perform(get("/api/v1/today")
				.header("Authorization", bearer(child)))
			.andExpect(status().isNotFound())
			.andExpect(jsonPath("$.errorCode").value("TODAY_ASSIGNMENT_NOT_FOUND"));
	}

	private String bearer(User user) {
		return "Bearer " + tokenProvider.issue(user.getId(), user.getRole()).value();
	}
}
