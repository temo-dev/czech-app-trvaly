import { corsHeaders } from "../_shared/cors.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  assertCanAccessOwnedRow,
  getAuthUserId,
} from "../_shared/guest_access.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  try {
    const { attempt_id } = await req.json() as { attempt_id: string };

    if (!attempt_id) {
      return new Response(
        JSON.stringify({ status: "error", message: "attempt_id required" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const { data: row, error } = await supabase
      .from("ai_speaking_attempts")
      .select("*")
      .eq("id", attempt_id)
      .maybeSingle();

    if (error || !row) {
      return new Response(
        JSON.stringify({ status: "error", message: "Attempt not found" }),
        {
          status: 404,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const r = row as Record<string, unknown>;
    const requesterUserId = await getAuthUserId(supabase, req);
    try {
      assertCanAccessOwnedRow({
        req,
        row: r,
        requesterUserId,
      });
    } catch (_) {
      return new Response(
        JSON.stringify({ status: "error", message: "Forbidden" }),
        {
          status: 403,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    if (r["status"] === "processing") {
      return new Response(
        JSON.stringify({ status: "pending" }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    if (r["status"] === "error") {
      return new Response(
        JSON.stringify({
          status: "error",
          message: normalizeSpeakingErrorMessage(
            r["error_message"] as string | undefined,
          ),
        }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    // Map DB columns → Flutter _parseEdgeResponse shape
    const metricsDb = (r["metrics"] as Record<string, unknown>) ?? {};
    const issues = (r["issues"] as Array<
      {
        word: string;
        type?: string;
        suggestion?: string;
        explanation?: string;
      }
    >) ?? [];
    const transcript = (r["transcript"] as string) ?? "";

    // metrics list expected by Flutter: [{ label, score, max_score, feedback?, tip? }]
    const metricsList = [
      {
        label: "Phát âm",
        score: Number(metricsDb["pronunciation"] ?? 0),
        max_score: 100,
        feedback: String(metricsDb["pronunciation_feedback"] ?? ""),
        tip: String(metricsDb["pronunciation_tip"] ?? ""),
      },
      {
        label: "Lưu loát",
        score: Number(metricsDb["fluency"] ?? 0),
        max_score: 100,
        feedback: String(
          metricsDb["fluency_feedback"] ?? metricsDb["content_feedback"] ?? "",
        ),
        tip: String(metricsDb["fluency_tip"] ?? metricsDb["content_tip"] ?? ""),
      },
      {
        label: "Từ vựng",
        score: Number(metricsDb["vocabulary"] ?? 0),
        max_score: 100,
        feedback: String(metricsDb["vocabulary_feedback"] ?? ""),
        tip: String(metricsDb["vocabulary_tip"] ?? ""),
      },
      {
        label: "Ngữ pháp",
        score: Number(metricsDb["task_achievement"] ?? 0),
        max_score: 100,
        feedback: String(metricsDb["grammar_feedback"] ?? ""),
        tip: String(metricsDb["grammar_tip"] ?? ""),
      },
    ];

    // Build transcript_words: mark words using their actual issue type
    const issueMap = new Map<
      string,
      { type: string; suggestion: string; explanation: string }
    >();
    for (const issue of issues) {
      issueMap.set(issue.word.toLowerCase(), {
        type: issue.type ?? "pronunciation",
        suggestion: issue.suggestion ?? "",
        explanation: issue.explanation ?? "",
      });
    }
    const transcriptWords = transcript.split(/\s+/).filter(Boolean).map(
      (word) => {
        const clean = word.replace(/[.,!?;:'"()]/g, "");
        const matched = issueMap.get(clean.toLowerCase());
        return matched
          ? { word, issue: matched.type, suggestion: matched.suggestion }
          : { word };
      },
    );

    const overallFeedback = String(metricsDb["overall_feedback"] ?? "") ||
      "Tiếp tục luyện tập để cải thiện kỹ năng nói!";

    const shortTips = (metricsDb["short_tips"] as string[] | undefined) ?? [];

    return new Response(
      JSON.stringify({
        status: "ready",
        attempt_id: r["id"],
        total_score: r["overall_score"] ?? 0,
        max_score: 100,
        metrics: metricsList,
        transcript,
        transcript_words: transcriptWords,
        corrections: String(r["corrected_answer"] ?? "")
          ? [String(r["corrected_answer"])]
          : [],
        corrected_answer: r["corrected_answer"] ?? "",
        short_tips: shortTips,
        overall_feedback: overallFeedback,
        review_mode: metricsDb["review_mode"] ?? "exercise",
        scoring_mode: metricsDb["scoring_mode"] ?? "transcript_fallback",
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (err) {
    console.error("speaking-result error:", err);
    return new Response(
      JSON.stringify({ status: "error", message: String(err) }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});

function normalizeSpeakingErrorMessage(message: string | undefined): string {
  const fallback = "Không thể chấm điểm bài nói. Vui lòng thử ghi âm và nộp lại.";
  const normalized = String(message ?? "").trim();
  if (!normalized) return fallback;

  if (
    normalized.includes("response_format") ||
    normalized.includes("OpenAI audio chat error 400")
  ) {
    return "Hệ thống chấm bài nói vừa gặp lỗi xử lý audio. Vui lòng nộp lại bài nói để chấm lại.";
  }

  return normalized;
}
