const REGISTRY_KEY = "license-registry-v1";
const TOKEN_PREFIX = "M2D2";
const VALID_TOKEN_HASH = /^[a-f0-9]{24,128}$/;
const VALID_TOKEN_FORMAT = /^M2D[0-9]+\.[A-Za-z0-9_-]{8,512}(?:\.[A-Za-z0-9_-]{8,1200})?$/;
const ALLOWED_STATUSES = new Set(["active", "revoked", "blocked", "disabled", "deleted", "inactive"]);
const MAX_TOKENS = 50000;

function buildCorsHeaders(env, request) {
  const requestOrigin = request.headers.get("Origin") || "";
  const allowedOrigins = String(env.ALLOWED_ORIGIN || "")
    .split(",")
    .map((entry) => entry.trim())
    .filter(Boolean);

  let origin = "*";
  if (requestOrigin && requestOrigin !== "null") {
    if (allowedOrigins.length === 0) {
      origin = requestOrigin;
    } else if (allowedOrigins.includes(requestOrigin)) {
      origin = requestOrigin;
    } else {
      origin = allowedOrigins[0];
    }
  } else if (allowedOrigins.length > 0) {
    origin = "*";
  }

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

function normalizeText(value, maxLength) {
  return String(value || "").trim().slice(0, maxLength);
}

function normalizeEmail(value) {
  return String(value || "").trim().toLowerCase().slice(0, 200);
}

function normalizeScope(value) {
  const scope = String(value || "private").trim().toLowerCase();
  return scope === "commercial" ? "commercial" : "private";
}

function normalizeIsoDate(value, fallbackIso) {
  const raw = String(value || "").trim();
  if (!raw) {
    return fallbackIso;
  }
  const parsed = new Date(raw);
  if (Number.isNaN(parsed.getTime())) {
    return fallbackIso;
  }
  return parsed.toISOString();
}

function ensureRegistryShape(payload) {
  const nowIso = new Date().toISOString();
  const mode = String(payload && payload.mode ? payload.mode : "allowlist").trim().toLowerCase();
  const safeMode = mode === "denylist" ? "denylist" : "allowlist";
  const sourceTokens = Array.isArray(payload && payload.tokens) ? payload.tokens : [];

  const seen = new Set();
  const tokens = sourceTokens
    .map((entry) => {
      if (!entry || typeof entry !== "object") {
        return null;
      }
      const tokenHash = normalizeText(entry.tokenHash || entry.hash || "", 128).toLowerCase();
      const statusRaw = normalizeText(entry.status || "active", 20).toLowerCase();
      const status = ALLOWED_STATUSES.has(statusRaw) ? statusRaw : "active";
      if (!VALID_TOKEN_HASH.test(tokenHash) || seen.has(tokenHash)) {
        return null;
      }
      seen.add(tokenHash);
      const issuedAt = normalizeIsoDate(entry.issuedAt, nowIso);
      return {
        tokenHash,
        status,
        reason: normalizeText(entry.reason || "", 240),
        scope: normalizeScope(entry.scope),
        ownerName: normalizeText(entry.ownerName || "", 120),
        email: normalizeEmail(entry.email || ""),
        purpose: normalizeText(entry.purpose || "", 200),
        deviceId: normalizeText(entry.deviceId || "", 200),
        issuedAt,
        updatedAt: normalizeIsoDate(entry.updatedAt, nowIso)
      };
    })
    .filter(Boolean)
    .slice(0, MAX_TOKENS);

  return {
    version: 1,
    mode: safeMode,
    updatedAt: normalizeIsoDate(payload && payload.updatedAt, nowIso),
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
  return ensureRegistryShape(stored);
}

async function writeRegistry(env, registry) {
  const normalized = ensureRegistryShape(registry);
  normalized.updatedAt = new Date().toISOString();
  await env.LICENSE_REGISTRY_KV.put(REGISTRY_KEY, JSON.stringify(normalized));
  return normalized;
}

async function sha256Hex(text) {
  const value = String(text || "");
  const data = new TextEncoder().encode(value);
  const digest = await crypto.subtle.digest("SHA-256", data);
  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

function randomTokenPart() {
  const bytes = new Uint8Array(24);
  crypto.getRandomValues(bytes);
  let binary = "";
  bytes.forEach((value) => {
    binary += String.fromCharCode(value);
  });
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}

function requireAdminAuth(request, env, corsHeaders) {
  const expectedToken = String(env.ADMIN_TOKEN || "").trim();
  if (!expectedToken) {
    return json({ ok: false, error: "ADMIN_TOKEN is not configured" }, { status: 500 }, corsHeaders);
  }
  const providedToken = getAdminBearerToken(request);
  if (!providedToken || !constantTimeEqual(providedToken, expectedToken)) {
    return json({ ok: false, error: "Unauthorized" }, { status: 401 }, corsHeaders);
  }
  return null;
}

function findTokenEntry(registry, tokenHash) {
  return Array.isArray(registry.tokens)
    ? registry.tokens.find((entry) => String(entry.tokenHash || "") === String(tokenHash || "")) || null
    : null;
}

async function handleIssuePrivateToken(request, env, corsHeaders) {
  let payload = null;
  try {
    payload = await request.json();
  } catch (_error) {
    return json({ ok: false, error: "Invalid JSON body" }, { status: 400 }, corsHeaders);
  }

  const ownerName = normalizeText(payload && payload.ownerName, 120);
  const email = normalizeEmail(payload && payload.email);
  const purpose = normalizeText(payload && payload.purpose, 200);
  const deviceId = normalizeText(payload && payload.deviceId, 200);

  if (!ownerName) {
    return json({ ok: false, error: "ownerName is required" }, { status: 400 }, corsHeaders);
  }
  if (!email || !email.includes("@")) {
    return json({ ok: false, error: "valid email is required" }, { status: 400 }, corsHeaders);
  }
  if (!purpose) {
    return json({ ok: false, error: "purpose is required" }, { status: 400 }, corsHeaders);
  }
  if (!deviceId || deviceId.length < 8) {
    return json({ ok: false, error: "valid deviceId is required" }, { status: 400 }, corsHeaders);
  }

  const token = `${TOKEN_PREFIX}.${randomTokenPart()}`;
  const tokenHash = await sha256Hex(token);
  const nowIso = new Date().toISOString();

  const registry = await readRegistry(env);
  const nextEntry = {
    tokenHash,
    status: "active",
    reason: "Token aktywny",
    scope: "private",
    ownerName,
    email,
    purpose,
    deviceId,
    issuedAt: nowIso,
    updatedAt: nowIso
  };

  const filtered = Array.isArray(registry.tokens)
    ? registry.tokens.filter((entry) => String(entry.tokenHash || "") !== tokenHash)
    : [];
  registry.tokens = [nextEntry, ...filtered].slice(0, MAX_TOKENS);
  await writeRegistry(env, registry);

  return json(
    {
      ok: true,
      token,
      payload: {
        v: 2,
        scope: "private",
        ownerName,
        email,
        purpose,
        deviceId,
        issuedAt: nowIso
      }
    },
    { status: 200 },
    corsHeaders
  );
}

async function handleVerifyToken(request, env, corsHeaders) {
  let payload = null;
  try {
    payload = await request.json();
  } catch (_error) {
    return json({ ok: false, error: "Invalid JSON body" }, { status: 400 }, corsHeaders);
  }

  const token = normalizeText(payload && payload.token, 320);
  const deviceId = normalizeText(payload && payload.deviceId, 200);
  if (!VALID_TOKEN_FORMAT.test(token)) {
    return json({ ok: false, error: "Invalid token format" }, { status: 400 }, corsHeaders);
  }

  const tokenHash = await sha256Hex(token);
  const registry = await readRegistry(env);
  const entry = findTokenEntry(registry, tokenHash);

  if (!entry) {
    return json({ ok: false, error: "Token not found" }, { status: 404 }, corsHeaders);
  }
  if (String(entry.status || "").toLowerCase() !== "active") {
    return json({ ok: false, error: "Token is not active" }, { status: 403 }, corsHeaders);
  }
  if (entry.deviceId && deviceId && entry.deviceId !== deviceId) {
    return json({ ok: false, error: "Token is bound to a different device" }, { status: 403 }, corsHeaders);
  }

  return json(
    {
      ok: true,
      tokenHash,
      payload: {
        v: 2,
        scope: normalizeScope(entry.scope),
        ownerName: normalizeText(entry.ownerName, 120),
        email: normalizeEmail(entry.email),
        purpose: normalizeText(entry.purpose, 200),
        deviceId: normalizeText(entry.deviceId || deviceId, 200),
        issuedAt: normalizeIsoDate(entry.issuedAt, new Date().toISOString())
      }
    },
    { status: 200 },
    corsHeaders
  );
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

    if (url.pathname === "/v1/license-tokens/issue-private" && request.method === "POST") {
      return handleIssuePrivateToken(request, env, corsHeaders);
    }

    if (url.pathname === "/v1/license-tokens/verify" && request.method === "POST") {
      return handleVerifyToken(request, env, corsHeaders);
    }

    if (url.pathname === "/v1/license-registry") {
      if (request.method === "GET") {
        const registry = await readRegistry(env);
        return json(registry, { status: 200 }, corsHeaders);
      }

      if (request.method === "POST") {
        const authError = requireAdminAuth(request, env, corsHeaders);
        if (authError) {
          return authError;
        }

        let payload = null;
        try {
          payload = await request.json();
        } catch (_error) {
          return json({ ok: false, error: "Invalid JSON body" }, { status: 400 }, corsHeaders);
        }

        const normalized = await writeRegistry(env, payload);
        return json(
          { ok: true, updatedAt: normalized.updatedAt, tokenCount: normalized.tokens.length },
          { status: 200 },
          corsHeaders
        );
      }

      return json({ ok: false, error: "Method not allowed" }, { status: 405 }, corsHeaders);
    }

    return json({ ok: false, error: "Not found" }, { status: 404 }, corsHeaders);
  }
};
