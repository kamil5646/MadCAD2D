# MadCAD License Registry Worker

Cloudflare Worker, który udostępnia publiczny rejestr licencji dla aplikacji oraz prywatny endpoint aktualizacji dla panelu admin.

## Endpointy

- `GET /v1/license-registry` - publiczny odczyt rejestru (dla aplikacji)
- `POST /v1/license-registry` - prywatna aktualizacja rejestru (Bearer token)
- `GET /healthz` - health check

## Wymagania

- Cloudflare account
- `wrangler login`

## Setup

1. Wejdź do katalogu worker:

```bash
cd cloudflare/license-registry-worker
npm install
```

2. Utwórz KV namespace:

```bash
npx wrangler kv namespace create LICENSE_REGISTRY_KV
```

3. Wklej zwrócony `id` do `wrangler.toml` (`[[kv_namespaces]].id`).

4. Ustaw sekret admina (token używany tylko przez panel admin):

```bash
npx wrangler secret put ADMIN_TOKEN
```

5. Deploy:

```bash
npm run deploy
```

## Użycie z frontendem

W panelu admin na stronie MadCAD wpisz:

- URL API: `https://<twoj-worker>.workers.dev/v1/license-registry`
- Admin token: ten sam co `ADMIN_TOKEN`

Po tym każda zmiana tokenów w panelu będzie automatycznie wysyłana do Workera.

## Użycie z aplikacją desktop

Po pierwszym deployu zaktualizuj plik:

- `docs/license-endpoints.json`

Dodaj tam URL endpointu Workera (na pierwszej pozycji w `registryUrls`), np.:

```json
{
  "version": 1,
  "updatedAt": "2026-03-08T18:45:00Z",
  "registryUrls": [
    "https://<twoj-worker>.workers.dev/v1/license-registry",
    "https://kamil5646.github.io/MadCAD2D/license-registry.json"
  ]
}
```

Aplikacja pobiera ten plik dynamicznie, więc nie wymaga nowego buildu po zmianie URL backendu.
