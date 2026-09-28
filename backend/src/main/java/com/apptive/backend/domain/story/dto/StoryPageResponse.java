package com.apptive.backend.domain.story.dto;

import java.util.List;

public record StoryPageResponse(List<StoryItemResponse> items, String nextCursor, boolean hasNext) {
}
