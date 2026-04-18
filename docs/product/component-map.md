# Component Map

Widget inventory with file paths and key props. Organized by feature.

---

## Shell (`lib/features/shell/`)

| Widget | File | Props |
|---|---|---|
| `AppShell` | `app_shell.dart` | wraps all `/app/**` routes via ShellRoute |
| `BottomNavBar` | `widgets/bottom_nav_bar.dart` | `selectedIndex, onDestinationSelected` |
| `SideRailNav` | `widgets/side_rail_nav.dart` | `selectedIndex, onDestinationSelected` |

---

## Dashboard (`lib/features/dashboard/widgets/`)

| Widget | Props | Notes |
|---|---|---|
| `DailyGreetingHeader` | `displayName, streakDays` | Time-of-day greeting |
| `StreakCard` | `currentStreak, lastActivityDate` | Flame icon + streak count |
| `PointsCard` | `totalXp, weeklyXp` | XP summary |
| `LatestResultCard` | `result (ExamResult?)` | Shows score + pass/fail; null-safe |
| `EmptyResultBanner` | — | CTA to take first mock test |
| `RecommendedLessonCard` | `lesson (RecommendedLesson)` | Skill icon + lesson title + module |
| `CourseProgressCard` | `progress (CourseProgress)` | Progress bar + lesson count |
| `LeaderboardPreviewCard` | `rows (List<LeaderboardRow>), ownRank` | Top 3 + own position |
| `DashboardSkeleton` | — | Shimmer layout matching full dashboard |

---

## Mock Test (`lib/features/mock_test/widgets/`)

| Widget | Props |
|---|---|
| `ExamTopBar` | `sectionLabel, remainingSeconds, onSubmit` |
| `ExamTimer` | `remainingSeconds` |
| `QuestionNavPanel` | `questions, answers, currentIndex, onNavigate` |
| `QuestionReviewList` | `questions, answers, flags` |
| `AutosaveIndicator` | `isSaving` |
| `ConfirmSubmitDialog` | `unansweredCount, onConfirm, onCancel` |
| `SectionTransitionCard` | `fromSkill, toSkill` |
| `TotalScoreHero` | `score, passed` |
| `SkillBreakdownChart` | `sectionScores (Map<String,SectionResult>)` |
| `ResultCtaSection` | `isAuthenticated, onRetry, onReview, onSignup` |

---

## Course (`lib/features/course/widgets/`)

| Widget | Props |
|---|---|
| `CourseHeaderBanner` | `course (CourseDetail)` |
| `ModuleCard` | `module (ModuleSummary), onTap` |
| `ModuleHeaderCard` | `module (ModuleSummary), courseTitle` |
| `LessonListTile` | `lesson (LessonSummary), onTap` |
| `LessonHeaderCard` | `lesson (LessonInfo)` |
| `LessonBlockCard` | `block (LessonBlock), onTap` |
| `BonusUnlockSection` | `xpCost, userXp, onUnlock` |
| `CourseSkeleton` | — |
| `ExerciseProgressFooter` | `completed, total` |

---

## Exercise (`lib/features/exercise/widgets/`)

| Widget | Props | Notes |
|---|---|---|
| `QuestionShell` | `question, child, onSubmit` | Wraps any exercise type |
| `QuestionIntro` | `introText?, introImageUrl?` | Context/passage shown above prompt |
| `McqExercise` | `options, selectedId, onSelect` | |
| `McqOptionTile` | `option, isSelected, isCorrect?, isWrong?, onTap` | |
| `FillBlankExercise` | `prompt, controller` | |
| `ListeningExercise` | `audioUrl, options, selectedId, onSelect` | |
| `ReadingPassageExercise` | `passageText, question` | |
| `SpeakingRecorderExercise` | `onRecordingComplete(audioPath)` | |
| `WritingInputExercise` | `prompt, controller, maxLength` | |
| `AudioPlayerBar` | `audioUrl` | |
| `ExplanationPanel` | `correctAnswer, explanation, isCorrect` | |

---

## Chat (`lib/features/chat/widgets/`)

| Widget | Props |
|---|---|
| `ConversationCard` | `conversation (DmConversation), onTap` |
| `MessageBubble` | `message (ChatMessage), isOwn` |
| `MessageInputBar` | `onSend(text), onAttach` |
| `AttachmentPreview` | `name, size, mime, onRemove` |
| `FriendTile` | `profile (UserProfile), onMessage, onRemove` |
| `FriendRequestTile` | `profile (UserProfile), onAccept, onDecline` |

---

## Shared Widgets (`lib/shared/widgets/`)

Reusable design-system primitives:

| Widget | Notes |
|---|---|
| `AppButton` | Primary/secondary/ghost variants, loading state |
| `AppTextField` | Label, helper, error text, obscure toggle |
| `SkillChip` | Color-coded skill badge (reading/listening/writing/speaking) |
| `ScoreBadge` | Score + pass/fail color |
| `ShimmerBox` | Base shimmer placeholder |
| `EmptyState` | Icon + title + subtitle + optional CTA |
| `ErrorState` | Error icon + message + retry button |
| `SectionHeader` | Section title + optional trailing action |
| `AvatarWidget` | Avatar URL with initials fallback |

---

## Design Token Usage

All widgets must use token classes — never raw literals:

| Token class | File | Use for |
|---|---|---|
| `AppColors` | `lib/core/theme/app_colors.dart` | All colors (primary: `#c2652a`, bg: `#faf5ee`) |
| `AppTypography` | `lib/core/theme/app_typography.dart` | Text styles (EB Garamond headlines, Manrope body) |
| `AppSpacing` | `lib/core/theme/app_spacing.dart` | Padding/margin (4px base grid) |
| `AppRadius` | `lib/core/theme/app_radius.dart` | Border radii (default 8px) |
| `AppShadows` | `lib/core/theme/app_radius.dart` | Box shadows (ultra-soft, warm-toned) |
