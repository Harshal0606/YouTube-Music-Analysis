-- YouTube Music Data Analysis using SQL
-- Solutions of 25 business problems

-- 1. Count the Total Number of Music Videos

SELECT 
    COUNT(*) AS total_videos
FROM youtube_music;


-- 2. Find the Average Views and Likes per Video

SELECT 
    ROUND(AVG(view_count)) AS avg_views,
    ROUND(AVG(like_count)) AS avg_likes
FROM youtube_music;


-- 3. Find the Top 10 Most Viewed Videos

SELECT 
    title,
    channel_name,
    view_count
FROM youtube_music
ORDER BY view_count DESC
LIMIT 10;


-- 4. Find the Top 10 Most Liked Videos

SELECT 
    title,
    channel_name,
    like_count
FROM youtube_music
ORDER BY like_count DESC
LIMIT 10;


-- 5. Calculate Engagement Rate (Likes to Views Ratio)

SELECT 
    title,
    channel_name,
    ROUND((like_count::numeric / NULLIF(view_count, 0)) * 100, 2) AS engagement_rate
FROM youtube_music
WHERE view_count > 0
ORDER BY engagement_rate DESC
LIMIT 10;


-- 6. Categorize Videos by Duration and Its Average Views

WITH parsed AS (
  SELECT 
    y.video_id,
    y.title,
    y.view_count,
    COALESCE(h.hours, 0) * 60 +
    COALESCE(m.mins, 0) +
    COALESCE(s.secs, 0) / 60 AS total_minutes
  FROM youtube_music y
  LEFT JOIN LATERAL (
    SELECT (REGEXP_MATCHES(y.duration, 'PT([0-9]+)H'))[1]::NUMERIC AS hours
  ) h ON TRUE
  LEFT JOIN LATERAL (
    SELECT (REGEXP_MATCHES(y.duration, 'PT(?:[0-9]+H)?([0-9]+)M'))[1]::NUMERIC AS mins
  ) m ON TRUE
  LEFT JOIN LATERAL (
    SELECT (REGEXP_MATCHES(y.duration, 'PT(?:[0-9]+H)?(?:[0-9]+M)?([0-9]+)S'))[1]::NUMERIC AS secs
  ) s ON TRUE
)
SELECT 
  CASE
    WHEN total_minutes < 2 THEN 'Short (<2 min)'
    WHEN total_minutes BETWEEN 2 AND 5 THEN 'Medium (2–5 min)'
    ELSE 'Long (>5 min)'
  END AS duration_category,
  COUNT(*) AS total_videos,
  ROUND(AVG(view_count)) AS avg_views,
  ROUND(MIN(total_minutes), 2) AS min_duration,
  ROUND(MAX(total_minutes), 2) AS max_duration
FROM parsed
GROUP BY duration_category
ORDER BY avg_views DESC;


-- 7. Analyze VEVO Videos and Their Performance

SELECT
  CASE
    WHEN channel_name ILIKE '%vevo%' THEN 'VEVO'
    ELSE 'Non-VEVO'
  END AS channel_type,
  COUNT(*) AS total_videos,
  COUNT(DISTINCT channel_name) AS unique_channels,
  ROUND(AVG(view_count)) AS avg_views,
  ROUND(AVG(like_count)) AS avg_likes,
  ROUND(AVG((like_count::numeric / NULLIF(view_count, 0)) * 100), 2) AS avg_engagement_rate
FROM youtube_music
GROUP BY channel_type
ORDER BY total_videos DESC;


-- 8. Find Top 5 Channels by Total Views

SELECT 
    channel_name,
    SUM(view_count) AS total_views
FROM youtube_music
GROUP BY channel_name
ORDER BY total_views DESC
LIMIT 5;


-- 9. Find Top 5 Channels by Engagement (Likes/View Ratio)

SELECT 
    channel_name,
    ROUND(SUM(like_count)::numeric / SUM(view_count)::numeric * 100, 2) AS engagement_rate
FROM youtube_music
GROUP BY channel_name
HAVING SUM(view_count) > 100000
ORDER BY engagement_rate DESC
LIMIT 5;


-- 10. Find Videos with “Official” in Title

SELECT 
    title,
    channel_name,
    view_count
FROM youtube_music
WHERE title ILIKE '%official%'
ORDER BY view_count DESC;


-- 11. Identify “Live” Performance Videos

SELECT 
    title,
    channel_name
FROM youtube_music
WHERE title ILIKE '%live%';


-- 12. Find “Remix” or “Mashup” Videos

SELECT 
    title,
    channel_name
FROM youtube_music
WHERE title ILIKE '%remix%' OR title ILIKE '%mashup%';


-- 13. Detect Outliers — Extremely High Engagement

SELECT 
    title,
    like_count,
    view_count,
    ROUND((like_count::numeric / NULLIF(view_count, 0)) * 100, 2) AS engagement_rate
FROM youtube_music
WHERE view_count > 100000
ORDER BY engagement_rate DESC
LIMIT 10;


-- 14. Year-wise Average Views and Likes

SELECT 
    EXTRACT(YEAR FROM publish_date) AS year,
    ROUND(AVG(view_count)) AS avg_views,
    ROUND(AVG(like_count)) AS avg_likes
FROM youtube_music
GROUP BY year
ORDER BY year DESC;


-- 15. Correlation Between Duration and Popularity

WITH parsed AS (
  SELECT 
    y.*,
    COALESCE(h.hours, 0) * 60 +
    COALESCE(m.mins, 0) +
    COALESCE(s.secs, 0) / 60 AS total_minutes
  FROM youtube_music y
  LEFT JOIN LATERAL (
    SELECT (REGEXP_MATCHES(y.duration, 'PT([0-9]+)H'))[1]::NUMERIC AS hours
  ) h ON TRUE
  LEFT JOIN LATERAL (
    SELECT (REGEXP_MATCHES(y.duration, 'PT(?:[0-9]+H)?([0-9]+)M'))[1]::NUMERIC AS mins
  ) m ON TRUE
  LEFT JOIN LATERAL (
    SELECT (REGEXP_MATCHES(y.duration, 'PT(?:[0-9]+H)?(?:[0-9]+M)?([0-9]+)S'))[1]::NUMERIC AS secs
  ) s ON TRUE
)
SELECT 
    ROUND(CORR(total_minutes, view_count::NUMERIC)::NUMERIC, 2) AS correlation
FROM parsed;


-- 16. Find Top 10 Videos Published in the Most Recent Year

SELECT 
    title,
    channel_name,
    view_count
FROM youtube_music
WHERE EXTRACT(YEAR FROM publish_date) = (
    SELECT MAX(EXTRACT(YEAR FROM publish_date)) FROM youtube_music
)
ORDER BY view_count DESC
LIMIT 10;


-- 17. Find Channels with the Most Uploads

SELECT 
    channel_name,
    COUNT(video_id) AS total_uploads
FROM youtube_music
GROUP BY channel_name
ORDER BY total_uploads DESC
LIMIT 10;


-- 18. Calculate Like-View Ratio Distribution Across All Videos

WITH base AS (
    SELECT
        CASE
            WHEN view_count IS NULL OR view_count = 0 THEN 'No Views'
            WHEN like_count IS NULL OR like_count = 0 THEN 'No Likes'
            ELSE CONCAT(
                ROUND((like_count::numeric / NULLIF(view_count, 0)) * 100, 2), '%'
            )
        END AS engagement_rate_group,
        view_count,
        like_count,
        title
    FROM youtube_music
)
SELECT
    engagement_rate_group,
    COUNT(*) AS num_videos,
    ROUND(AVG(view_count)) AS avg_view_count,
    ROUND(AVG(like_count)) AS avg_like_count,
    MIN(title) AS sample_title
FROM base
GROUP BY engagement_rate_group
ORDER BY
    CASE
        WHEN engagement_rate_group = 'No Views' THEN 9999
        WHEN engagement_rate_group = 'No Likes' THEN 9998
        ELSE CAST(REPLACE(engagement_rate_group, '%', '') AS numeric)
    END DESC;


-- 19. Find Channels That Posted Both “Official” and “Remix” Videos

WITH official_videos AS (
    SELECT 
        channel_name, 
        COUNT(*) AS official_count
    FROM youtube_music
    WHERE title ILIKE '%official%'
    GROUP BY channel_name
),
remix_videos AS (
    SELECT 
        channel_name, 
        COUNT(*) AS remix_count
    FROM youtube_music
    WHERE title ILIKE '%remix%'
    GROUP BY channel_name
)
SELECT 
    o.channel_name,
    o.official_count,
    r.remix_count,
    (o.official_count + r.remix_count) AS total_related_videos
FROM official_videos o
JOIN remix_videos r 
    ON o.channel_name = r.channel_name
ORDER BY total_related_videos DESC, o.channel_name;


-- 20. Identify Videos With “Acoustic” in Title

SELECT 
    title,
    channel_name,
    view_count
FROM youtube_music
WHERE title ILIKE '%acoustic%'
ORDER BY view_count DESC;


-- 21. Find Average Engagement Rate by Year

SELECT 
    EXTRACT(YEAR FROM publish_date) AS year,
    ROUND(AVG((like_count::numeric / NULLIF(view_count,0)) * 100), 2) AS avg_engagement
FROM youtube_music
GROUP BY year
ORDER BY year DESC;


-- 22. Identify “Trailer” or “Teaser” Videos

SELECT 
    title,
    channel_name
FROM youtube_music
WHERE title ILIKE '%trailer%' OR title ILIKE '%teaser%';


-- 23. Find Channels with More Than 10 Videos

SELECT 
    channel_name,
    COUNT(*) AS total_videos
FROM youtube_music
GROUP BY channel_name
HAVING COUNT(*) > 10
ORDER BY total_videos DESC;


-- 24. Find the Most Common Words in Video Titles

SELECT 
    word,
    COUNT(*) AS occurrences
FROM (
    SELECT UNNEST(STRING_TO_ARRAY(LOWER(title), ' ')) AS word
    FROM youtube_music
) AS words
WHERE word NOT IN ('the', 'a', 'an', 'and', '-', '|', 'of', 'in', 'on', 'official', 'video')
GROUP BY word
ORDER BY occurrences DESC
LIMIT 15;


-- 25. Categorize Videos Based on Emotion Keywords

SELECT 
    CASE 
        WHEN description ILIKE '%love%' THEN 'Romantic'
        WHEN description ILIKE '%sad%' THEN 'Sad'
        WHEN description ILIKE '%party%' THEN 'Party'
        WHEN description ILIKE '%motiv%' THEN 'Motivational'
        ELSE 'Other'
    END AS mood_category,
    COUNT(*) AS total_videos
FROM youtube_music
GROUP BY mood_category
ORDER BY total_videos DESC;

-- End of report