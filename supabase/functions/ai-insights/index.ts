// Supabase Edge Function: ai-insights
//
// The app sends a compact spending summary; this function calls OpenAI with a
// SERVER-SIDE key and returns structured insights. The API key never leaves the
// server. Set it once, then deploy:
//   supabase secrets set OPENAI_API_KEY=sk-...
//   supabase secrets set OPENAI_MODEL=gpt-4o        # optional; default gpt-4o
//   supabase functions deploy ai-insights
//
// Swap models any time via the OPENAI_MODEL secret (e.g. gpt-4o-mini to cut
// cost ~40x) — no code change or redeploy of this file needed for a re-set.
//
// Supabase verifies the caller's JWT before this runs (default), so only
// signed-in users can invoke it. Premium is gated in the app before calling.

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY") ?? "";
const MODEL = Deno.env.get("OPENAI_MODEL") ?? "gpt-4o";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// Shape we force the model to return via OpenAI structured outputs.
const schema = {
  type: "object",
  additionalProperties: false,
  properties: {
    summary: { type: "string" },
    // Overall financial-health score, 0-100 (enforced by the prompt).
    score: { type: "integer" },
    scoreLabel: { type: "string" },
    insights: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        properties: {
          title: { type: "string" },
          detail: { type: "string" },
          tone: { type: "string", enum: ["positive", "warning", "neutral"] },
        },
        required: ["title", "detail", "tone"],
      },
    },
    tip: { type: "string" },
  },
  required: ["summary", "score", "scoreLabel", "insights", "tip"],
};

// Human-readable names for the languages the app ships, so the model gets an
// unambiguous instruction. Unknown codes fall back to the code itself.
const LANGUAGE_NAMES: Record<string, string> = {
  en: "English",
  ru: "Russian (русский)",
};

function systemPrompt(language: string): string {
  const name = LANGUAGE_NAMES[language] ?? language;
  return (
    "You are a sharp, encouraging personal-finance coach. You are given a " +
    "user's spending summary (amounts already in their base currency). Analyse " +
    "it and reply ONLY via the structured schema. Be specific: reference real " +
    "numbers and category names from the data, never invent figures. " +
    "`summary`: one punchy sentence on their money right now. " +
    "`score`: an integer 0-100 rating their financial health this period " +
    "(spending vs income, balance, concentration in one category — higher is " +
    "healthier). `scoreLabel`: 2-4 words for that score (e.g. 'Overspending', " +
    "'On track', 'Great shape'). `insights`: 3-4 concrete observations, each " +
    "with a tone (positive | warning | neutral). `tip`: one specific, " +
    "actionable next step. " +
    // Language comes last so it is the most recent instruction the model sees.
    `Write EVERY human-readable string (summary, scoreLabel, insights.title, ` +
    `insights.detail, tip) in ${name}. Keep category names exactly as the user ` +
    `wrote them — do not translate them. The 'tone' values stay in English ` +
    `because they are enum keys.`
  );
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  if (!OPENAI_API_KEY) {
    return json({ error: "OPENAI_API_KEY is not set on the server." }, 500);
  }

  let payload: Record<string, unknown>;
  try {
    payload = await req.json();
  } catch {
    return json({ error: "Invalid JSON body." }, 400);
  }

  // The app sends the UI language so the coach answers in it.
  const language = typeof payload.language === "string" ? payload.language : "en";

  const res = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "authorization": `Bearer ${OPENAI_API_KEY}`,
    },
    body: JSON.stringify({
      model: MODEL,
      messages: [
        { role: "system", content: systemPrompt(language) },
        {
          role: "user",
          content: "Spending summary (JSON):\n" + JSON.stringify(payload),
        },
      ],
      response_format: {
        type: "json_schema",
        json_schema: { name: "insights", strict: true, schema },
      },
    }),
  });

  if (!res.ok) {
    const text = await res.text();
    return json({ error: `OpenAI error ${res.status}: ${text}` }, 502);
  }

  const data = await res.json();
  const message = data.choices?.[0]?.message;
  if (message?.refusal) return json({ error: "AI declined the request." }, 502);
  const content = message?.content;
  if (typeof content !== "string") {
    return json({ error: "No content returned." }, 502);
  }

  try {
    // With json_schema strict mode the content is guaranteed valid JSON.
    return json(JSON.parse(content), 200);
  } catch {
    return json({ error: "Could not parse AI response." }, 502);
  }
});

function json(body: unknown, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "content-type": "application/json" },
  });
}
