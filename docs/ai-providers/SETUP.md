# AI providers (router): setup

Code: `functions/src/ai/router/*`, admin callable `functions/src/ai/adminAi.ts`,
admin panel page `/ai-providers` (greengo-admin-panel, `src/pages/AIProviders.tsx`).

## How it works
- Features ask for a **capability**:
  - `translate_chat`
  - `translate_public`
  - `text_assist`
  - `text_buddies`
  - `tts`
- Each capability has a provider **chain**: the primary provider first, then the fallbacks.
- **Context rules** per capability: max characters, style lines, banned terms, glossary, memory and check-in settings.
- Config doc: `ai_config/main`. It is server-only, versioned in `ai_config/main/history/{version}`, and has a 60 s cache in each function instance.
- **API keys live only in Google Cloud Secret Manager**, as `AI_KEY_<KEYNAME>`. Several providers can share one key name; the Qwen preset uses `dashscope` for every Qwen model, so the secret is `AI_KEY_DASHSCOPE`.
  - Save a key in the admin panel: *AI Providers → API keys → Set / replace key*.
  - Functions read the `latest` version at call time, so no redeploy is needed.
  - The panel can never read a key back.
- **Without `ai_config/main`, everything behaves as before:**
  - Cloud Translation v2 for chat
  - The free Google endpoint for public texts
  - Gemini for the chat helpers
  - Google TTS
- **Consent:** a provider with `minConsentVersion: 3` (Qwen) is used only for users who accepted AI notice v3, the one naming Alibaba Cloud. Everyone else is routed to the next provider in the chain, which is Google.
- **Usage:** `ai_usage_stats/{yyyymmdd}_{shard}` holds calls, items, chars, errors, fallbacks and latency per capability and provider. See *AI Providers → Usage & cost*.

## One-time IAM (per Firebase project)
The functions runtime service accounts need access to the `AI_KEY_*` secrets. Here `PROJECT` is the project id and `NUM` is the project number:

```bash
for SA in NUM-compute@developer.gserviceaccount.com PROJECT@appspot.gserviceaccount.com; do
  gcloud projects add-iam-policy-binding PROJECT --member="serviceAccount:$SA" \
    --role=roles/secretmanager.secretAccessor \
    --condition='expression=resource.name.startsWith("projects/NUM/secrets/AI_KEY_"),title=ai-keys-read'
  gcloud projects add-iam-policy-binding PROJECT --member="serviceAccount:$SA" \
    --role=roles/secretmanager.admin \
    --condition='expression=resource.name.startsWith("projects/NUM/secrets/AI_KEY_"),title=ai-keys-write'
done
```

Production keeps the IAM condition, so the functions can touch only the `AI_KEY_*` secrets.

The condition may block **creating** a new secret: a create is checked against the project, not the secret. If that happens, create each secret once by hand. After that, the admin panel only adds versions:

```bash
gcloud secrets create AI_KEY_DASHSCOPE --replication-policy=automatic --project PROJECT
```

The test project uses the project-level roles without a condition.

## Qwen (Alibaba Cloud Model Studio)
- The endpoint is in the **US (Virginia)** region:
  - text and translation: `https://dashscope-us.aliyuncs.com/compatible-mode/v1`
  - text-to-speech: `https://dashscope-us.aliyuncs.com/api/v1`
- The admin panel's **Load Qwen preset** creates:
  - `qwen_flash` (`qwen-flash`): chat helpers and Buddies
  - `qwen_mt_flash` (`qwen-mt-flash`): chat translation
  - `qwen_mt_public` (`qwen-mt-flash`, no consent gate): public texts
  - `qwen_tts` (`qwen3-tts-flash`): text-to-speech
- **Fallbacks:** Google for every capability except Buddies.
- **Check each model id** with *Load models from provider*, which lists the models your key can call. If a model is not offered in the US region, either change its id (US models may carry a `-us` suffix) or switch that provider to the Singapore endpoint (`https://dashscope-intl.aliyuncs.com/...`).
- Use **Test** on each provider before switching routes.
- Prices: add them per provider in options, for example `{"price":{"inputPer1M":0.05,"outputPer1M":0.4}}`. TTS uses `{"price":{"per10kChars":0.1}}`. The Usage tab then estimates the cost.

## Test environment (`greengo-chat-test`)
- App: https://greengo-chat-test.web.app
- Admin: https://greengo-chat-test-admin.web.app
- **Separate project:** it has its own database, functions, Storage, Secret Manager and placeholder payment secrets. It has no production data.
- **Deploy from this repo:**

  ```bash
  firebase deploy --config firebase.test.json --project test --only ...
  ```

  `firebase.test.json` deploys `firestore.additive.rules`, like production.
- **Functions env:** `functions/.env.greengo-chat-test` is git-ignored and holds random test values.
- **Web build:** for the test build, `lib/firebase_options.dart` is a git-ignored copy whose `web` block points at the test project. Then run:

  ```bash
  bash tools/web/build_web.sh
  firebase deploy --config firebase.test.json --project test --only hosting:app
  ```

- **Admin login:** the test project sends no e-mail, so read the 2FA code with:

  ```bash
  bash tools/test_env/get_admin_2fa_code.sh <email>
  ```

## Production rollout (NOT done; needs the owner's OK)
1. Get legal approval for AI notice v3: the in-app texts `aiConsent*V3` and the Privacy Policy, naming Alibaba Cloud and processing in the USA.
2. Run the IAM commands above on `greengo-chat`.
3. Deploy the functions by name: `adminAi`, `aiAssist`, `synthesizeSpeech`, `translatePrivateText`, `translateMessage`, `batchTranslateMessages`, `translateTexts`, `translateCommunityTips`. Deploy the rules too.
4. Deploy the admin panel. Then, in *AI Providers*: set the DashScope key, **Load Qwen preset**, and **Test** each provider.
5. Release the app with consent v3. Until users accept v3 they stay on Google automatically.
