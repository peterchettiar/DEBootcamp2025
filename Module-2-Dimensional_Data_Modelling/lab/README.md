# Week 2 Lab Notes

### Table of contents

- [Data Modelling - Cumulative Dimensions, Struct and Array](#data-modelling-cumulative-dimensions-struct-and-array)
  - [Complex Data Types](#complex-data-types)

## Data Modelling - Cumulative Dimensions, Struct and Array

The main table we wiil be looking at today is `player_seasons`. You would have realised that it is actually a large temporal dataset (i.e. one player has multiple records - each representing a season). Let's take `Aaron McKie` as an example:

<img width="1639" height="700" alt="image" src="https://github.com/user-attachments/assets/eca029ca-6b96-4339-89e1-df9a7500e036" />

Here you can see that the first few columns up to the column `gp` the values of each record are the same, only after that then the season statistics vary for each season. The issue for keeping the table as is is that if you join this table with another one (e.g. `games` or `teams`) that does not have this temporal granularity, the system needs to shuffle data across nodes to align the different granularity of data, and this can be an expensive operation in distributed systems leading to slower performance and loss of compression. This is also known as the `temporal problem`.

> Note: Compression loss happens because repeated values (like `player_name` become less effective at compressing when they are split across many rows instead of grouped.

🧠 **The Solution: One record per player with an array of seasons**
Instead of keeping one row per season, group all of a player's seasons into an array like this:

| player_name | seasons                                                                 |
|-----------|--------------------------------------------------------------------------|
| A       | [{"season":2020, "team":"A", "points":1500}, {"season":2021, "team":"A", "points":1600}] |
| B       | [{"season":2020, "team":"B", "points":1700}]                             |

This way:
- You have one row per player, removing the "temporal" spread.
- The seasonal data is nested in an array (e.g. JSON-like structure)
- Joins with other tables are now faster, more efficient, and preserve compression.
