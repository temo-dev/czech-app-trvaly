import { chatComplete, getVietnameseGuardModel } from "./openai.ts";

const GUARD_SYSTEM_PROMPT = `
Bạn là lớp kiểm tra cuối cùng để chuẩn hóa JSON nhận xét sang tiếng Việt cho ứng dụng luyện thi tiếng Séc.

Nhiệm vụ:
- Chỉ viết lại các giá trị user-facing để chúng trở thành tiếng Việt tự nhiên, rõ ràng, nhất quán.
- Giữ NGUYÊN cấu trúc JSON, key, số, boolean, null, enum, UUID và mọi trường không phải nhận xét.
- Không dịch hoặc chỉnh sửa các trường chứa nội dung tiếng Séc gốc hay bản sửa tiếng Séc.

Luôn giữ nguyên các trường sau nếu có:
- corrected_answer
- corrected_essay
- corrected_version
- transcript
- text
- correction
- token
- suggestion
- detected_language
- item

Bạn có thể giữ nguyên tiếng Séc khi nó là ví dụ, transcript, đáp án sửa đúng hoặc cụm từ cần trích dẫn.
Trả về JSON hợp lệ, không có văn bản nào khác.
`.trim();

const TRANSLATABLE_KEYS = new Set([
  "summary",
  "reinforcement",
  "feedback",
  "tip",
  "detail",
  "error_analysis",
  "correct_explanation",
  "short_tip",
  "key_concept",
  "overall_feedback",
  "grammar_feedback",
  "vocabulary_feedback",
  "content_feedback",
  "format_feedback",
  "message",
  "main_issue",
  "title",
  "issue",
]);

const CONTAINER_KEYS = new Set([
  "criteria",
  "mistakes",
  "suggestions",
  "annotated_spans",
  "matching_feedback",
  "skill_insights",
  "overall_recommendations",
  "pronunciation_feedback",
  "grammar_feedback",
  "vocabulary_feedback",
  "fluency_feedback",
  "content_feedback",
  "artifacts",
  "transcript_issues",
]);

const PRESERVED_KEYS = new Set([
  "corrected_answer",
  "corrected_essay",
  "corrected_version",
  "transcript",
  "text",
  "correction",
  "token",
  "suggestion",
  "detected_language",
  "item",
]);

const ENGLISH_MARKERS = [
  "the",
  "and",
  "incorrect",
  "correct",
  "should",
  "because",
  "grammar",
  "vocabulary",
  "fluency",
  "pronunciation",
  "feedback",
  "summary",
  "suggestion",
  "detail",
  "improve",
  "answer",
  "missing",
  "use",
  "word order",
  "article",
  "tense",
  "needs",
  "retry",
  "good job",
];

const VIETNAMESE_MARKERS = [
  "bạn",
  "không",
  "cần",
  "nên",
  "đúng",
  "sai",
  "ngữ",
  "từ",
  "lỗi",
  "mẹo",
  "gợi ý",
  "nhận xét",
  "nội dung",
  "cấu trúc",
];

export async function ensureVietnameseUserFacingJson<
  T extends Record<string, unknown>,
>(
  apiKey: string,
  payload: T,
  context: string,
): Promise<T> {
  const inspection = inspectSuspiciousEnglish(payload);
  if (inspection.suspiciousCount === 0) {
    return payload;
  }

  const model = getVietnameseGuardModel();
  logGuardEvent({
    status: "triggered",
    context,
    model,
    suspiciousCount: inspection.suspiciousCount,
    suspiciousPaths: inspection.suspiciousPaths,
  });

  try {
    const rewritten = await chatComplete(
      apiKey,
      GUARD_SYSTEM_PROMPT,
      [
        `Ngữ cảnh: ${context}`,
        "Hãy chuẩn hóa các giá trị user-facing sang tiếng Việt nhưng giữ nguyên cấu trúc JSON.",
        `JSON gốc:\n${JSON.stringify(payload)}`,
      ].join("\n\n"),
      { model, timeoutMs: 20_000 },
    );

    const merged = mergeNormalizedJson(payload, rewritten) as T;
    const remaining = inspectSuspiciousEnglish(merged);
    logGuardEvent({
      status: remaining.suspiciousCount === 0 ? "rewritten" : "partial",
      context,
      model,
      suspiciousCount: inspection.suspiciousCount,
      suspiciousPaths: inspection.suspiciousPaths,
      remainingCount: remaining.suspiciousCount,
      remainingPaths: remaining.suspiciousPaths,
      changed: JSON.stringify(merged) !== JSON.stringify(payload),
    });
    return merged;
  } catch (error) {
    logGuardEvent({
      status: "fallback",
      context,
      model,
      suspiciousCount: inspection.suspiciousCount,
      suspiciousPaths: inspection.suspiciousPaths,
      error: String(error),
    });
    return payload;
  }
}

type GuardInspection = {
  suspiciousCount: number;
  suspiciousPaths: string[];
};

function shouldInspectString(key?: string): boolean {
  if (!key) return false;
  if (PRESERVED_KEYS.has(key)) return false;
  return TRANSLATABLE_KEYS.has(key) || key === "short_tips";
}

function looksEnglish(text: string): boolean {
  const normalized = text.trim().toLowerCase();
  if (normalized.length < 4) return false;
  if (
    /[ăâđêôơưáàảãạấầẩẫậắằẳẵặéèẻẽẹếềểễệíìỉĩịóòỏõọốồổỗộớờởỡợúùủũụứừửữựýỳỷỹỵ]/
      .test(normalized)
  ) {
    return false;
  }
  if (VIETNAMESE_MARKERS.some((marker) => normalized.includes(marker))) {
    return false;
  }
  return ENGLISH_MARKERS.some((marker) => normalized.includes(marker));
}

function inspectSuspiciousEnglish(value: unknown): GuardInspection {
  const suspiciousPaths: string[] = [];
  visitSuspiciousEnglish(value, suspiciousPaths, "$");
  return {
    suspiciousCount: suspiciousPaths.length,
    suspiciousPaths: suspiciousPaths.slice(0, 8),
  };
}

function visitSuspiciousEnglish(
  value: unknown,
  suspiciousPaths: string[],
  path: string,
  parentKey?: string,
) {
  if (typeof value === "string") {
    if (shouldInspectString(parentKey) && looksEnglish(value)) {
      suspiciousPaths.push(path);
    }
    return;
  }

  if (Array.isArray(value)) {
    value.forEach((item, index) => {
      visitSuspiciousEnglish(
        item,
        suspiciousPaths,
        `${path}[${index}]`,
        parentKey,
      );
    });
    return;
  }

  if (typeof value !== "object" || value == null) {
    return;
  }

  for (const [key, child] of Object.entries(value)) {
    if (PRESERVED_KEYS.has(key)) {
      continue;
    }
    visitSuspiciousEnglish(child, suspiciousPaths, `${path}.${key}`, key);
  }
}

function logGuardEvent(args: {
  status: "triggered" | "rewritten" | "partial" | "fallback";
  context: string;
  model: string;
  suspiciousCount: number;
  suspiciousPaths: string[];
  remainingCount?: number;
  remainingPaths?: string[];
  changed?: boolean;
  error?: string;
}) {
  const contextGroup = classifyContextGroup(args.context);
  const payload: Record<string, unknown> = {
    event: "vietnamese_guard",
    status: args.status,
    context: args.context,
    context_group: contextGroup,
    context_slug: toContextSlug(args.context),
    model: args.model,
    suspicious_count: args.suspiciousCount,
    suspicious_paths: args.suspiciousPaths,
  };

  if (args.remainingCount != null) {
    payload.remaining_count = args.remainingCount;
  }
  if (args.remainingPaths && args.remainingPaths.length > 0) {
    payload.remaining_paths = args.remainingPaths;
  }
  if (args.changed != null) {
    payload.changed = args.changed;
  }
  if (args.error) {
    payload.error = args.error.slice(0, 300);
  }

  const message = JSON.stringify(payload);
  if (args.status === "fallback") {
    console.warn(message);
    return;
  }
  console.log(message);
}

function classifyContextGroup(context: string): string {
  const normalized = context.trim().toLowerCase();
  const prefix = normalized.split(/[.\s]/).find((segment) =>
    segment.length > 0
  );
  if (prefix === "question_feedback") return "question_feedback";
  if (prefix === "exam_analysis") return "exam_analysis";
  if (prefix === "objective_review") return "objective_review";
  if (prefix === "speaking") return "speaking";
  if (prefix === "writing") return "writing";
  if (normalized.includes("teacher_review")) return "teacher_review";
  return "other";
}

function toContextSlug(context: string): string {
  return context
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "_")
    .replace(/^_+|_+$/g, "")
    .slice(0, 80);
}

function mergeNormalizedJson(original: unknown, rewritten: unknown): unknown {
  if (Array.isArray(original)) {
    if (!Array.isArray(rewritten)) {
      return original;
    }
    return original.map((item, index) =>
      mergeNormalizedJson(item, rewritten[index])
    );
  }

  if (typeof original === "object" && original != null) {
    if (
      typeof rewritten !== "object" || rewritten == null ||
      Array.isArray(rewritten)
    ) {
      return original;
    }

    const merged: Record<string, unknown> = {};
    for (const [key, value] of Object.entries(original)) {
      if (!(key in (rewritten as Record<string, unknown>))) {
        merged[key] = value;
        continue;
      }
      merged[key] = mergeNormalizedJson(
        value,
        (rewritten as Record<string, unknown>)[key],
      );
    }
    return merged;
  }

  if (typeof original === typeof rewritten && rewritten !== undefined) {
    return rewritten;
  }

  return original;
}
