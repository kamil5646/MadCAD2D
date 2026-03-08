const REGISTRY_KEY = "license-registry-v1";
const VALID_TOKEN_HASH = /^[a-f0-9]{24,128}$/;
const ALLOWED_STATUSES = new Set(["active", "revoked", "blocked", "disabled", "deleted", "inactive"]);

function buildCorsHeaders(env, request) {
  const requestOrigin = request.headers.get("Origin") || "";
  const allowedOrigin = String(env.ALLOWED_ORIGIN || "").trim();
  const origin = allowedOrigin || (requestOrigin ? requestOrigin : "*");
  return {
    "Access-Control-Allow-Origin": origin,
    "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type,Authorization",
    "Access-Control-Max-Age": "86400",
    "Vary": "Origin"
  };
}

function json(data, init, corsHeaders) {
  const headers = new Headers(init && init.headers ? init.headers : undefined);
  headers.set("Content-Type", "application/json; charset=utf-8");
  headers.set("Cache-Control", "no-store");
  if (corsHeaders) {
    Object.entries(corsHeaders).forEach(([k, v]) => headers.set(k, v));
  }
  return new Response(JSON.stringify(data, null, 2), {
    status: (init && init.status) || 200,
    headers
  });
}

function constantTimeEqual(a, b) {
  const left = String(a || "");
  const right = String(b || "");
  if (left.length !== right.length) {
    return false;
  }
  let diff = 0;
  for (let i = 0; i < left.length; i += 1) {
    diff |= left.charCodeAt(i) ^ right.charCodeAt(i);
  }
  return diff === 0;
}

function getAdminBearerToken(request) {
  const auth = String(request.headers.get("Authorization") || "").trim();
  if (!auth.toLowerCase().startsWith("bearer ")) {
    return "";
  }
  return auth.slice(7).trim();
}

function normalizeRegistry(payload) {
  const mode = String(payload && payload.mode ? payload.mode : "allowlist").trim().toLowerCase();
  const safeMode = mode === "denylist" ? "denylist" : "allowlist";
  const sourceTokens = Array.isArray(payload && payload.tokens) ? payload.tokens : [];

  const seen = new Set();
  const tokens = sourceTokens
    .map((entry) => {
      if (!entry || typeof entry !== "object") {
        return null;
      }
      const tokenHash = String(entry.tokenHash || entry.hash || "").trim().toLowerCase();
      const statusRaw = String(entry.status || "active").trim().toLowerCase();
      const status = ALLOWED_STATUSES.has(statusRaw) ? statusRaw : "active";
      const reason = String(entry.reason || "").trim();
      if (!VALID_TOKEN_HASH.test(tokenHash)) {
        return null;
      }
      if (seen.has(tokenHash)) {
        return null;
      }
      seen.add(tokenHash);
      return {
        tokenHash,
        status,
        reason: reason.slice(0, 240)
      };
    })
    .filter(Boolean);

  return {
    version: 1,
    mode: safeMode,
    updatedAt: new Date().toISOString(),
    tokens
  };
}

function defaultRegistry() {
  return {
    version: 1,
    mode: "allowlist",
    updatedAt: new Date().toISOString(),
    tokens: []
  };
}

async function readRegistry(env) {
  const stored = await env.LICENSE_REGISTRY_KV.get(REGISTRY_KEY, { type: "json" });
  if (!stored || typeof stored !== "object") {
    return defaultRegistry();
  }
  return normalizeRegistry(stored);
}

export default {
  async fetch(request, env) {
    const corsHeaders = buildCorsHeaders(env, request);
    const url = new URL(request.url);

    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders });
    }

    if (url.pathname === "/healthz") {
      return json({ ok: true, service: "madcad-license-registry" }, { status: 200 }, corsHeaders);
    }

    if (url.pathname !== "/v1/license-registry") {
      return json({ ok: false, error: "Not found" }, { status: 404 }, corsHeaders);
    }

    if (request.method === "GET") {
      const registry = await readRegistry(env);
      return json(registry, { status: 200 }, corsHeaders);
    }

    if (request.method === "POST") {
      const expectedToken = String(env.ADMIN_TOKEN || "").trim();
      if (!expectedToken) {
        return json({ ok: false, error: "ADMIN_TOKEN is not configured" }, { status: 500 }, corsHeaders);
      }
      const providedToken = getAdminBearerToken(request);
      if (!providedToken || !constantTimeEqual(providedToken, expectedToken)) {
        return json({ ok: false, error: "Unauthorized" }, { status: 401 }, corsHeaders);
      }

      let payload = null;
      try {
        payload = await request.json();
      } catch (_error) {
        return json({ ok: false, error: "Invalid JSON body" }, { status: 400 }, corsHeaders);
      }

      const normalized = normalizeRegistry(payload);
      await env.LICENSE_REGISTRY_KV.put(REGISTRY_KEY, JSON.stringify(normalized));
      return json({ ok: true, updatedAt: normalized.updatedAt, tokenCount: normalized.tokens.length }, { status: 200 }, corsHeaders);
    }

    return json({ ok: false, error: "Method not allowed" }, { status: 405 }, corsHeaders);
  }
};
