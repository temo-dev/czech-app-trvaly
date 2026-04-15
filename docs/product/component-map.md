# Component Map — Trvalý Prep MVP
> Flutter · file paths relative to `lib/`
> Every component listed here is a concrete widget class.

---

## 1. Shell & Layout

| Widget | File | Props | Used in |
|--------|------|-------|---------|
| `AppShell` | `features/shell/app_shell.dart` | `child: Widget` | GoRouter ShellRoute |
| `ResponsivePageContainer` | `shared/widgets/responsive_page_container.dart` | `child, maxWidth: 900` | Every screen |
| `MobileBottomNav` | `features/shell/widgets/bottom_nav_bar.dart` | `tabs, selectedIndex, onTap` | AppShell (< 900px) |
| `WebSidebarNav` | `features/shell/widgets/side_rail_nav.dart` | `tabs, selectedIndex, onTap` | AppShell (≥ 900px) |
| `AppTopBar` | `shared/widgets/app_top_bar.dart` | `title, actions, showBack` | All inner screens |
| `StickyBottomCTA` | `shared/widgets/sticky_bottom_cta.dart` | `label, onTap, isLoading` | Landing, Course Overview |
| `BreadcrumbBar` | `shared/widgets/breadcrumb_bar.dart` | `crumbs: List<Crumb>` | Web: Course → Module → Lesson |

---

## 2. Buttons & Actions

| Widget | File | Props |
|--------|------|-------|
| `PrimaryButton` | `shared/widgets/app_button.dart` | `label, onPressed, isLoading, fullWidth` |
| `SecondaryButton` | `shared/widgets/app_button.dart` | `label, onPressed` (outlined style) |
| `LoadingButton` | `shared/widgets/app_button.dart` | `label, onPressed, isLoading` |
| `InlineLinkButton` | `shared/widgets/inline_link_button.dart` | `label, onTap` |
| `DestructiveButton` | `shared/widgets/app_button.dart` | `label, onPressed` (red style) |

All buttons extend from `AppButton` with a `variant` enum param.

---

## 3. Form Inputs

| Widget | File | Props |
|--------|------|-------|
| `AppTextField` | `shared/widgets/app_text_field.dart` | `controller, label, hint, errorText, validator` |
| `PasswordField` | `shared/widgets/password_field.dart` | `controller, label, errorText` — has show/hide toggle |
| `AppCheckbox` | `shared/widgets/app_checkbox.dart` | `value, onChanged, label` |
| `AppRadioGroup<T>` | `shared/widgets/app_radio_group.dart` | `options, groupValue, onChanged` |
| `AppToggle` | `shared/widgets/app_toggle.dart` | `value, onChanged, label` |
| `TimePickerField` | `shared/widgets/time_picker_field.dart` | `hour, onChanged` |
| `WritingTextArea` | `shared/widgets/writing_text_area.dart` | `controller, minLines, maxWords, wordCount` |

---

## 4. Feedback / UI State

| Widget | File | Props |
|--------|------|-------|
| `AppSkeleton` | `shared/widgets/loading_shimmer.dart` | `child` (shimmer wrapper) |
| `ShimmerCardList` | `shared/widgets/loading_shimmer.dart` | `count, itemHeight` |
| `EmptyStateCard` | `shared/widgets/empty_state.dart` | `message, title?, icon?, actionLabel?, onAction?` |
| `ErrorStateCard` | `shared/widgets/error_state.dart` | `message?, onRetry?` |
| `SuccessBanner` | `shared/widgets/success_banner.dart` | `message` |
| `InfoBanner` | `shared/widgets/info_banner.dart` | `message, icon?` |
| `AutosaveIndicator` | `features/mock_test/widgets/autosave_indicator.dart` | `status: AutosaveStatus` |
| `OfflineBanner` | `shared/widgets/offline_banner.dart` | — (subscribes to connectivity stream) |

---

## 5. Cards — Content

| Widget | File | Props |
|--------|------|-------|
| `LatestResultCard` | `features/dashboard/widgets/latest_result_card.dart` | `result: ExamResult` |
| `RecommendedLessonCard` | `features/dashboard/widgets/recommended_lesson_card.dart` | `lesson: RecommendedLesson, onTap` |
| `StreakCard` | `features/dashboard/widgets/streak_card.dart` | `streakDays: int` |
| `PointsCard` | `features/dashboard/widgets/points_card.dart` | `totalXp, weeklyXp, weeklyRank` |
| `LeaderboardPreviewCard` | `features/dashboard/widgets/leaderboard_preview_card.dart` | `rows: List<LeaderboardRow>, ownRank` |
| `CourseProgressCard` | `features/dashboard/widgets/course_progress_card.dart` | `course: CourseProgress` |
| `ModuleCard` | `features/course/widgets/module_card.dart` | `module: ModuleSummary, onTap` |
| `LessonListTile` | `features/course/widgets/lesson_list_tile.dart` | `lesson: LessonSummary, onTap` |
| `LessonBlockCard` | `features/course/widgets/lesson_block_card.dart` | `block: LessonBlock, onTap` |
| `BonusUnlockSection` | `features/course/widgets/bonus_unlock_section.dart` | `xpCost, currentXp, isUnlocked, onUnlock` |
| `TeacherFeedbackCard` | `features/teacher_feedback/widgets/teacher_feedback_card.dart` | `review: TeacherReview` |
| `TeacherCommentCard` | `features/teacher_feedback/widgets/teacher_comment_card.dart` | `comment: TeacherComment` |

---

## 6. Exam & Practice Shell

| Widget | File | Props |
|--------|------|-------|
| `ExamTopBar` | `features/mock_test/widgets/exam_top_bar.dart` | `sectionLabel, remainingSeconds, autosaveStatus` |
| `ExamTimer` | `features/mock_test/widgets/exam_timer.dart` | `remainingSeconds, onExpired` |
| `QuestionShell` | `features/exercise/widgets/question_shell.dart` | `question: Question, onAnswer` |
| `QuestionProgressBar` | `features/exercise/widgets/question_progress_bar.dart` | `answered, flagged, total` |
| `QuestionNavigationPanel` | `features/mock_test/widgets/question_nav_panel.dart` | `questions: List<QuestionStatus>, onTap` |
| `ExamSubmitButton` | `features/mock_test/widgets/exam_submit_button.dart` | `onSubmit, answeredCount, total` |
| `ConfirmSubmitDialog` | `features/mock_test/widgets/confirm_submit_dialog.dart` | `unansweredCount, onConfirm` |
| `ExerciseProgressFooter` | `features/exercise/widgets/exercise_progress_footer.dart` | `completed, total` |
| `SectionTransitionCard` | `features/mock_test/widgets/section_transition_card.dart` | `nextSection: SectionMeta` |

---

## 7. Question Renderer Widgets
All owned by `features/exercise/widgets/`

| Widget | Exercise type | Key props |
|--------|--------------|-----------|
| `McqExercise` | `mcq` | `options, selectedId, onSelect, isSubmitted` |
| `FillBlankExercise` | `fill_blank` | `promptWithBlanks, controllers, isSubmitted` |
| `MatchingExercise` | `matching` | `pairs, userMatches, onMatch` |
| `OrderingExercise` | `ordering` | `items, userOrder, onReorder` |
| `ReadingPassageExercise` | `reading_mcq` | `passage, options, selectedId` |
| `ListeningExercise` | `listening_mcq` | `audioUrl, options, selectedId` |
| `SpeakingRecorderExercise` | `speaking` | `prompt, onRecordingComplete` |
| `WritingInputExercise` | `writing` | `prompt, controller, maxWords` |
| `ExplanationPanel` | all | `explanation, isCorrect, correctAnswer` |

Shared inside each:
- `AudioPlayerBar` — `features/exercise/widgets/audio_player_bar.dart` — `audioUrl, onPlayPause`
- `McqOptionTile` — `option: QuestionOption, state: OptionState`

---

## 8. Speaking AI widgets
All in `features/speaking_ai/widgets/`

| Widget | Props |
|--------|-------|
| `SpeakingRecorderButton` | `recordingState: RecordingState, onToggle` |
| `WaveformVisualizer` | `amplitudes: List<double>` |
| `TranscriptBlock` | `transcript, issues: List<TranscriptIssue>` |
| `SpeakingScoreMetricCard` | `label, score: int` |

---

## 9. Writing AI widgets
All in `features/writing_ai/widgets/`

| Widget | Props |
|--------|-------|
| `AnnotatedEssayPanel` | `text, annotations: List<Annotation>` |
| `GrammarNotesList` | `notes: List<FeedbackNote>` |
| `VocabularyNotesList` | `notes: List<FeedbackNote>` |
| `WritingScoreMetricCard` | `label, score: int` |
| `CorrectedAnswerPanel` | `correctedText` |

---

## 10. Gamification & Progress

| Widget | File | Props |
|--------|------|-------|
| `ProgressRing` | `shared/widgets/progress_ring.dart` | `value: 0.0–1.0, size, label?, color?` |
| `ScoreBadge` | `shared/widgets/score_badge.dart` | `score: 0–100, size` |
| `StreakBadge` | `shared/widgets/streak_badge.dart` | `streakDays: int` |
| `PointsBadge` | `shared/widgets/points_badge.dart` | `xp: int` |
| `RankBadge` | `shared/widgets/rank_badge.dart` | `rank: int` |
| `WeeklyLeaderboardRow` | `features/leaderboard/widgets/leaderboard_row.dart` | `rank, user: LeaderboardUser, isCurrentUser` |
| `OwnRankStickyCard` | `features/leaderboard/widgets/own_rank_card.dart` | `rank, xp` |
| `TopThreePodium` | `features/leaderboard/widgets/top_three_podium.dart` | `top3: List<LeaderboardUser>` |
| `SkillRadarChart` | `features/progress/widgets/skill_radar_chart.dart` | `scores: Map<Skill, int>` |
| `StreakCalendarHeatmap` | `features/progress/widgets/streak_heatmap.dart` | `activityByDate: Map<DateTime, int>` |
| `TagChip` | `shared/widgets/tag_chip.dart` | `label, variant: TagChipVariant, onTap?` |
| `WeakSkillChip` | `shared/widgets/tag_chip.dart` | wraps TagChip with difficulty colour |

---

## 11. AI Feedback shared

| Widget | File | Props |
|--------|------|-------|
| `AIFeedbackHeader` | `shared/widgets/ai_feedback_header.dart` | `skill, overallScore, type: 'speaking'\|'writing'` |
| `ScoreMetricCard` | `shared/widgets/score_metric_card.dart` | `label, score: int, maxScore: int` |
| `StrengthList` | `shared/widgets/feedback_list.dart` | `items: List<String>` |
| `ImprovementList` | `shared/widgets/feedback_list.dart` | `items: List<String>` |
| `FeedbackSummaryPanel` | `shared/widgets/feedback_summary_panel.dart` | `body: String` |

---

## 12. Naming conventions

| Rule | Example |
|------|---------|
| Screens are suffixed `Screen` | `DashboardScreen` |
| Feature-level widgets go in `features/<module>/widgets/` | `features/course/widgets/module_card.dart` |
| Shared widgets go in `shared/widgets/` | `shared/widgets/progress_ring.dart` |
| Providers go in `features/<module>/providers/` | `features/dashboard/providers/dashboard_provider.dart` |
| Each widget file = one widget class | one class per file |
| State classes are suffixed `State` | `ExamSessionState` |
| Notifiers are suffixed `Notifier` | `ExamSessionNotifier` |
