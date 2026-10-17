# Render Environment Setup Checklist (LiveKit Cloud)

Yeh guide Render project owner ke liye hai taaki LiveKit video service properly connect ho sake aur koi secret git ya public chat me leak na ho.

---

## 1. Render Dashboard me kya set karna hai (Required Variables)

Render Dashboard (`https://dashboard.render.com`) me apne web service (`liveapple` ya backend API) ke **Environment** tab me jaakar niche diye 3 variables add/check karein:

| Variable Name | Description | Value Example (Form Only) |
|---|---|---|
| `LIVEKIT_URL` | LiveKit Cloud Server WebSocket URL | `wss://<project-subdomain>.livekit.cloud` (Must start with `wss://`) |
| `LIVEKIT_API_KEY` | LiveKit Project API Key | LiveKit dashboard se copy karein (e.g. `APIxxxxxxxx`) |
| `LIVEKIT_API_SECRET` | LiveKit Project API Secret | LiveKit dashboard se copy karein |

> **IMPORTANT WARNING:**
> Kabhi bhi `LIVEKIT_API_SECRET` ko kisi chat, WhatsApp, email ya GitHub commit me paste na karein. Agar galti se secret leak ho jaye, toh turant LiveKit Cloud Dashboard me jaakar us key ko delete karein aur new API key create karke Render me update karein.

---

## 2. LiveKit Cloud se Credentials kaise nikalein

1. [LiveKit Cloud Console](https://cloud.livekit.io/) me log in karein.
2. Apna project select karein.
3. Left sidebar me **Settings** > **Keys** par click karein.
4. Wahan aapko:
   - **WebSocket URL**: Copy karein. Ensure karein yeh `wss://` se shuru ho raha hai (e.g. `wss://my-school-xyz.livekit.cloud`). `http://` ya `localhost` nahi hona chahiye.
   - **API Key**: Copy karein.
   - **Secret**: **Reveal Secret** par click karke copy karein.
5. Render Dashboard > Services > `liveapple` > **Environment** tab open karein.
6. `LIVEKIT_URL`, `LIVEKIT_API_KEY`, aur `LIVEKIT_API_SECRET` ke samne paste karke **Save Changes** par click karein.

---

## 3. Manual Deploy / Redeploy kaise karein

1. Render Web Service page par top right me **Manual Deploy** button par click karein.
2. **Clear build cache & deploy** ya **Deploy latest commit** select karein.
3. Deploy logs check karein.
   - Agar variables sahi set hain, startup log aayega:
     ```text
     [LiveKit] Configured successfully (wss://<host>).
     ```
   - Agar URL missing ya invalid hai, API crash nahi hogi balki video-degraded mode me start hogi:
     ```text
     [LiveKit WARNING] Video feature is degraded in production: LIVEKIT_URL is invalid/missing. Non-video APIs will remain operational.
     ```

---

## 4. Success kaise Confirm karein (/api/health)

Browser me ya Postman se deployed URL ka health endpoint open karein:
`https://<your-render-domain>/api/health`

### Expected Successful Response:
```json
{
  "status": "ok",
  "timestamp": "2026-10-17T08:45:00.000Z",
  "service": "liveapple-api",
  "livekit": {
    "configured": true,
    "urlHost": "<project-subdomain>.livekit.cloud",
    "urlIsWss": true,
    "usingDefaultKeys": false
  }
}
```

Agar response me:
- `livekit.configured: true`
- `livekit.urlIsWss: true`
- `livekit.usingDefaultKeys: false`

...aata hai, toh video streaming aur class token generation 100% active ho chuka hai!

### Agar `livekit.configured: false` dikhe:
Iska matlab dashboard me variables missing hain ya `wss://` URL nahi dali gayi hai. Non-video routes (login, timetable, student list) chalte rahenge, par live class join karte waqt 503 error (`Video server abhi set nahi hua`) aayega jab tak owner credentials set nahi kar deta.
