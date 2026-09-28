package com.apptive.backend.domain.story.dto;

import com.apptive.backend.domain.answer.entity.TtsStatus;

public record StoryChildAnswerResponse(String answerId, String text, TtsStatus ttsStatus) {
}
