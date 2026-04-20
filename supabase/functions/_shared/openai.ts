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

export function getSpeakingAudioModel(): string {
  return getConfiguredModel("OPENAI_SPEAKING_AUDIO_MODEL", "gpt-audio-mini");
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

interface ChatCompletionMessage {
  role: "system" | "user" | "assistant";
  content: string | Record<string, unknown>[];
}

export async function chatComplete(
  apiKey: string,
  systemPrompt: string,
  userMessage: string,
  options: number | ChatCompleteOptions = 30_000,
): Promise<Record<string, unknown>> {
  return chatCompleteMessages(
    apiKey,
    [
      { role: "system", content: systemPrompt },
      { role: "user", content: userMessage },
    ],
    options,
    { responseFormat: "json_object" },
  );
}

export async function chatCompleteWithAudio(
  apiKey: string,
  systemPrompt: string,
  userMessage: string,
  audioBytes: Uint8Array,
  audioFormat: "wav" | "mp3",
  options: number | ChatCompleteOptions = 30_000,
): Promise<Record<string, unknown>> {
  return chatCompleteMessages(
    apiKey,
    [
      { role: "system", content: systemPrompt },
      {
        role: "user",
        content: [
          { type: "text", text: userMessage },
          {
            type: "input_audio",
            input_audio: {
              data: bytesToBase64(audioBytes),
              format: audioFormat,
            },
          },
        ],
      },
    ],
    options,
    { responseFormat: "none" },
  );
}

async function chatCompleteMessages(
  apiKey: string,
  messages: ChatCompletionMessage[],
  options: number | ChatCompleteOptions = 30_000,
  config: { responseFormat: "json_object" | "none" } = {
    responseFormat: "json_object",
  },
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
      messages,
    };
    if (config.responseFormat === "json_object") {
      body.response_format = { type: "json_object" };
    }

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
    return parseJsonResponseText(
      extractChatCompletionText(data.choices?.[0]?.message?.content),
    );
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
    const blob = new Blob([audioChunk], { type: resolveAudioMimeType(filename) });
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

function extractChatCompletionText(content: unknown): string {
  if (typeof content === "string" && content.trim().length > 0) {
    return content;
  }

  if (Array.isArray(content)) {
    const text = content
      .map((part) => {
        if (!part || typeof part !== "object") return "";
        const record = part as Record<string, unknown>;
        if (typeof record["text"] === "string") return record["text"];
        if (typeof record["content"] === "string") return record["content"];
        return "";
      })
      .join("")
      .trim();

    if (text.length > 0) {
      return text;
    }
  }

  throw new Error("Empty OpenAI response");
}

function parseJsonResponseText(text: string): Record<string, unknown> {
  const trimmed = text.trim();
  const candidates = [
    trimmed,
    trimmed.replace(/^```json\s*/i, "").replace(/^```\s*/i, "").replace(/\s*```$/, ""),
    extractFirstJsonObject(trimmed),
  ].filter((candidate): candidate is string => !!candidate && candidate.trim().length > 0);

  for (const candidate of candidates) {
    try {
      return JSON.parse(candidate) as Record<string, unknown>;
    } catch (_) {
      // try next candidate
    }
  }

  throw new Error(`Invalid JSON response: ${trimmed}`);
}

function extractFirstJsonObject(text: string): string | null {
  const start = text.indexOf("{");
  const end = text.lastIndexOf("}");
  if (start === -1 || end === -1 || end <= start) {
    return null;
  }
  return text.slice(start, end + 1);
}

function bytesToBase64(bytes: Uint8Array): string {
  let binary = "";
  for (const byte of bytes) {
    binary += String.fromCharCode(byte);
  }
  return btoa(binary);
}

function resolveAudioMimeType(filename: string): string {
  const lower = filename.toLowerCase();
  if (lower.endsWith(".wav")) return "audio/wav";
  if (lower.endsWith(".mp3")) return "audio/mpeg";
  return "audio/m4a";
}
