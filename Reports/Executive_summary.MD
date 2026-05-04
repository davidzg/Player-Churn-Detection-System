# Executive Summary: Player Churn & Retention Strategy
## The Big Picture
In the hyper-competitive mobile gaming market, losing a player (churn) is more than a lost metric—it’s lost revenue and community vitality. This project moves beyond generic "please come back" emails by using Machine Learning to understand who is leaving and why.

By combining Unsupervised Clustering with Supervised Random Forest modeling, we’ve developed a system that identifies at-risk players with 74% accuracy (Recall) and categorizes them into actionable behavioral archetypes.

## 1. Player Archetypes: Who are we losing?
We identified 6 distinct player types. Two represent 80% of our churn risk:
|Archetype|Risk|The Cause|Strategic Fix|
|---|---|---|---|
|The Bored|🔴 Critical|High skill/wins, but low activity.|New challenges / Hard Mode.|
|The Frustrated|🟠 High|Low win rate; hitting a "wall."|Dynamic Difficulty Adjustment (DDA) or "Pity" rewards.|
|The Fans|🟢 Low|High spenders; deeply invested.|VIP-exclusive content and early access.|
## 2. Why They Leave (Key Drivers)
Analysis shows that winning isn't why players stay—engagement is.
1. Play Intensity is the main predictor. A drop in session frequency is a signal they are churning.
2. Players with a high `Card_score` have a "barrier to exit" and rarely leave.
3. If a player stops moving through the campaigns, they churn regardless of their gem balance.
## 3. Strategic Recommendations
- **Automated Interventions:** Deploy the model to flag "Bored" or "Frustrated" players in real-time.
- **Segmented Rewards:**
    - Give Frustrated players a "rebound gift" after a losing streak to keep them competitive.
    - Give Bored players time-sensitive competitive events to boost their intensity.
- **Early-Game Buffs:** Since `Card_score` and `Progress` are such heavy predictors, players hitting a "dead zone" early on must be avoided. If a player’s card power falls below the average for their level, offer a "Recovery Pack" to keep them competitive.

## 4. Model Performance

<p align="center">
  <img src="../Images/confusion_matrix.png" alt="alt text">
</p>

- 74% Recall: We catch the vast majority of churners.
- 52% Precision: While we may "over-gift" some active players, the cost of a small reward is significantly lower than the cost of losing a player’s Lifetime Value (LTV).