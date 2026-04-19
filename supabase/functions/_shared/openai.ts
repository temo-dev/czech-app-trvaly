export function getOpenAIKey(): string {
  const key = Deno.env.get("OPENAI_API_KEY");
  if (!key) throw new Error("OPENAI_API_KEY secret is not set");
  return key;
}

export async function chatComplete(
  apiKey: string,
  systemPrompt: string,
  userMessage: string,
  timeoutMs = 30_000,
): Promise<Record<string, unknown>> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const res = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "gpt-4.1-mini",
        response_format: { type: "json_object" },
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: userMessage },
        ],
        temperature: 0.3,
      }),
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
  detectedLanguage: string; // ISO 639-1 code, e.g. 'cs', 'en', 'vi'
}

export async function transcribeAudio(
  apiKey: string,
  audioBytes: Uint8Array,
  filename: string,
): Promise<TranscribeResult> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 60_000);

  try {
    const form = new FormData();
    const audioChunk = audioBytes.slice();
    const blob = new Blob([audioChunk], { type: "audio/m4a" });
    form.append("file", blob, filename);
    form.append("model", "whisper-1");
    // Use verbose_json to get the detected language — do NOT force 'cs' so
    // that Whisper can tell us when the student speaks the wrong language.
    form.append("response_format", "verbose_json");

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
      detectedLanguage: (data.language as string | undefined) ?? "unknown",
    };
  } finally {
    clearTimeout(timer);
  }
}
