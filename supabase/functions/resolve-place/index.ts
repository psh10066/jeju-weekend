// 네이버 지도 링크 → { name, address, url }. 로그인한 사용자만 호출(verify_jwt 기본값)
const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};
const NAVER_HOSTS = /^(naver\.me|(m\.|pcmap\.)?(map|place)\.naver\.com|m\.place\.naver\.com|pcmap\.place\.naver\.com)$/;
const UA = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 Mobile/15E148";

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });

function placeId(url: string): string | null {
  const m = url.match(/\/(?:place|restaurant|cafe|hairshop|hospital|accommodation|attraction)\/(\d{5,})/) ??
    url.match(/[?&](?:id|placeId|pinId)=(\d{5,})/); // 앱 공유 링크는 pinId
  return m?.[1] ?? null;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: cors });
  // 새 API 키 방식에선 게이트웨이 JWT 검증이 꺼져 있어 직접 확인
  const user = await fetch(`${Deno.env.get("SUPABASE_URL")}/auth/v1/user`, {
    headers: { apikey: Deno.env.get("SUPABASE_ANON_KEY")!, Authorization: req.headers.get("Authorization") ?? "" },
  });
  if (!user.ok) return json({ error: "로그인이 필요해요" }, 401);

  let url: string;
  try {
    url = new URL(String((await req.json()).url)).href;
  } catch {
    return json({ error: "링크 형식이 아니에요" }, 400);
  }

  // 짧은 링크는 네이버 도메인 안에서만 리다이렉트를 따라간다 (SSRF 방지)
  for (let hop = 0; hop < 5 && !placeId(url); hop++) {
    if (!NAVER_HOSTS.test(new URL(url).hostname)) return json({ error: "네이버 지도 링크만 넣을 수 있어요" }, 400);
    const res = await fetch(url, { redirect: "manual", headers: { "User-Agent": UA } });
    const next = res.headers.get("location");
    if (!next) break;
    url = new URL(next, url).href;
  }
  if (!NAVER_HOSTS.test(new URL(url).hostname)) return json({ error: "네이버 지도 링크만 넣을 수 있어요" }, 400);

  const id = placeId(url);
  if (!id) return json({ error: "장소를 찾지 못했어요. 장소 상세 화면에서 공유 링크를 복사해 주세요" }, 422);
  const canonical = `https://map.naver.com/p/entry/place/${id}`;

  // shortcut: 공식 API가 아닌 플레이스 페이지를 읽음, 구조가 바뀌면 name/address가 비어 돌아가고 화면에서 직접 입력
  try {
    const html = await (await fetch(`https://m.place.naver.com/place/${id}/home`, { headers: { "User-Agent": UA } })).text();
    const name = html.match(/og:title" content="([^"]+)"/)?.[1].replace(/\s*:\s*네이버[\s\S]*$/, "") || null;
    const address = html.match(/"roadAddress":"([^"]+)"/)?.[1] ?? null;
    return json({ id, url: canonical, name, address });
  } catch {
    return json({ id, url: canonical, name: null, address: null });
  }
});
