// AI stylist: turns the client's quiz answers into 1-3 looks built strictly
// from in-stock catalog items. Claude runs here, server-side, so the API key
// never ships inside the mobile app.
//
// Secrets: supabase secrets set ANTHROPIC_API_KEY=...
// SUPABASE_URL / SUPABASE_ANON_KEY / SUPABASE_SERVICE_ROLE_KEY are provided
// by the Edge runtime automatically.

import Anthropic from "npm:@anthropic-ai/sdk@1.8.0";
import { betaZodOutputFormat } from "npm:@anthropic-ai/sdk@1.8.0/helpers/beta/zod";
import { z } from "npm:zod@4.1.12";
import { createClient } from "npm:@supabase/supabase-js@2.119.0";

const MODEL = "claude-opus-5-5";
const DAILY_LIMIT = 20; // AI requests per client per day

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const ProfileSchema = z.object({
  gender: z.string().max(20).nullable().optional(),
  occasions: z.array(z.string().max(40)).max(10).default([]),
  styles: z.array(z.string().max(40)).max(10).default([]),
  budget: z.number().int().positive().nullable().optional(),
  top_size: z.string().max(10).nullable().optional(),
  colors: z.array(z.string().max(40)).max(12).default([]),
  notes: z.string().max(500).default(""),
});

const LooksSchema = z.object({
  summary: z.string(),
  looks: z.array(
    z.object({
      title: z.string(),
      reason: z.string(),
      product_ids: z.array(z.string()),
    }),
  ),
});

type Product = {
  id: string;
  title: string;
  brand: string;
  price: number;
  category: string;
  sizes: string[];
  stock: number;
  style_tags: string[];
  colors: string[];
};

const SYSTEM = `Ты — ассистент персонального стилиста. Клиент прошёл анкету; собери
для него от 1 до 3 образов ТОЛЬКО из товаров каталога ниже.

Правила:
- Используй только id из каталога, ничего не придумывай.
- В каждом образе: один верх (tops), один низ (bottoms), одна обувь (shoes);
  верхнюю одежду (outerwear) и аксессуары (accessories) добавляй, если они
  уместны и укладываются в бюджет.
- Сумма цен образа не должна превышать бюджет клиента.
- Если указан размер верха, выбирай вещи, где он есть в sizes.
- Образы должны заметно отличаться друг от друга.
- title — короткое название образа (2–4 слова). reason — 1–2 предложения
  на «вы»: почему этот образ подходит под случаи, стиль и цвета клиента.
- summary — одна-две фразы для клиента о подборке. Пиши по-русски, тепло и
  по делу, без эмодзи. Если ничего не подходит — верни пустой список looks и
  в summary предложи написать стилисту.`;

function catalogText(products: Product[]): string {
  // One compact line per item keeps the prompt small.
  return products
    .map((p) =>
      [p.id, p.category, p.title, p.brand, `${p.price}`, `sizes:${p.sizes.join("/")}`,
        `style:${p.style_tags.join("/")}`, `colors:${p.colors.join("/")}`].join(" | ")
    )
    .join("\n");
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  // Who is calling? (JWT is verified by the gateway; we still need the id.)
  const authHeader = req.headers.get("Authorization") ?? "";
  const userClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );
  const { data: { user } } = await userClient.auth.getUser();
  if (!user) return json({ error: "unauthorized" }, 401);

  const parsedBody = z.object({ profile: ProfileSchema }).safeParse(
    await req.json().catch(() => null),
  );
  if (!parsedBody.success) return json({ error: "bad_request" }, 400);
  const profile = parsedBody.data.profile;

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // Simple per-client daily quota protects the API budget.
  const since = new Date(Date.now() - 24 * 3600 * 1000).toISOString();
  const { count } = await admin
    .from("ai_requests")
    .select("id", { count: "exact", head: true })
    .eq("client_id", user.id)
    .gte("created_at", since);
  if ((count ?? 0) >= DAILY_LIMIT) return json({ error: "rate_limited" }, 429);

  const { data: rows, error } = await admin
    .from("products")
    .select("id,title,brand,price,category,sizes,stock,style_tags,colors")
    .eq("is_active", true)
    .gt("stock", 0);
  if (error) return json({ error: "catalog_unavailable" }, 503);
  const products = (rows ?? []) as Product[];
  const byId = new Map(products.map((p) => [p.id, p]));

  // Remember the answers so the stylist sees them next to the chat.
  await admin.from("style_profiles").upsert({
    client_id: user.id,
    answers: profile,
    updated_at: new Date().toISOString(),
  });

  const client = new Anthropic(); // reads ANTHROPIC_API_KEY
  let result: z.infer<typeof LooksSchema> = { summary: "", looks: [] };
  try {
    const response = await client.beta.messages.parse({
      model: MODEL,
      max_tokens: 16000,
      // Quick, interactive request: low effort keeps latency down.
      output_config: { effort: "low", format: betaZodOutputFormat(LooksSchema) },
      // If a safety classifier declines, the API retries on a suitable model.
      betas: ["server-side-fallback-2026-07-01"],
      fallbacks: "default",
      system: [
        { type: "text", text: SYSTEM },
        // Catalog is identical across clients -> cacheable prefix.
        {
          type: "text",
          text: `Каталог (id | категория | название | бренд | цена | ...):\n${catalogText(products)}`,
          cache_control: { type: "ephemeral" },
        },
      ],
      messages: [{
        role: "user",
        content: `Анкета клиента (JSON):\n${JSON.stringify(profile)}`,
      }],
    });
    if (response.stop_reason !== "refusal" && response.parsed_output) {
      result = response.parsed_output;
    }
  } catch (e) {
    if (e instanceof Anthropic.RateLimitError) {
      console.warn("anthropic rate limited");
    } else if (e instanceof Anthropic.APIError) {
      console.error(`anthropic error ${e.status}: ${e.message}`);
    } else {
      console.error("ai-stylist failed", e);
    }
    // Empty looks -> the app falls back to its offline look builder.
  }

  // Never trust model output blindly: keep only real, affordable looks.
  const budget = profile.budget ?? Number.MAX_SAFE_INTEGER;
  const looks = result.looks
    .map((l) => ({ ...l, product_ids: [...new Set(l.product_ids)].filter((id) => byId.has(id)) }))
    .filter((l) => {
      const items = l.product_ids.map((id) => byId.get(id)!);
      const cats = new Set(items.map((p) => p.category));
      const total = items.reduce((s, p) => s + p.price, 0);
      return ["tops", "bottoms", "shoes"].every((c) => cats.has(c)) && total <= budget;
    })
    .slice(0, 3);

  const payload = { summary: result.summary, looks };
  await admin.from("ai_requests").insert({ client_id: user.id, profile, result: payload });
  return json(payload);
});
