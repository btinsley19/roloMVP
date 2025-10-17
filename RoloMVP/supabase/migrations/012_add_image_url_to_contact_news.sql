-- Add image_url column to contact_news table
-- This column will store the thumbnail/image URL from NewsAPI's urlToImage field

ALTER TABLE contact_news
ADD COLUMN image_url text;

-- Add comment explaining the column
COMMENT ON COLUMN contact_news.image_url IS 'URL to the article thumbnail image from NewsAPI';

