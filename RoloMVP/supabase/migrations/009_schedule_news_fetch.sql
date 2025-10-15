-- Migration: Schedule automatic news fetching for high-priority contacts
-- 
-- This migration sets up helper views and functions to support scheduled news fetching.
-- For the actual cron job, you'll need to set it up manually in Supabase Dashboard.
--
-- Setup Instructions:
-- 1. Deploy the batch-fetch-news Edge Function
-- 2. In Supabase Dashboard → Database → Cron Jobs:
--    - Create new job: "Daily News Fetch"
--    - Schedule: "0 6 * * *" (6 AM daily)
--    - Command: Call the batch-fetch-news Edge Function via webhook
--
-- Alternatively, you can use a third-party scheduler (GitHub Actions, etc.)
-- to call: POST https://[project-ref].supabase.co/functions/v1/batch-fetch-news

-- Create a view to easily see which contacts need news refresh
-- Using SECURITY INVOKER to respect RLS policies
CREATE OR REPLACE VIEW contacts_needing_news_refresh
WITH (security_invoker = true)
AS
SELECT 
  c.id,
  c.user_id,
  c.full_name,
  c.company_name,
  c.relationship_priority,
  MAX(cn.fetched_at) as last_fetched_at,
  COUNT(cn.id) as news_count
FROM contacts c
LEFT JOIN contact_news cn ON cn.contact_id = c.id
WHERE 
  c.relationship_priority >= 7
  AND c.company_name IS NOT NULL
  AND c.company_name != ''
GROUP BY c.id, c.user_id, c.full_name, c.company_name, c.relationship_priority
HAVING 
  MAX(cn.fetched_at) IS NULL 
  OR MAX(cn.fetched_at) < NOW() - INTERVAL '24 hours'
ORDER BY c.relationship_priority DESC, MAX(cn.fetched_at) ASC NULLS FIRST;

-- Create a function to get stats about news fetching
-- Using SECURITY INVOKER to respect RLS policies
CREATE OR REPLACE FUNCTION get_news_fetch_stats()
RETURNS TABLE (
  total_contacts BIGINT,
  high_priority_contacts BIGINT,
  contacts_with_news BIGINT,
  contacts_needing_refresh BIGINT,
  total_news_articles BIGINT
)
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
BEGIN
  RETURN QUERY
  SELECT
    (SELECT COUNT(*) FROM contacts WHERE user_id = auth.uid()) as total_contacts,
    (SELECT COUNT(*) FROM contacts WHERE user_id = auth.uid() AND relationship_priority >= 7) as high_priority_contacts,
    (SELECT COUNT(DISTINCT cn.contact_id) FROM contact_news cn JOIN contacts c ON c.id = cn.contact_id WHERE c.user_id = auth.uid()) as contacts_with_news,
    (SELECT COUNT(*) FROM contacts_needing_news_refresh WHERE user_id = auth.uid()) as contacts_needing_refresh,
    (SELECT COUNT(*) FROM contact_news cn JOIN contacts c ON c.id = cn.contact_id WHERE c.user_id = auth.uid()) as total_news_articles;
END;
$$;

-- Grant permissions
GRANT SELECT ON contacts_needing_news_refresh TO authenticated;
GRANT EXECUTE ON FUNCTION get_news_fetch_stats() TO authenticated;

-- Add helpful comments
COMMENT ON VIEW contacts_needing_news_refresh IS 'Shows high-priority contacts (7-10) that need news refresh (>24h or never fetched)';
COMMENT ON FUNCTION get_news_fetch_stats() IS 'Returns statistics about news fetching coverage';

