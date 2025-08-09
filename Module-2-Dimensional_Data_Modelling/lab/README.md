# Week 2 Lab Notes

### Table of contents

- [Data Modelling - Cumulative Dimensions, Struct and Array](#data-modelling-cumulative-dimensions-struct-and-array)
  - [Creating an Array of structs](#creating-an-array-of-structs)
  - [Creating a table with new Schema](#creating-a-table-with-a-new-schema)

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


