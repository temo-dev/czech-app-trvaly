import {
  createClient,
  type SupabaseClient,
} from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";
import {
  buildSpeakingReviewPayload,
  buildWritingReviewPayload,
  filterReviewPayload,
  getRequesterContext,
  type ReviewPayload,
} from "../_shared/ai_teacher.ts";
import { assertCanAccessOwnedRow } from "../_shared/guest_access.ts";
import { getOpenAIKey } from "../_shared/openai.ts";
import { ensureVietnameseUserFacingJson } from "../_shared/vietnamese_guard.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  try {
    const body = await req.json() as { review_id?: string };
    const reviewId = body.review_id;
    if (!reviewId) {
      return jsonResponse({ error: "review_id is required" }, 400);
    }

    const requester = await getRequesterContext(supabase, req);
    const { data: review } = await supabase
      .from("ai_teacher_reviews")
      .select("*")
      .eq("id", reviewId)
      .single();

    if (!review) {
      return jsonResponse({ error: "Review not found" }, 404);
    }

    const row = review as Record<string, unknown>;
    try {
      assertCanAccessOwnedRow({
        req,
        row,
        requesterUserId: requester.userId,
      });
    } catch (_) {
      return jsonResponse({ error: "Forbidden" }, 403);
    }

    const hydrated = await hydrateReviewIfNeeded(supabase, row);
    const status = String(hydrated["status"] ?? "processing");

    if (status === "processing") {
      return jsonResponse(buildPendingPayload(hydrated), 200);
    }

    if (status === "error") {
      return jsonResponse(
        {
          status: "error",
          review_id: hydrated["id"],
          message: String(
            hydrated["error_message"] ?? "Không thể tải AI Teacher review.",
          ),
        },
        200,
      );
    }

    const payload =
      (hydrated["result_payload"] as Record<string, unknown> | null) ?? {};
    return jsonResponse(
      filterReviewPayload(payload as ReviewPayload, requester.accessLevel),
      200,
    );
  } catch (err) {
    console.error("ai-review-result error:", err);
    return jsonResponse({ error: String(err) }, 500);
  }
});

async function hydrateReviewIfNeeded(
  supabase: SupabaseClient,
  row: Record<string, unknown>,
): Promise<Record<string, unknown>> {
  if (row["status"] !== "processing") return row;

  const rowId = String(row["id"]);
  const source = String(row["source"] ?? "practice");

  const writingAttemptId = row["writing_attempt_id"] as string | null;
  if (writingAttemptId) {
    const { data: writingAttempt } = await supabase
      .from("ai_writing_attempts")
      .select("*")
      .eq("id", writingAttemptId)
      .maybeSingle();

    if (!writingAttempt) return row;
    const attempt = writingAttempt as Record<string, unknown>;
    if (attempt["status"] === "processing") return row;

    if (attempt["status"] === "error") {
      await supabase
        .from("ai_teacher_reviews")
        .update({
          status: "error",
          error_message: String(
            attempt["error_message"] ?? "Không thể tạo AI Teacher review.",
          ),
          updated_at: new Date().toISOString(),
        })
        .eq("id", rowId);
      return {
        ...row,
        status: "error",
        error_message: attempt["error_message"],
      };
    }

    const payload = await ensureVietnameseUserFacingJson(
      getOpenAIKey(),
      buildWritingReviewPayload({
        reviewId: rowId,
        source,
        row: attempt,
      }),
      "writing.teacher_review_hydration",
    );
    await supabase
      .from("ai_teacher_reviews")
      .update({
        status: "ready",
        verdict: payload.verdict,
        result_payload: payload,
        updated_at: new Date().toISOString(),
      })
      .eq("id", rowId);
    return {
      ...row,
      status: "ready",
      verdict: payload.verdict,
      result_payload: payload,
    };
  }

  const speakingAttemptId = row["speaking_attempt_id"] as string | null;
  if (!speakingAttemptId) return row;

  const { data: speakingAttempt } = await supabase
    .from("ai_speaking_attempts")
    .select("*")
    .eq("id", speakingAttemptId)
    .maybeSingle();

  if (!speakingAttempt) return row;
  const attempt = speakingAttempt as Record<string, unknown>;
  if (attempt["status"] === "processing") return row;

  if (attempt["status"] === "error") {
    await supabase
      .from("ai_teacher_reviews")
      .update({
        status: "error",
        error_message: String(
          attempt["error_message"] ?? "Không thể tạo AI Teacher review.",
        ),
        updated_at: new Date().toISOString(),
      })
      .eq("id", rowId);
    return {
      ...row,
      status: "error",
      error_message: attempt["error_message"],
    };
  }

  const payload = await ensureVietnameseUserFacingJson(
    getOpenAIKey(),
    buildSpeakingReviewPayload({
      reviewId: rowId,
      source,
      row: attempt,
    }),
    "speaking.teacher_review_hydration",
  );
  await supabase
    .from("ai_teacher_reviews")
    .update({
      status: "ready",
      verdict: payload.verdict,
      result_payload: payload,
      updated_at: new Date().toISOString(),
    })
    .eq("id", rowId);

  return {
    ...row,
    status: "ready",
    verdict: payload.verdict,
    result_payload: payload,
  };
}

function jsonResponse(body: Record<string, unknown>, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function buildPendingPayload(row: Record<string, unknown>) {
  const modality = String(row["modality"] ?? "objective");
  let message = "AI Teacher đang tạo nhận xét cho câu này.";

  if (row["writing_attempt_id"]) {
    message = "AI Teacher đang đợi bài viết được chấm xong để tạo nhận xét.";
  } else if (row["speaking_attempt_id"]) {
    message =
      "AI Teacher đang đợi transcript và kết quả chấm bài nói để tạo nhận xét.";
  } else if (modality === "objective") {
    message = "AI Teacher đang phân tích câu trả lời và tạo nhận xét.";
  }

  return {
    status: "pending",
    review_id: row["id"],
    message,
  };
}
