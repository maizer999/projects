# Baytoti API — contract

Base URL (production): `https://api.mazier.website`

**Auth model:** no user accounts. A list is a shared secret — anyone who knows
`listId` can read/write. `inviteCode` is a short human-friendly alias used only
to look up a `listId` when joining. The Flutter app identifies the editor by a
local display name (set once on first launch).

All requests/responses are JSON. All datetimes are ISO 8601 UTC strings.

## Endpoints

### Health
```
GET /health
→ 200 {"ok": true, "time": "2026-11-19T18:00:00Z"}
```

### Lists
```
POST /lists
body: {"name": "بيت العائلة", "ownerName": "محمد"}
→ 201 {"id": "aB3xK9pL4q", "name": "...", "inviteCode": "7HJ4KM",
        "createdAt": "...", "ownerName": "محمد"}

GET /lists/{id}
→ 200 {"id": "...", "name": "...", "inviteCode": "...", "createdAt": "...",
        "ownerName": "...", "members": ["محمد", "نجوى"]}
→ 404 if not found

GET /lists/by-invite/{code}
→ 200 same shape as GET /lists/{id}
→ 404 if not found

PUT /lists/{id}
body: {"name": "..."}
→ 200 same shape

POST /lists/{id}/join
body: {"name": "نجوى"}
→ 200 same shape (idempotent — adds if not already a member)

DELETE /lists/{id}/members/{name}
→ 204
```

### Purchases
```
GET /lists/{id}/purchases?includeArchived=0
→ 200 [{"id": "...", "itemName": "خبز", "price": 1.5, "category": "food",
         "addedByName": "محمد", "note": null, "archived": false,
         "date": "..."}]

POST /lists/{id}/purchases
body: {"id": "...", "itemName": "...", "price": 1.5, "category": "food",
       "addedByName": "...", "note": null, "date": "..."}
→ 201 the created purchase

PUT /lists/{id}/purchases/{itemId}
body: any of the above fields
→ 200 the updated purchase

DELETE /lists/{id}/purchases/{itemId}
→ 204

POST /lists/{id}/purchases/archive-older
body: {"cutoff": "2026-10-01T00:00:00Z"}
→ 200 {"archived": 42}
```

### Stats
```
GET /lists/{id}/stats?limit=10
→ 200 [{"id": "...", "name": "خبز", "count": 12, "lastUsed": "..."}]
```

## Errors
```
400 {"error": "bad_request", "message": "..."}
404 {"error": "not_found"}
500 {"error": "server_error"}
```

## Notes
- Categories: `food | cleaning | other`.
- Wishlist is **not** synced — kept in `shared_preferences` only (matches web).
- IDs: client generates (10-char alphanumeric for lists, 20-char for purchases).
- `inviteCode`: 6 chars from `ABCDEFGHJKLMNPQRSTUVWXYZ23456789` (no look-alikes).
