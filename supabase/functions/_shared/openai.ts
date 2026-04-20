export function getOpenAIKey(): string {
  const key = Deno.env.get("OPENAI_API_KEY");
  if (!key) throw new Error("OPENAI_API_KEY secret is not set");
  return key;
}

function readEnv(name: string): string | null {
  const value = Deno.env.get(name)?.trim();
  return value && value.length > 0 ? value : null;
}

export function getConfiguredModel(envName: string, fallback: string): string {
  return readEnv(envName) ?? fallback;
}

export function getDefaultChatModel(): string {
  return getConfiguredModel("OPENAI_DEFAULT_CHAT_MODEL", "gpt-4.1-mini");
}

export function getSpeakingTranscriptionModel(): string {
  return getConfiguredModel(
    "OPENAI_SPEAKING_TRANSCRIBE_MODEL",
    "gpt-4o-transcribe",
  );
}

export function getSpeakingScoringModel(): string {
  return getConfiguredModel("OPENAI_SPEAKING_SCORING_MODEL", "gpt-5-mini");
}

export function getWritingScoringModel(): string {
  return getConfiguredModel("OPENAI_WRITING_SCORING_MODEL", "gpt-5-mini");
}

export function getQuestionFeedbackModel(): string {
  return getConfiguredModel("OPENAI_QUESTION_FEEDBACK_MODEL", "gpt-5-mini");
}

export function getObjectiveReviewModel(): string {
  return getConfiguredModel("OPENAI_OBJECTIVE_REVIEW_MODEL", "gpt-5-mini");
}

export function getExamSynthesisModel(): string {
  return getConfiguredModel("OPENAI_EXAM_SYNTHESIS_MODEL", "gpt-5.1");
}

export function getVietnameseGuardModel(): string {
  return getConfiguredModel("OPENAI_VIETNAMESE_GUARD_MODEL", "gpt-5-mini");
}

export interface ChatCompleteOptions {
  model?: string;
  timeoutMs?: number;
  temperature?: number;
}

export async function chatComplete(
  apiKey: string,
  systemPrompt: string,
  userMessage: string,
  options: number | ChatCompleteOptions = 30_000,
): Promise<Record<string, unknown>> {
  const normalizedOptions = typeof options === "number"
    ? { timeoutMs: options }
    : options;
  const model = normalizedOptions.model ?? getDefaultChatModel();
  const timeoutMs = normalizedOptions.timeoutMs ?? 30_000;
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const body: Record<string, unknown> = {
      model,
      response_format: { type: "json_object" },
      messages: [
        { role: "system", content: systemPrompt },
        { role: "user", content: userMessage },
      ],
    };

    const temperature = normalizedOptions.temperature ?? 0.3;
    if (!model.startsWith("gpt-5")) {
      body.temperature = temperature;
    }

    const res = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
      signal: controller.signal,
    });

    if (!res.ok) {
      const err = await res.text();
      throw new Error(`OpenAI chat error ${res.status}: ${err}`);
    }

    const data = await res.json();
    const content = data.choices?.[0]?.message?.content;
    if (!content) throw new Error("Empty OpenAI response");
    return JSON.parse(content);
  } finally {
    clearTimeout(timer);
  }
}

export interface TranscribeResult {
  text: string;
  detectedLanguage: string | null; // ISO 639-1 code, e.g. 'cs', 'en', 'vi'
}

export interface TranscribeAudioOptions {
  model?: string;
  timeoutMs?: number;
  language?: string;
  prompt?: string;
}

export async function transcribeAudio(
  apiKey: string,
  audioBytes: Uint8Array,
  filename: string,
  options: TranscribeAudioOptions = {},
): Promise<TranscribeResult> {
  const model = options.model ?? "whisper-1";
  const timeoutMs = options.timeoutMs ?? 60_000;
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const form = new FormData();
    const audioChunk = audioBytes.slice();
    const blob = new Blob([audioChunk], { type: "audio/m4a" });
    form.append("file", blob, filename);
    form.append("model", model);
    if (options.language) {
      form.append("language", options.language);
    }
    if (options.prompt) {
      form.append("prompt", options.prompt);
    }
    // GPT-4o transcription models only support JSON output.
    if (model === "whisper-1") {
      form.append("response_format", "verbose_json");
    } else {
      form.append("response_format", "json");
    }

    const res = await fetch("https://api.openai.com/v1/audio/transcriptions", {
      method: "POST",
      headers: { "Authorization": `Bearer ${apiKey}` },
      body: form,
      signal: controller.signal,
    });

    if (!res.ok) {
      const err = await res.text();
      throw new Error(`Whisper error ${res.status}: ${err}`);
    }

    const data = await res.json();
    return {
      text: data.text ?? "",
      detectedLanguage: (data.language as string | undefined) ?? null,
    };
  } finally {
    clearTimeout(timer);
  }
}
