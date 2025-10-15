# News Fetching Setup Guide

This guide explains how to set up automatic news fetching for Rolo contacts.

## Overview

The news fetching system consists of:
1. **fetch-contact-news** - Edge Function to fetch news for a single contact (user-triggered)
2. **batch-fetch-news** - Edge Function to fetch news for multiple high-priority contacts (scheduled)
3. **Database helpers** - Views and functions to track news coverage

## Setup Steps

### 1. Configure NewsAPI Key

Already done! You've set `NEWS_API_KEY` in Supabase secrets.

### 2. Deploy Edge Functions

```bash
cd supabase

# Deploy individual fetch function (user-triggered via iOS app)
supabase functions deploy fetch-contact-news

# Deploy batch fetch function (for scheduled jobs)
supabase functions deploy batch-fetch-news
```

### 3. Run Database Migration

```bash
supabase db push
```

This creates:
- `contacts_needing_news_refresh` view - Shows which contacts need news
- `get_news_fetch_stats()` function - Returns news coverage statistics

### 4. Set Up Scheduled Fetching (Choose One)

#### Option A: GitHub Actions (Recommended for MVP)

Create `.github/workflows/fetch-news.yml`:

```yaml
name: Fetch News Daily

on:
  schedule:
    - cron: '0 6 * * *'  # 6 AM UTC daily
  workflow_dispatch:  # Allow manual trigger

jobs:
  fetch-news:
    runs-on: ubuntu-latest
    steps:
      - name: Call Batch Fetch Edge Function
        run: |
          curl -X POST \
            https://[your-project-ref].supabase.co/functions/v1/batch-fetch-news \
            -H "Authorization: Bearer ${{ secrets.SUPABASE_ANON_KEY }}"
```

Add `SUPABASE_ANON_KEY` to GitHub repository secrets.

#### Option B: Supabase pg_cron (Requires Pro Plan)

In Supabase Dashboard → Database → Extensions:
1. Enable `pg_cron` extension
2. Run this SQL:

```sql
SELECT cron.schedule(
  'daily-news-fetch',
  '0 6 * * *',
  $$
  SELECT net.http_post(
    url := 'https://[your-project-ref].supabase.co/functions/v1/batch-fetch-news',
    headers := '{"Authorization": "Bearer [your-service-role-key]"}'::jsonb
  );
  $$
);
```

#### Option C: External Cron Service

Use services like:
- **Cron-job.org** (free)
- **EasyCron**
- **Zapier** (if you have it)

Set up daily POST request to:
```
https://[your-project-ref].supabase.co/functions/v1/batch-fetch-news
```

With header:
```
Authorization: Bearer [your-anon-key]
```

### 5. Manual Testing

Test the batch fetch function:

```bash
curl -X POST \
  https://[your-project-ref].supabase.co/functions/v1/batch-fetch-news \
  -H "Authorization: Bearer [your-anon-key]"
```

Check stats:
```sql
SELECT * FROM get_news_fetch_stats();
SELECT * FROM contacts_needing_news_refresh LIMIT 10;
```

## How It Works

### Individual Contact Fetch (User-Triggered)
1. User opens contact detail page, taps "Fetch News"
2. iOS app calls `NewsService.fetchNews(contactId:)`
3. Service calls `fetch-contact-news` Edge Function
4. Function searches NewsAPI for company name
5. Saves top 5 articles to `contact_news` table
6. Returns results to iOS app

### Batch Fetch (Scheduled)
1. Scheduled job calls `batch-fetch-news` Edge Function
2. Function queries contacts with priority ≥ 7
3. Filters contacts not fetched in last 24 hours
4. Fetches news for up to 30 contacts (stays within 100/day limit)
5. Saves articles to database
6. Returns summary report

## API Rate Limits

**NewsAPI Free Tier:**
- 100 requests/day
- 1 request/second

**Strategy:**
- High-priority contacts (7-10): Auto-fetch daily = ~30 requests
- Medium-priority (4-6): Manual fetch only
- Low-priority (1-3): Manual fetch only
- Leaves ~70 requests for manual user-triggered fetches

## Monitoring

Check news coverage:
```sql
-- See stats
SELECT * FROM get_news_fetch_stats();

-- See which contacts need refresh
SELECT 
  full_name, 
  company_name, 
  relationship_priority,
  last_fetched_at,
  news_count
FROM contacts_needing_news_refresh
LIMIT 20;

-- See recent news
SELECT 
  c.full_name,
  cn.title,
  cn.source,
  cn.published_at,
  cn.fetched_at
FROM contact_news cn
JOIN contacts c ON c.id = cn.contact_id
ORDER BY cn.fetched_at DESC
LIMIT 10;
```

## Troubleshooting

**No news showing up:**
- Check NewsAPI key is set: `supabase secrets list`
- Test Edge Function manually with curl
- Check logs: `supabase functions logs fetch-contact-news`

**Rate limit errors:**
- Reduce batch size in `batch-fetch-news` (currently 30)
- Increase schedule interval (currently daily)

**Duplicate articles:**
- The system deduplicates by URL automatically

## Future Enhancements

- LLM summarization: "Why this matters to you"
- Topic extraction and filtering
- Deduplicate across contacts (same article about company X)
- Notification when important news is found
- Support for more news sources (LinkedIn, Twitter, etc.)

