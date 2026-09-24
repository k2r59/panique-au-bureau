const json = (data, status = 200) => Response.json(data, {status, headers: {'Cache-Control': 'no-store'}});
const playerQuery = 'SELECT u.id, u.name, u.avatar, COALESCE(s.best_score, 0) AS score FROM users u LEFT JOIN scores s ON s.user_id = u.id';
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (url.pathname === '/' || url.pathname === '/index.html') {
      return new Response('<!doctype html><html><head><meta name="robots" content="noindex,nofollow"><title></title></head><body style="margin:0;background:white"></body></html>', {headers: {'Content-Type':'text/html; charset=utf-8', 'Cache-Control':'no-store'}});
    }
    if (url.pathname === '/play' || url.pathname === '/play/') {
      return env.ASSETS.fetch(new Request(new URL('/play/index.html', url), request));
    }
    if (url.pathname === '/play/index.wasm') {
      const asset = await env.ASSETS.fetch(new Request(new URL('/play/index.wasm.gz', url), {method: request.method, headers: {'Accept-Encoding': 'identity'}}));
      const headers = new Headers(asset.headers);
      headers.set('Content-Type', 'application/wasm');
      headers.set('Content-Encoding', 'gzip');
      headers.set('Cache-Control', 'public, max-age=0, must-revalidate');
      return new Response(asset.body, {status: asset.status, headers, encodeBody: "manual"});
    }
    if (!url.pathname.startsWith('/api/')) return env.ASSETS.fetch(request);
    try {
      if (request.method === 'GET' && url.pathname === '/api/health') {
        await env.DB.prepare('SELECT 1').first();
        return json({ok: true, project: 'panique-au-bureau', database: 'D1'});
      }
      if (request.method === 'GET' && url.pathname === '/api/leaderboard') {
        const {results} = await env.DB.prepare(`${playerQuery} WHERE s.best_score > 0 ORDER BY s.best_score DESC, s.updated_at ASC, u.id LIMIT 20`).all();
        return json({players: results});
      }
      if (!['/api/profile', '/api/score'].includes(url.pathname)) return json({error: 'Not found'}, 404);
      if (!['GET', 'PUT', 'POST'].includes(request.method)) return json({error: 'Method not allowed'}, 405);
      const token = request.headers.get('Authorization')?.match(/^Bearer ([a-f0-9]{64})$/)?.[1];
      if (!token) return json({error: 'Unauthorized'}, 401);
      const hash = [...new Uint8Array(await crypto.subtle.digest('SHA-256', new TextEncoder().encode(token)))].map(v => v.toString(16).padStart(2, '0')).join('');
      if (request.method === 'GET' && url.pathname === '/api/profile') {
        const player = await env.DB.prepare(`${playerQuery} WHERE u.token_hash = ?`).bind(hash).first();
        return player ? json({player}) : json({error: 'Not found'}, 404);
      }
      const origin = request.headers.get('Origin');
      if (origin && origin !== url.origin) return json({error: 'Origin not allowed'}, 403);
      if (!request.headers.get('Content-Type')?.includes('application/json')) return json({error: 'JSON required'}, 415);
      // Bound the body while streaming, including chunked requests.
      const reader = request.body?.getReader();
      if (!reader) return json({error: 'Body required'}, 400);
      let size = 0, chunks = [];
      for (;;) {
        const {done, value} = await reader.read();
        if (done) break;
        size += value.byteLength;
        if (size > 2048) { await reader.cancel(); return json({error: 'Body too large'}, 413); }
        chunks.push(value);
      }
      const bytes = new Uint8Array(size); let offset = 0;
      for (const chunk of chunks) { bytes.set(chunk, offset); offset += chunk.length; }
      let body;
      try { body = JSON.parse(new TextDecoder().decode(bytes)); } catch { return json({error: 'Invalid JSON'}, 400); }
      if (!body || Array.isArray(body) || typeof body !== 'object') return json({error: 'Invalid body'}, 400);
      if (request.method === 'PUT' && url.pathname === '/api/profile') {
        const name = typeof body.name === 'string' ? body.name.trim() : '';
        if (name.length < 2 || name.length > 16 || /[\p{Cc}\p{Cf}]/u.test(name) || !Number.isInteger(body.avatar) || body.avatar < 1 || body.avatar > 6) return json({error: 'Invalid profile'}, 400);
        await env.DB.prepare('INSERT INTO users (id, token_hash, name, avatar) VALUES (?, ?, ?, ?) ON CONFLICT(token_hash) DO UPDATE SET name=excluded.name, avatar=excluded.avatar').bind(crypto.randomUUID(), hash, name, body.avatar).run();
      } else if (request.method === 'POST' && url.pathname === '/api/score') {
        if (!Number.isInteger(body.score) || body.score < 0 || body.score > 100000) return json({error: 'Invalid score'}, 400);
        await env.DB.prepare('INSERT INTO scores (user_id, best_score) SELECT id, ? FROM users WHERE token_hash = ? ON CONFLICT(user_id) DO UPDATE SET best_score=excluded.best_score, updated_at=CURRENT_TIMESTAMP WHERE excluded.best_score > scores.best_score').bind(body.score, hash).run();
        // Scores are client-reported; this is a casual leaderboard, not a prize system.
      } else return json({error: 'Method not allowed'}, 405);
      const player = await env.DB.prepare(`${playerQuery} WHERE u.token_hash = ?`).bind(hash).first();
      return player ? json({player}) : json({error: 'Not found'}, 404);
    } catch (error) {
      console.error('API operation failed', error?.message);
      return json({error: 'Service temporarily unavailable'}, 503);
    }
  }
};
