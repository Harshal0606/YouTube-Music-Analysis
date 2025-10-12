-- SCHEMAS of YouTube

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

SELECT * FROM youtube_music;