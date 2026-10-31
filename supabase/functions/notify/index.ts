// 새 글·댓글 → 쓴 사람을 뺀 가족 모두에게 웹 푸시. 글쓴 화면이 insert 직후 { review } 또는 { comment } 로 부른다
import webpush from "npm:web-push@3.6.7";
import { createClient } from "npm:@supabase/supabase-js@2.45.4";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });

webpush.setVapidDetails(
  "https://psh10066.github.io/jeju-weekend/log/",
  Deno.env.get("VAPID_PUBLIC_KEY")!,
  Deno.env.get("VAPID_PRIVATE_KEY")!,
);

// 아빠가 · 딸이
const ga = (role: string) => role + ((role.charCodeAt(role.length - 1) - 0xac00) % 28 ? "이" : "가");
const cut = (s: string, n = 80) => (s.length > n ? s.slice(0, n) + "…" : s);

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: cors });
  // 글쓴이 권한(RLS) 그대로 읽는다. 새 API 키 방식이라 게이트웨이 대신 여기서 로그인 확인
  const sb = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!, {
    global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
  });
  const { data: { user } } = await sb.auth.getUser();
  if (!user) return json({ error: "로그인이 필요해요" }, 401);

  const { review, comment } = await req.json().catch(() => ({}));
  const row = comment
    ? (await sb.from("comments").select("user_id, created_at, body, post:review_id").eq("id", comment).maybeSingle()).data
    : (await sb.from("reviews").select("user_id, created_at, body, post:id, visits(place_name)").eq("id", review).maybeSingle()).data;
  // 본인이 방금 쓴 것만 (남의 글로 알림 보내기·옛 글 재발송 막기)
  if (!row || row.user_id !== user.id || Date.now() - Date.parse(row.created_at) > 60_000) {
    return json({ error: "알림 보낼 글이 아니에요" }, 400);
  }

  const { data: me } = await sb.from("members").select("role").eq("user_id", user.id).single();
  const who = ga(me?.role ?? "가족");
  // deno-lint-ignore no-explicit-any
  const place = (row as any).visits?.place_name;
  const msg = comment
    ? { title: `${who} 댓글을 달았어요`, body: cut(row.body) }
    : { title: `${who} 새 글을 올렸어요`, body: [place && `📍 ${place}`, row.body && cut(row.body)].filter(Boolean).join(" · ") || "사진을 올렸어요" };

  const { data: subs } = await sb.from("push_subscriptions").select("endpoint, p256dh, auth").neq("user_id", user.id);
  const payload = JSON.stringify({ ...msg, post: row.post, cmt: !!comment });
  const sent = await Promise.all((subs ?? []).map(({ endpoint, p256dh, auth }) =>
    webpush.sendNotification({ endpoint, keys: { p256dh, auth } }, payload, { TTL: 86400, urgency: "high" })
      .then(() => true)
      .catch(async (e: { statusCode?: number; body?: string }) => {
        // 404·410: 앱 삭제·권한 해제로 끝난 구독
        if (e.statusCode === 404 || e.statusCode === 410) await sb.from("push_subscriptions").delete().eq("endpoint", endpoint);
        else console.error("push", e.statusCode, e.body);
        return false;
      })
  ));
  return json({ sent: sent.filter(Boolean).length, of: sent.length });
});
