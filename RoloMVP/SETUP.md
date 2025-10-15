# Setup Instructions

## 🔐 Configuration Setup

### First Time Setup

1. **Copy the config template:**
   ```bash
   cd Resources
   cp Config.xcconfig.template Config.xcconfig
   ```

2. **Add your Supabase credentials:**
   - Open `Resources/Config.xcconfig`
   - Replace `https://your-project.supabase.co` with your actual Supabase URL
   - Replace `your-anon-key-here` with your actual anon key

3. **Verify it's ignored by git:**
   ```bash
   git status
   # Config.xcconfig should NOT appear in the list
   ```

### Getting Supabase Credentials

1. Go to your [Supabase Dashboard](https://app.supabase.com)
2. Select your project
3. Go to **Settings** → **API**
4. Copy:
   - **Project URL** → `SUPABASE_URL`
   - **anon public key** → `SUPABASE_ANON_KEY`

---

## 🚀 Running the App

1. Open `RoloMVP.xcodeproj` in Xcode
2. Select a simulator or device
3. Press **Cmd+R** to build and run

---

## 🤖 AI Chat Setup (Optional)

If you want to use the AI chat feature:

1. **Set OpenAI API Key in Supabase:**
   - Go to Supabase Dashboard → **Settings** → **Edge Functions** → **Secrets**
   - Add: `OPENAI_API_KEY = sk-proj-...`

2. **Deploy the Edge Function:**
   ```bash
   # Install Supabase CLI
   brew install supabase/tap/supabase
   
   # Login and link project
   supabase login
   cd supabase
   supabase link --project-ref your-project-ref
   
   # Deploy
   supabase functions deploy contact-chat
   ```

---

## ⚠️ Security Notes

- **Never commit** `Config.xcconfig` to git (it contains secrets)
- **Always use** `Config.xcconfig.template` as the shareable version
- **OpenAI API keys** should only be in Supabase secrets, never in the iOS app

---

## 🆘 Troubleshooting

### "Invalid Supabase URL" error
- Check that `Config.xcconfig` exists and has correct values
- Verify it's linked in Xcode project settings

### AI Chat not working
- Verify OpenAI API key is set in Supabase secrets
- Check that edge function is deployed: `supabase functions list`

### Build errors
- Clean build folder: **Cmd+Shift+K**
- Delete derived data: **Cmd+Option+Shift+K**

