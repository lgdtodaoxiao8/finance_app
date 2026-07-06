// Supabase Edge Function: ai-insights
//
// The app sends a compact spending summary; this function calls Anthropic with
// a SERVER-SIDE key and returns structured insights. The Anthropic key never
// leaves the server — set it once with:
//   supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
// then deploy:
//   supabase functions deploy ai-insights
//
// Supabase verifies the caller's JWT before this runs (default), so only
// signed-in users can invoke it. Gate premium in the app before calling.

const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY") ?? "";
const MODEL = "claude-opus-4-8";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// Shape we ask Claude to return, enforced via structured outputs.
const schema = {
  type: "object",
  additionalProperties: false,
  properties: {
    summary: { type: "string" },
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
  required: ["summary", "insights", "tip"],
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  if (!ANTHROPIC_API_KEY) {
    return json({ error: "ANTHROPIC_API_KEY is not set on the server." }, 500);
  }

  let payload: unknown;
  try {
    payload = await req.json();
  } catch {
    return json({ error: "Invalid JSON body." }, 400);
  }

  const prompt =
    "You are a sharp, encouraging personal-finance coach. Given this user's " +
    "spending summary (amounts are in their base currency), write a short, " +
    "concrete analysis. Be specific and reference real numbers and category " +
    "names from the data. Return 3-4 insights and one actionable tip. Do not " +
    "invent data that isn't present.\n\nSpending summary (JSON):\n" +
    JSON.stringify(payload);

  const res = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "x-api-key": ANTHROPIC_API_KEY,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model: MODEL,
      max_tokens: 1200,
      output_config: { format: { type: "json_schema", schema } },
      messages: [{ role: "user", content: prompt }],
    }),
  });

  if (!res.ok) {
    const text = await res.text();
    return json({ error: `Anthropic error ${res.status}: ${text}` }, 502);
  }

  const data = await res.json();
  const block = (data.content ?? []).find((b: { type: string }) =>
    b.type === "text"
  );
  if (!block) return json({ error: "No content returned." }, 502);

  try {
    // With output_config.format the text block is guaranteed valid JSON.
    return json(JSON.parse(block.text), 200);
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
