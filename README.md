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

### 1 Count the Total Number of Music Videos
```sql
SELECT COUNT(*) AS total_videos
FROM youtube_music;
```
**Objective:** Get a quick overview of total videos analyzed.

---

### 2 Find the Average Views and Likes per Video
```sql
SELECT 
    ROUND(AVG(view_count)) AS avg_views,
    ROUND(AVG(like_count)) AS avg_likes
FROM youtube_music;
```
**Objective:** Measure average engagement across all videos.

---

### 3 Find the Top 10 Most Viewed Videos
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

### 4 Find the Top 10 Most Liked Videos
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

### 5 Calculate Engagement Rate (Likes to Views Ratio)
```sql
SELECT 
    title,
    channel_name,
    ROUND((like_count::numeric / NULLIF(view_count, 0)) * 100, 2) AS engagement_rate
FROM youtube_music
ORDER BY engagement_rate DESC
LIMIT 10;
```
**Objective:** Determine which videos have the strongest fan engagement.

---

### 6 Categorize Videos by Duration
```sql
SELECT 
    CASE
        WHEN SPLIT_PART(duration, 'M', 1)::INT < 2 THEN 'Short (<2 min)'
        WHEN SPLIT_PART(duration, 'M', 1)::INT BETWEEN 2 AND 5 THEN 'Medium (2–5 min)'
        ELSE 'Long (>5 min)'
    END AS duration_category,
    COUNT(*) AS total_videos
FROM youtube_music
GROUP BY duration_category
ORDER BY total_videos DESC;
```
**Objective:** Understand duration-based content distribution.

---

### 7 Find Average Views for Each Duration Category
```sql
SELECT 
    CASE
        WHEN SPLIT_PART(duration, 'M', 1)::INT < 2 THEN 'Short'
        WHEN SPLIT_PART(duration, 'M', 1)::INT BETWEEN 2 AND 5 THEN 'Medium'
        ELSE 'Long'
    END AS duration_type,
    ROUND(AVG(view_count)) AS avg_views
FROM youtube_music
GROUP BY duration_type
ORDER BY avg_views DESC;
```
**Objective:** Check which duration attracts more viewers.

---

### 8 Find Top 5 Channels by Total Views
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

### 9 Find Top 5 Channels by Engagement (Likes/View Ratio)
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

### 10 Find Videos with “Official” in Title
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

### 11 Identify “Live” Performance Videos
```sql
SELECT 
    title,
    channel_name
FROM youtube_music
WHERE title ILIKE '%live%';
```
**Objective:** Understand the frequency of live performance videos.

---

### 12 Find “Remix” or “Mashup” Videos
```sql
SELECT 
    title,
    channel_name
FROM youtube_music
WHERE title ILIKE '%remix%' OR title ILIKE '%mashup%';
```
**Objective:** Identify remix or mashup-type videos.

---

### 13 Detect Outliers — Extremely High Engagement
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

### 14 Year-wise Average Views and Likes
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

### 15 Correlation Between Duration and Popularity
```sql
SELECT 
    ROUND(CORR(SPLIT_PART(duration, 'M', 1)::NUMERIC, view_count::NUMERIC), 2) AS correlation
FROM youtube_music;
```
**Objective:** Determine if video length affects viewership.

---

### 16 Find Top 10 Videos Published in the Most Recent Year
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

### 17 Find Channels with the Most Uploads
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

### 18 Calculate Like-View Ratio Distribution Across All Videos
```sql
SELECT 
    ROUND((like_count::numeric / NULLIF(view_count,0)) * 100, 2) AS engagement_rate,
    COUNT(*) AS num_videos
FROM youtube_music
GROUP BY engagement_rate
ORDER BY engagement_rate DESC;
```
**Objective:** Visualize engagement rate spread across videos.

---

### 19 Find Channels That Posted Both “Official” and “Remix” Videos
```sql
SELECT DISTINCT channel_name
FROM youtube_music
WHERE title ILIKE '%official%'
INTERSECT
SELECT DISTINCT channel_name
FROM youtube_music
WHERE title ILIKE '%remix%';
```
**Objective:** Identify artists experimenting with both types of content.

---

### 20 Identify Videos With “Acoustic” in Title
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

### 21 Find Average Engagement Rate by Year
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

### 22 Identify “Trailer” or “Teaser” Videos
```sql
SELECT 
    title,
    channel_name
FROM youtube_music
WHERE title ILIKE '%trailer%' OR title ILIKE '%teaser%';
```
**Objective:** Detect pre-release or promotional content.

---

### 23️ Find Channels with More Than 10 Videos
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

### 24️ Find the Most Common Words in Video Titles
```sql
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
```
**Objective:** Discover dominant keywords used in music titles.

---

### 25️ Categorize Videos Based on Emotion Keywords
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
