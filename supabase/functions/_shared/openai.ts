export function getOpenAIKey(): string {
  const key = Deno.env.get('OPENAI_API_KEY');
  if (!key) throw new Error('OPENAI_API_KEY secret is not set');
  return key;
}

export async function chatComplete(
  apiKey: string,
  systemPrompt: string,
  userMessage: string,
): Promise<Record<string, unknown>> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 30_000);

  try {
    const res = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-4o-mini',
        response_format: { type: 'json_object' },
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userMessage },
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
    if (!content) throw new Error('Empty OpenAI response');
    return JSON.parse(content);
  } finally {
    clearTimeout(timer);
  }
}

export async function transcribeAudio(
  apiKey: string,
  audioBytes: Uint8Array,
  filename: string,
): Promise<string> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 60_000);

  try {
    const form = new FormData();
    const blob = new Blob([audioBytes], { type: 'audio/m4a' });
    form.append('file', blob, filename);
    form.append('model', 'whisper-1');
    form.append('language', 'cs'); // Czech — helps Whisper accuracy

    const res = await fetch('https://api.openai.com/v1/audio/transcriptions', {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${apiKey}` },
      body: form,
      signal: controller.signal,
    });

    if (!res.ok) {
      const err = await res.text();
      throw new Error(`Whisper error ${res.status}: ${err}`);
    }

    const data = await res.json();
    return data.text ?? '';
  } finally {
    clearTimeout(timer);
  }
}
