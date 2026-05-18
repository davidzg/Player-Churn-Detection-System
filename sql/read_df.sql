With player_base as (
  SELECT
    ID,
    AvatarLevel,
    Gold,
    Gems,
    Purchases,
    VipLevel,
    TotalPlay,
    TotalWon,
    TotalLost,
    DATE(FirstInstallDate) AS FirstInstallDate,
    DATE(ConfigFetchTimeStamp) AS LastSeenDate
  FROM `f2p-game-balance.game_data_analysis.general`
  WHERE 
    Gold>=0 
    AND Gems >= 0 
    AND TotalPlay >= 0
    AND TotalWon >= 0
    AND TotalLost >= 0
    AND AvatarXp >= 0
    AND AvatarLevel BETWEEN 20 AND 220 --Filtering out users still playing the FTUE, and the invalid users with very high AvatarLevel
    AND DATE(ConfigFetchTimeStamp) >= '2024-01-14' --Taking only the users seen in the last 90 days of the snapshot (2024-04-13)
),
-- CARDS TABLE
pivoted_cards_sum AS(
  SELECT 
    *
  FROM(
    SELECT
      ID,
      IFNULL(Level,0) as Level,
      Rarity
    FROM
      `f2p-game-balance.game_data_analysis.cards`
    WHERE
      Type != 0
  )
  PIVOT(
    SUM(Level) 
    FOR Rarity in ('COMMON','UNCOMMON','RARE','EPIC'))
),

card_scores AS (
  SELECT 
    ID,
    Card_score 
  FROM (
    SELECT 
        ID,
        IFNULL(SAFE_DIVIDE(COMMON,29*30),0) + 
        IFNULL(SAFE_DIVIDE(UNCOMMON,86*60),0) + 
        IFNULL(SAFE_DIVIDE(RARE,89*100),0) + 
        IFNULL(SAFE_DIVIDE(EPIC,87*150),0) AS Card_score
    FROM pivoted_cards_sum)
),
-- PROGRESS TABLE
campaign_progression AS(
  SELECT
    ID,
    SUM(IFNULL(stars, 0)) AS TotalStars,
    SUM(IFNULL(SAFE_DIVIDE(stars,max_stars),0))/
    -- count the number of campaigns
      (SELECT COUNT(DISTINCT CONCAT(name, '_', CAST(difficulty AS STRING))) FROM `f2p-game-balance.game_data_analysis.campaigns`) AS Overall_progress
  FROM `f2p-game-balance.game_data_analysis.campaigns` 
  GROUP BY(ID)
)

-- FINAL TABLE
SELECT 
    b.ID,
    b.AvatarLevel,
    b.Gold,
    b.Gems,
    b.Purchases,
    b.VipLevel,
    b.TotalPlay,
    b.TotalWon,
    b.TotalLost,
    b.FirstInstallDate,
    b.LastSeenDate,
    c.Card_score,
    p.TotalStars,
    p.Overall_progress
FROM player_base b
LEFT JOIN card_scores c ON b.ID = c.ID
LEFT JOIN campaign_progression p ON b.ID = p.ID;
