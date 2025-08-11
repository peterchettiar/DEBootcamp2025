# Week 2 Lab Notes

### Table of contents

- [Data Modelling - Cumulative Dimensions, Struct and Array](#data-modelling-cumulative-dimensions-struct-and-array)
  - [Creating an Array of structs](#creating-an-array-of-structs)
  - [Creating a table with a new Schema](#creating-a-table-with-a-new-schema)
  - [Inserting Values into table](#inserting-values-into-table)

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

### Creating an Array of Structs

To create the array of seasons, which is essentially an `ARRAY` of `STRUCTS`, we can create a composite type in PostgreSQL (also called a user-defined type) - it allows you to define a custom data structure with multiple fields. You can think of it as building an object (instance of a class) in Python. You can define the `season_stats` STRUCT, which is its own data type, in SQL as:
```sql
CREATE TYPE season_stats AS (
  season INTEGER,
  age TEXT,
  gp INTEGER,
  pts REAL,
  reb REAL,
  ast REAL
);
```

So the equivalent of this in Python OOP would be a class with attributes for each field as follows:
```python
Class SeasonStats:
    def __init__(self, season: int, age: str, gp: int, pts: float, reb: float, ast: float):
        self.season = season
        self.age = age
        self.gp = gp
        self.pts = pts
        self.reb = reb
        self.ast = ast        
```

In the event that you made a mistake and would like to change/make amendments to the `TYPE` you have to follow these steps:
1. We need to make sure that the composite type is not used in any table, it it is we need to drop it first.
```sql
-- If we want to make changes to composite type, we need to first alter table using the type
ALTER TABLE players DROP COLUMN season_stats;
```
2. Now that we know that the composite type is not being used in any table, we can drop it safely altogether by running the query `DROP TYPE season_stats;`
3. Since we dropped the old type, we need to re-create with the necessary fields with the changes incorporated
```sql
-- Then create the new type again
CREATE TYPE season_stats AS (
  season INTEGER,
  age TEXT,
  games_played INTEGER,
  points NUMERIC,
  rebounds NUMERIC,
  assits NUMERIC
);
```
4. Lastly, if need be, we can add the column back to the table as such:
```sql
-- Lastly, re-add the column
ALTER TABLE players ADD COLUMN season_stats season_stats[];
```

### Creating a table with a new schema

The next step then would be to create a table with the schema that we had envisioned (i.e. one record per player with season statistics grouped in an array of structs).
The SQL query for creating an empty table with our desired schema is as follows:
```sql
CREATE TABLE players (
  player_name TEXT,
  height TEXT,
  college TEXT,
  country TEXT,
  draft_year TEXT,
  draft_round TEXT,
  draft_number TEXT,
  season_stats season_stats[], -- array of composite structs
  current_season INTEGER,
  PRIMARY KEY (player_name, current_season)
);
```

> [!TIP]
> It is worth pointing out that in the above syntax, it is not mandatory to provide a `PRIMARY_KEY` statement when creating a table but it is particularly useful as a constraint:
> 1. Uniquely identifies each row in table
> 2. Cannot be `NULL` (Postgres enforces `NOT NULL` automatically for primary key columns)
> 3. Is indexed automatically for faster lookups

### Inserting Values into table

Now, that we have created our target table (for a lack of a better term) with our desired schema, we can proceed to populate it with the values from `player_seasons`. As mentioned, our objective is to accumulate each player's statistics on a per season basis. We will take a [Cumulative Table Design](https://github.com/peterchettiar/DEBootcamp2025/tree/main/Module-2-Dimensional_Data_Modelling#cumulative-table-design) approach when inserting these values into the new table. Based on the cumulative design example below, we can see there are two major components; `yesterday` and `today`.

<img width="640" height="266" alt="image" src="https://github.com/user-attachments/assets/a8983a1e-4ecf-427b-b254-60cd9b79ab53" />

> [!IMPORTANT]
> **The goal**:
> Merge today’s new stats into yesterday’s cumulative record so that season_stats becomes a growing array of season data per player.

1.  We start off with the `yesterday` table which is essentially our cumulative table - our first step would be to instantiate the table as follows:
```sql
WITH yesterday AS (
  SELECT * FROM players
  WHERE current_season = 1995
),
```
> Note: We select `1995` as the starting year of the accumulation because the minimum year in the `player_seasons` table is `1996`.

2. Next, we would also create a CTE for `today` - these are the temporal records that we want to extract from the raw table.
```sql
  today AS (
  SELECT * FROM player_seasons
  WHERE season = 1996
  )
```

3. Now that we have the CTEs for `yesterday` and `today`, we can proceed with the creation of the seed query that would be eventually used for the cumulation. Its the seed query because when we run the query for `yesterday` it should return us null.
```sql
SELECT 
  COALESCE(t.player_name, y.player_name) as player_name,
  COALESCE(t.height, y.height) as height,
  COALESCE(t.college, y.college) as college,
  COALESCE(t.country, y.country) as country,
  COALESCE(t.draft_year, y.draft_year) as draft_year,
  COALESCE(t.draft_round, y.draft_round) as draft_round,
  COALESCE(t.draft_number, y.draft_number) as draft_number,
  CASE 
    WHEN y.season_stats IS NULL THEN ARRAY[ROW(t.season, t.age, t.gp, t.pts, t.reb, t.ast)::season_stats]
    WHEN t.season IS NOT NULL THEN y.season_stats || ARRAY[ROW(t.season, t.age, t.gp, t.pts, t.reb, t.ast)::season_stats] 
  ELSE y.season_stats 
  END AS season_stats,
  COALESCE(t.season, y.current_season + 1) AS current_season
FROM yesterday y FULL OUTER JOIN today t ON y.player_name = t.player_name;
```
When we perform a `FULL OUTER JOIN` we are merging both tables, but since they are have the same fields, we can use the `COALESCE` function to return the first non-null value of same field name and collapse the view into a unified one instead of merging them side-by-side. The way the structure of the query is, you would have noticed that its similar to our schema of the `players` table that we had created. Hence, it should be apparent that we would be inserting into the `players` table records from the seed query. The `CASE` statement considers 3 scenarios for `season_stats` fields:
1. If the player is new (no yesterday record) → start a new array with this season’s stats.
2. If the player already has stats → append this season’s row to the array (|| concatenates arrays in Postgres).
3. If no new season data → keep the old array.
4. `COALESCE(t.season, y.current_season + 1) AS current_season` - For existing players, we increment the year. As for new players, we take the `t.season` directly.

This is exactly the **cumulative design principle**:
> Append new data to existing historical data without losing the past.

4. Last step would be to add the `INSERT INTO` statement to write in the output of the subsequent query into the `players` table. In other words, we are now inserting the merged result back into the `players` table to refresh the cumulative dataset.
5. Last but not least repeat the steps for up to season 2002 for course purposes, else you can run a loop to load the cumulative data from the first season to the last season of the raw dataset (i.e. 1996 to 2022).

