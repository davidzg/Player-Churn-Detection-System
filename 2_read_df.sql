-- ==============================================================================
-- Main Script: Player Progression and Activity Data Extraction
-- Description: Aggregates player base stats, card collection scores, and 
--              campaign progression into a single consolidated view for analysis.
-- ==============================================================================

WITH player_base AS (
  -- Extract fundamental player statistics and filter out invalid/inactive users
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
    -- Data validation: Exclude records with negative values in cumulative fields
    Gold >= 0 
    AND Gems >= 0 
    AND TotalPlay >= 0
    AND TotalWon >= 0
    AND TotalLost >= 0
    AND AvatarXp >= 0
    -- Filter out users still in the First Time User Experience (FTUE) (<20) 
    -- and outliers/cheaters with invalidly high levels (>220)
    AND AvatarLevel BETWEEN 20 AND 220 
    -- Keep only Active Users: Users seen within the last 90 days of the snapshot date (2024-04-13)
    AND ConfigFetchTimeStamp >= '2024-01-14 00:00:00' 
),

pivoted_cards_sum AS (
  -- Transpose the cards table to calculate the total sum of card levels per rarity 
  SELECT 
    *
  FROM (
    SELECT
      ID,
      IFNULL(Level, 0) AS Level, -- Default missing levels to 0 to avoid NULL math issues
      Rarity
    FROM
      `f2p-game-balance.game_data_analysis.cards`
    WHERE
      Type != 0 -- Exclude placeholder, empty, or invalid card types
  )
  PIVOT(
    -- Create distinct columns for each rarity containing the sum of player levels
    SUM(Level) 
    FOR Rarity IN ('COMMON', 'UNCOMMON', 'RARE', 'EPIC')
  )
),

card_scores AS (
  -- Calculate a normalized "Card Score" representing overall collection progress
  SELECT 
    ID,
    Card_score 
  FROM (
    SELECT 
        ID,
        -- Normalize the sum of card levels by the maximum possible total levels for each rarity
        -- Denominator logic: (Number of Cards of that Rarity) * (Max Level for that Rarity)
        IFNULL(SAFE_DIVIDE(COMMON, 29 * 30), 0) +   -- 29 Common cards, max level 30
        IFNULL(SAFE_DIVIDE(UNCOMMON, 86 * 60), 0) + -- 86 Uncommon cards, max level 60
        IFNULL(SAFE_DIVIDE(RARE, 89 * 100), 0) +    -- 89 Rare cards, max level 100
        IFNULL(SAFE_DIVIDE(EPIC, 87 * 150), 0) AS Card_score -- 87 Epic cards, max level 150
    FROM pivoted_cards_sum
  )
),

campaign_progression AS (
  -- Calculate campaign engagement metrics
  SELECT
    ID,
    -- Total absolute stars earned by the player across all campaigns
    SUM(IFNULL(stars, 0)) AS TotalStars,
    
    -- Calculate an overall progression ratio
    -- Calculates the sum of progress per campaign, then divides by the total number of distinct campaigns
    SUM(IFNULL(SAFE_DIVIDE(stars, max_stars), 0)) /
      (SELECT COUNT(DISTINCT CONCAT(name, '_', CAST(difficulty AS STRING))) 
       FROM `f2p-game-balance.game_data_analysis.campaigns`) AS Overall_progress
  FROM `f2p-game-balance.game_data_analysis.campaigns` 
  GROUP BY ID
)

-- ==============================================================================
-- Combine all CTEs into the final analytical dataset
-- ==============================================================================
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
-- Use LEFT JOINs to ensure baseline players are kept even if they haven't unlocked cards or played campaigns yet.
LEFT JOIN card_scores c ON b.ID = c.ID
LEFT JOIN campaign_progression p ON b.ID = p.ID;