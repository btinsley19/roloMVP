# News Fetching Implementation Overview

## Architecture

The news fetching system uses a lightweight MVP approach with NewsAPI.org (free tier: 100 requests/day) to fetch news for contacts based on their company names.

### High-Level Flow
```
iOS App → NewsService → Edge Function → NewsAPI → Database → iOS App
```

### Complete News Lifecycle

#### 1. Fetching (User-Triggered)
**Trigger:** User taps "Fetch News" button on contact's News tab

**Steps:**
1. `ContactDetailView` → User taps "Fetch News"
2. `ContactDetailViewModel.fetchNews()` → Calls service
3. `NewsService.fetchNews(contactId)` → Makes HTTP request to Edge Function
4. Edge Function authenticates user via JWT token
5. Edge Function queries NewsAPI.org for articles about contact's company
6. Edge Function saves 3-5 articles to `contact_news` table
7. iOS reloads news from database to display updated list

**Files:**
- `Features/Contacts/Views/ContactDetailView.swift` - UI with "Fetch News" button
- `Features/Contacts/ViewModels/ContactDetailViewModel.swift` - Calls `fetchNews()`
- `Core/Services/NewsService.swift` - HTTP request to Edge Function
- `supabase/functions/fetch-contact-news/index.ts` - Edge Function logic

#### 2. Storage (Database)
**Location:** `contact_news` table in Supabase PostgreSQL

**Stored Fields:**
- `id` - UUID primary key
- `contact_id` - FK to contacts table
- `source` - News source name (e.g., "Reuters")
- `title` - Article headline
- `url` - Article URL (unique per contact for deduplication)
- `summary` - Article description/excerpt
- `published_at` - When article was published
- `fetched_at` - When we retrieved it from NewsAPI
- `topics` - Array of topic tags (future use)
- `created_at` - When saved to our database

**Deduplication:** Articles with same URL for same contact are skipped

#### 3. Display (Reading from Database)
News articles are displayed in three places in the app:

**A. Contact Detail → News Tab**
- **Query:** `NewsService.list(contactId: UUID)`
- **Purpose:** Show all news for THIS specific contact
- **Display:** Vertical list of article cards
- **Action:** User can tap "Read More" to open article in browser

**B. Home Page → Recent News Section**
- **Query:** `NewsService.listRecent(userId: UUID, limit: 20)` filtered to last 7 days
- **Purpose:** Quick preview of recent news across network
- **Display:** Horizontal scrolling cards
- **Action:** "See All" navigates to full News feed

**C. News Page → Full Feed**
- **Query:** `NewsService.listRecent(userId: UUID, limit: 50)`
- **Purpose:** Browse all news articles across all contacts
- **Display:** Vertical scrolling list, sorted by published date
- **Action:** Pull-to-refresh reloads from database

**Query Logic:**
`listRecent()` performs two database queries:
1. Fetch all contact IDs for the user (`SELECT id FROM contacts WHERE user_id = ?`)
2. Fetch news for those contacts (`SELECT * FROM contact_news WHERE contact_id IN (...)`)
3. Results sorted by `published_at DESC`

## Components

### 1. Edge Functions

#### `fetch-contact-news` (User-Triggered)
- **Purpose**: Fetch news for a single contact when user taps "Fetch News"
- **Input**: `{ "contactId": "uuid" }`
- **Process**:
  1. Authenticates user via JWT token
  2. Fetches contact details (company_name, full_name)
  3. Searches NewsAPI for company name (or contact name if no company)
  4. Returns top 5 articles from last 30 days
  5. Saves articles to `contact_news` table
  6. Deduplicates by URL
- **Output**: `{ "success": true, "articles": [...] }`

#### `batch-fetch-news` (Scheduled)
- **Purpose**: Automatically fetch news for high-priority contacts (priority ≥ 7)
- **Process**: 
  1. Gets contacts with priority ≥ 7 and company names
  2. Filters contacts not fetched in last 24 hours
  3. Processes max 30 contacts per run
  4. Fetches news for each contact
- **Usage**: Called by GitHub Actions/cron job daily

### 2. iOS Services

#### `NewsService.swift`
- **`fetchNews(contactId:)`**: Calls Edge Function to fetch news for specific contact
- **`list(contactId:)`**: Gets all news for a contact from database
- **`listRecent(userId:)`**: Gets recent news across all user's contacts
- **Authentication**: Uses `URLSession` with Bearer token + apikey headers

#### Key Methods:
```swift
// Fetch news from NewsAPI (user-triggered)
func fetchNews(contactId: UUID) async throws -> [ContactNews]

// Get news from database
func list(contactId: UUID) async throws -> [ContactNews]
func listRecent(userId: UUID, limit: Int) async throws -> [ContactNews]
```

### 3. Database Schema

#### `contact_news` table:
```sql
CREATE TABLE contact_news (
  id UUID PRIMARY KEY,
  contact_id UUID REFERENCES contacts(id),
  source TEXT,                    -- e.g., 'Reuters', 'TechCrunch'
  title TEXT,                     -- Article title
  url TEXT,                       -- Article URL
  summary TEXT,                   -- Article description/summary
  published_at TIMESTAMPTZ,       -- When article was published
  fetched_at TIMESTAMPTZ,         -- When we fetched it
  topics TEXT[],                 -- Array of topics (future use)
  created_at TIMESTAMPTZ
);
```

#### Helper Views:
- `contacts_needing_news_refresh`: Shows high-priority contacts needing news
- `get_news_fetch_stats()`: Returns news coverage statistics

### 4. UI Components

#### Contact Detail → News Tab
- Shows 3-5 fetched articles per contact
- "Fetch News" button with loading states
- "Refresh News" button for existing articles
- Displays: title, summary, source, published date, link

#### Home Page
- Shows 10-20 recent articles (last 7 days) from all contacts
- Horizontal scrolling cards
- Links to full news feed

#### Main News Feed
- Shows all articles (up to 50) sorted by published date
- Pull-to-refresh capability
- Links to read full articles

## Authentication Flow

### iOS App → Edge Function
```swift
// Get fresh session (refresh if needed)
_ = try await client.auth.refreshSession()
let session = try await client.auth.session
let accessToken = session.accessToken

// Make request with proper headers
var request = URLRequest(url: edgeFunctionURL)
request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
```

### Edge Function → Supabase
```typescript
// Create Supabase client with user's auth token
const supabase = createClient(
  Deno.env.get('SUPABASE_URL'),
  Deno.env.get('SUPABASE_ANON_KEY'),
  { global: { headers: { Authorization: authHeader } } }
)

// Verify user authentication
const { data: { user }, error } = await supabase.auth.getUser()
```

## NewsAPI Integration

### API Details
- **Provider**: NewsAPI.org
- **Free Tier**: 100 requests/day, no credit card required
- **Rate Limit**: 1 request/second
- **Search**: By company name (primary) or contact name (fallback)
- **Results**: Top 5 articles per contact, last 30 days, sorted by relevancy

### Request Format
```
GET https://newsapi.org/v2/everything?
  q={company_name}&
  from={30_days_ago}&
  sortBy=relevancy&
  language=en&
  pageSize=5&
  apiKey={NEWS_API_KEY}
```

### Response Format
```json
{
  "status": "ok",
  "totalResults": 1234,
  "articles": [
    {
      "source": { "name": "Reuters" },
      "title": "Company announces...",
      "description": "Article summary...",
      "url": "https://...",
      "publishedAt": "2025-10-15T10:30:00Z"
    }
  ]
}
```

## Rate Limiting Strategy

### Daily Quota (100 requests)
- **30 requests**: High-priority contacts (auto-fetch daily)
- **70 requests**: User-triggered fetches
- **Batch function**: 1-second delays between requests

### Contact Prioritization
- **Priority 7-10**: Auto-fetch daily (scheduled job)
- **Priority 4-6**: Manual fetch only
- **Priority 1-3**: Manual fetch only

## Issues Resolved

### Issue 1: "Unauthorized: Auth session missing!"
**Status:** ✅ FIXED  
**Cause**: Edge function was using `@supabase/supabase-js@2.39.3` while working AI Chat used `@supabase/supabase-js@2`  
**Solution**: Updated Edge Function to use `@supabase/supabase-js@2` (matching AI Chat)

### Issue 2: "The data couldn't be read because it is missing"
**Status:** ✅ FIXED  
**Cause**: `listRecent()` was trying to decode `Contact` model from `.select("id")` query  
**Solution**: Created lightweight `ContactId` struct to decode only the `id` field

### Issue 3: Authentication pattern consistency
**Status:** ✅ FIXED  
**Cause**: NewsService had complex session refresh logic different from working AI Chat  
**Solution**: Simplified NewsService to use `client.auth.session` directly (matching AIChatService)

## Setup Instructions

### 1. NewsAPI Key
```bash
# Set in Supabase secrets
supabase secrets set NEWS_API_KEY=your_newsapi_key
```

### 2. Deploy Edge Functions
```bash
supabase functions deploy fetch-contact-news
supabase functions deploy batch-fetch-news
```

### 3. Database Migration
```bash
supabase db push  # Creates helper views and functions
```

### 4. Scheduled Job (Optional)
Create GitHub Actions workflow:
```yaml
name: Daily News Fetch
on:
  schedule:
    - cron: '0 6 * * *'  # 6 AM UTC daily
jobs:
  fetch-news:
    runs-on: ubuntu-latest
    steps:
      - name: Fetch News
        run: |
          curl -X POST \
            https://[project-ref].supabase.co/functions/v1/batch-fetch-news \
            -H "Authorization: Bearer ${{ secrets.SUPABASE_ANON_KEY }}"
```

## Testing

### Manual Testing
1. Open contact with company name
2. Go to News tab
3. Tap "Fetch News"
4. Wait 2-3 seconds
5. Articles should appear

### Debug Logs
- **iOS**: Check Xcode console for "Got access token: ..."
- **Edge Function**: Check Supabase Dashboard → Logs → Edge Functions
- **Database**: Query `contact_news` table to see saved articles

## File Structure

```
supabase/
├── functions/
│   ├── fetch-contact-news/index.ts    # Single contact fetch
│   └── batch-fetch-news/index.ts      # Batch processing
└── migrations/
    └── 009_schedule_news_fetch.sql     # Helper views/functions

Core/Services/
└── NewsService.swift                   # iOS service layer

Features/
├── Contacts/Views/ContactDetailView.swift  # News tab UI
├── Home/Views/HomeView.swift              # Recent news display
└── News/Views/NewsView.swift              # Full news feed
```

## Future Enhancements

- **LLM Summarization**: "Why this matters to you" personalization
- **Topic Extraction**: Auto-categorize news by topics
- **Deduplication**: Remove duplicate articles across contacts
- **Notifications**: Alert when important news is found
- **More Sources**: LinkedIn, Twitter, company websites
- **Analytics**: Track which contacts generate most relevant news

## Troubleshooting

### Common Errors
1. **"Missing authorization header"**: Check iOS app is logged in
2. **"Auth session missing"**: Token expired, refresh session
3. **"No articles found"**: Company name too generic or no recent news
4. **Rate limit exceeded**: Wait or upgrade NewsAPI plan

### Debug Commands
```bash
# Check Edge Function logs
supabase functions logs fetch-contact-news

# Test Edge Function manually
curl -X POST https://[project].supabase.co/functions/v1/fetch-contact-news \
  -H "Authorization: Bearer [token]" \
  -H "apikey: [anon-key]" \
  -d '{"contactId":"[uuid]"}'

# Check database
SELECT * FROM contact_news ORDER BY fetched_at DESC LIMIT 10;
```

---

**Status**: ✅ Fully functional - contact news fetching, home feed, and news page all working
**Last Updated**: October 15, 2025
**Version**: 1.2.1-MVP

## Quick Start

1. **Fetch news for a contact:**
   - Open any contact (preferably with company name)
   - Go to News tab
   - Tap "Fetch News"
   - Wait 2-3 seconds for articles to load

2. **View all news:**
   - Home page shows recent articles (last 7 days)
   - News tab shows all articles (up to 50)
   - Pull to refresh on both pages

3. **Best practices:**
   - Add company names to contacts for better results
   - NewsAPI free tier: 100 requests/day
   - Articles are cached in database (no re-fetching needed)
