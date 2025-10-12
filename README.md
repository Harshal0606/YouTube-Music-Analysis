# YouTube Music Data Analysis using SQL

![](https://github.com/Harshal0606/YouTube-Music-Analysis/blob/main/YouTube_Logo.png)

## Overview
This project performs an in-depth analysis of YouTube music video data using SQL.
The goal is to derive insights into content trends, engagement metrics, and audience preferences across music videos.
The dataset includes attributes such as video duration, likes, views, and other metadata extracted from the YouTube API.

## Objectives

- Analyze video popularity based on views and likes.
- Identify top-performing artists and track types.
- Explore trends in video duration and engagement.
- Detect outliers. i.e. extremely short or long videos.
- Understand the correlation between likes and views.
- Identify keyword-based video categories (e.g., “Official”, “Live”, “Remix”).
- Provide actionable insights for creators and record labels.

## Dataset

Source: Extracted from YouTube Data API v3.
File used: youtube_music_final_utf8.csv

## Schema

```sql
DROP TABLE IF EXISTS youtube_music;
CREATE TABLE youtube_music (
    video_id        VARCHAR(20) PRIMARY KEY,
    title           TEXT,
    channel_name    TEXT,
    publish_date    DATE,
    duration        VARCHAR(15),
    like_count      BIGINT,
    view_count      BIGINT,
    category        TEXT,
    description     TEXT
);
```

## Business Problems and Solutions

### 1. Count the Total Number of Music Videos
```sql
SELECT COUNT(*) AS total_videos
FROM youtube_music;
```
**Objective:** Get a quick overview of total videos analyzed.

---

### 2. Find the Average Views and Likes per Video
```sql
SELECT 
    ROUND(AVG(view_count)) AS avg_views,
    ROUND(AVG(like_count)) AS avg_likes
FROM youtube_music;
```
**Objective:** Measure average engagement across all videos.

---

### 3. Find the Top 10 Most Viewed Videos
```sql
SELECT 
    title,
    channel_name,
    view_count
FROM youtube_music
ORDER BY view_count DESC
LIMIT 10;
```
**Objective:** Identify the most-watched videos.

---

### 4. Find the Top 10 Most Liked Videos
```sql
SELECT 
    title,
    channel_name,
    like_count
FROM youtube_music
ORDER BY like_count DESC
LIMIT 10;
```
**Objective:** Identify the most appreciated videos.

---

### 5. Calculate Engagement Rate (Likes to Views Ratio)
```sql
SELECT 
    title,
    channel_name,
    ROUND((like_count::numeric / view_count::numeric) * 100, 2) AS engagement_rate
FROM youtube_music
WHERE like_count IS NOT NULL 
  AND view_count IS NOT NULL 
  AND view_count > 0
ORDER BY engagement_rate DESC
LIMIT 10;
```
**Objective:** Determine which videos have the strongest fan engagement.

---

### 6. Categorize Videos by Duration and its Average Views
```sql
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
```
**Objective:** Understand duration-based content distribution.

---

### 7. Analyze VEVO Videos and Their Performance
```sql
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
ORDER BY total_videos;
```
**Objective:** VEVO and Non-VEVO metrics

---

### 8. Find Top 5 Channels by Total Views
```sql
SELECT 
    channel_name,
    SUM(view_count) AS total_views
FROM youtube_music
GROUP BY channel_name
ORDER BY total_views DESC
LIMIT 5;
```
**Objective:** Identify the most-viewed channels.

---

### 9. Find Top 5 Channels by Engagement (Likes/View Ratio)
```sql
SELECT 
    channel_name,
    ROUND(SUM(like_count)::numeric / SUM(view_count)::numeric * 100, 2) AS engagement_rate
FROM youtube_music
GROUP BY channel_name
HAVING SUM(view_count) > 100000
ORDER BY engagement_rate DESC
LIMIT 5;
```
**Objective:** Identify channels with the most loyal audiences.

---

### 10. Find Videos with “Official” in Title
```sql
SELECT 
    title,
    channel_name,
    view_count
FROM youtube_music
WHERE title ILIKE '%official%'
ORDER BY view_count DESC;
```
**Objective:** List official music videos, typically high-performing uploads.

---

### 11. Identify “Live” Performance Videos
```sql
SELECT 
    title,
    channel_name
FROM youtube_music
WHERE title ILIKE '%live%';
```
**Objective:** Understand the frequency of live performance videos.

---

### 12. Find “Remix” or “Mashup” Videos
```sql
SELECT 
    title,
    channel_name
FROM youtube_music
WHERE title ILIKE '%remix%' OR title ILIKE '%mashup%';
```
**Objective:** Identify remix or mashup-type videos.

---

### 13. Detect Outliers — Extremely High Engagement
```sql
SELECT 
    title,
    like_count,
    view_count,
    ROUND((like_count::numeric / NULLIF(view_count, 0)) * 100, 2) AS engagement_rate
FROM youtube_music
WHERE view_count > 100000
ORDER BY engagement_rate DESC
LIMIT 10;
```
**Objective:** Highlight videos performing exceptionally well relative to views.

---

### 14. Year-wise Average Views and Likes
```sql
SELECT 
    EXTRACT(YEAR FROM publish_date) AS year,
    ROUND(AVG(view_count)) AS avg_views,
    ROUND(AVG(like_count)) AS avg_likes
FROM youtube_music
GROUP BY year
ORDER BY year DESC;
```
**Objective:** Analyze performance trends over years.

---

### 15. Correlation Between Duration and Popularity
```sql
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
    ROUND(CORR(total_minutes, view_count::NUMERIC)::NUMERIC, 2) AS correlation,
    ROUND(AVG(total_minutes), 2) AS avg_duration_min,
    ROUND(AVG(view_count), 0) AS avg_view_count,
    COUNT(*) AS total_videos
FROM parsed;
```
**Objective:** Determine if video length affects viewership.

---

### 16. Find Top 10 Videos Published in the Most Recent Year
```sql
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
```
**Objective:** Identify top videos released in the latest year.

---

### 17. Find Channels with the Most Uploads
```sql
SELECT 
    channel_name,
    COUNT(video_id) AS total_uploads
FROM youtube_music
GROUP BY channel_name
ORDER BY total_uploads DESC
LIMIT 10;
```
**Objective:** Discover the most consistent uploaders.

---

### 18. Calculate Like-View Ratio Distribution Across All Videos
```sql
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
    -- numeric ordering for percentage groups, custom order for labels
    CASE
        WHEN engagement_rate_group = 'No Views' THEN 9999
        WHEN engagement_rate_group = 'No Likes' THEN 9998
        ELSE CAST(REPLACE(engagement_rate_group, '%', '') AS numeric)
    END DESC;
```
**Objective:** Visualize engagement rate spread across videos.

---

### 19. Find Channels That Posted Both “Official” and “Remix” Videos
```sql
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
```
**Objective:** Identify artists experimenting with both types of content.

---

### 20. Identify Videos With “Acoustic” in Title
```sql
SELECT 
    title,
    channel_name,
    view_count
FROM youtube_music
WHERE title ILIKE '%acoustic%'
ORDER BY view_count DESC;
```
**Objective:** Explore the performance of acoustic versions.

---

### 21. Find Average Engagement Rate by Year
```sql
SELECT 
    EXTRACT(YEAR FROM publish_date) AS year,
    ROUND(AVG((like_count::numeric / NULLIF(view_count,0)) * 100), 2) AS avg_engagement
FROM youtube_music
GROUP BY year
ORDER BY year DESC;
```
**Objective:** Observe how audience interaction changed yearly.

---

### 22. Identify “Trailer” or “Teaser” Videos
```sql
SELECT 
    title,
    channel_name
FROM youtube_music
WHERE title ILIKE '%trailer%' OR title ILIKE '%teaser%';
```
**Objective:** Detect pre-release or promotional content.

---

### 23. Find Channels with More Than 10 Videos
```sql
SELECT 
    channel_name,
    COUNT(*) AS total_videos
FROM youtube_music
GROUP BY channel_name
HAVING COUNT(*) > 10
ORDER BY total_videos DESC;
```
**Objective:** Identify high-volume content producers.

---

### 24. Find the Most Common Words in Video Titles
```sql
SELECT 
    word,
    COUNT(*) AS occurrences
FROM (
    SELECT UNNEST(STRING_TO_ARRAY(LOWER(title), ' ')) AS word
    FROM youtube_music
) AS words
WHERE word NOT IN ('the', 'a', 'an', 'and', '-', '|', 'of', 'in','', 'on', '(official', 'video)')
GROUP BY word
ORDER BY occurrences DESC
LIMIT 15;
```
**Objective:** Discover dominant keywords used in music titles.

---

### 25. Categorize Videos Based on Emotion Keywords
```sql
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
```
**Objective:** Classify music videos into emotional or thematic categories.

## Findings and Conclusion

- **Engagement Sweet Spot:** Videos between 2–5 minutes yield the best balance of watch-time and engagement.  
- **Channel Dominance:** A few popular channels contribute to most total views and likes.  
- **Content Strategy:** Official and Acoustic versions outperform remixes and teasers.  
- **Yearly Growth:** View counts and engagement rates rise steadily year over year.  
- **Keyword Trends:** Common title words (“official”, “remix”, “love”) indicate popular themes in music content.  
- **Outlier Insights:** A handful of short videos exhibit extremely high engagement — perfect for algorithmic virality.  
- **Emotional Mapping:** “Love” and “Party” themes dominate, showing audience preference for upbeat or emotional music. 

This analysis provides a comprehensive view of YouTube's music content and can help inform content strategy and decision-making.

## Conclusion
This SQL-driven analysis delivers comprehensive insights into YouTube Music trends, creator behavior, and audience engagement.  
It serves as a foundation for:
- Predictive modeling of video success,  
- Genre-based performance analysis, and  
- Marketing optimization for record labels and content strategists.  
