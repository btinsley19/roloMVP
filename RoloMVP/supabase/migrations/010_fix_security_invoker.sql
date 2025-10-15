-- Fix security issue: Change SECURITY DEFINER to SECURITY INVOKER
-- This ensures RLS policies are respected

-- Drop and recreate the view with security_invoker
DROP VIEW IF EXISTS contacts_needing_news_refresh;

CREATE VIEW contacts_needing_news_refresh
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

-- Recreate the function with SECURITY INVOKER and proper user filtering
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

-- Add comments
COMMENT ON VIEW contacts_needing_news_refresh IS 'Shows high-priority contacts (7-10) that need news refresh (>24h or never fetched) - respects RLS';
COMMENT ON FUNCTION get_news_fetch_stats() IS 'Returns statistics about news fetching coverage for current user - respects RLS';

