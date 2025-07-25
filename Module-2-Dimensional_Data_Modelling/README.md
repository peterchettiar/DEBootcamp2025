# Week 2 Notes

### Table of contents

- [Dimensional Data Modelling Complex Data Type and Cumulation](#dimensional-data-modelling-complex-data-type-and-cumulation)
  - [Complex Data Types](#complex-data-types)
  - [Types of Dimensions](#types-of-dimensions)
  - [Database Types](#database-types)
  - [Normalisation](#normalisation)
  - [Cumulative Table Design](#cumulative-table-design)
  - [The compactness vs usability tradeoff](#the-compactness-vs-usability-tradeoff)
  - [Struct vs Array vs Map](#struct-vs-array-vs-map)
  - [Temporal Cardinality Explosion](#temporal-cardinality-explosion)

## Dimensional Data Modelling Complex Data Type and Cumulation

A Data Engineer's primary role is to design, build, and maintain the infrastructure and systems that allow organisations to collect, store, process and analyse data. They ensure that the data is readily available and in a usable format for data scientists, analysts, and other stakeholders to derive valuable insights and make informed decisions.

Essentially, the final product is a data warehouse / lakehouse that is built and maintained by the data engieers for the perusal of the business. This should not be only functional but rather performant as well. This means that that the data should not be just available at the request of its users but also fast when users query the database.

Now, to optimise the database, the tables within need to be built in a certain structure, and hence the term data modelling was coined. It is simply techniques in which data is structured for querying and analysis, particularly for data warehouses and business intelligence systems. It organises data into `facts` and `dimensions` tables, making it easier to understand and retrieve information. This design is optimised for data retrieval and provide a clear, concise representation of data for business users. The resulting structure is often visualised as a `star` or `snowflake` schema.

> Note: The description above is in relation to `OLAP` systems. And its importance to distinguish the difference between a `data model` and `database design`, the former is like the blueprint to the latter (i.e. `data model` is the logical representation while `database design` is the implementation).

### Complex Data Types

Besides the schema design, we can take a step further optimising each table (both `fact` and `dimension`) through the usage of different data types. Complex data types such as `STRUCT` and `ARRAY` can be used to optimised fields in tables for querying. 

- `STRUCT` : Composite data type that groups together multiple fields of different data types (i.e. to model nested records, conceptually similar to `dict` in python)
- `ARRAY` : An ordered collection of elements of the same data type. It is similar to a list or an array in most programming languages
- You can also combine both complex data types to represent complex hierarchical data. An example of an `ARRAY` containing `STRUCT` objects would be as follows:
```json
{
  "order_items": [
    { "product_id": "P123", "quantity": 2, "price": 10.5 },
    { "product_id": "P456", "quantity": 1, "price": 20.0 }
  ]
}
```

#### 📌 Benefits of Using an Array of STRUCTs
| Benefit               | Why It Matters                                                                 |
|------------------------|--------------------------------------------------------------------------------|
| **Natural hierarchy**  | Reflects real-world nested relationships (e.g., orders with multiple items)   |
| **Cohesive data**      | Keeps multi-field repeating data together, avoiding index mismatches          |
| **Easier denormalization** | Simplifies modeling by avoiding joins while retaining structure         |
| **Query flexibility**  | Easily flatten nested data using `UNNEST` or `explode` for analysis           |
| **Interoperability**   | Maps well to semi-structured formats like JSON, Avro, and Parquet             |
| **Performance**        | Modern engines optimize nested queries and storage for efficiency             |

### Types of Dimensions

In the realm of data, a `dimension` is defined as a descriptive data structure that contains attributes (fields) which provide context to measurable data (facts), enabling users to filter, group, slice, and analyze facts in meaningful ways. It can be seen as an aspect of space of an area (e.g. in a 3D space x, y and z are the dimensions). These dimensions that make the `dimension` table can change over time (i.e. become time dependent). This is because more often than not, in the case of a `product_dim` table for example, attributes of a product may change. Perhaps the product description may have changed, or the product ID. Then the question would be as to how to handle such changes.

This is where the concept of slowly changing dimensions (SCDs) addresses this problem. It is a concept of how attributes are updated overtime without simply overwriting and track historical changes thereby allowing for analysis of how dimensions evolve. SCDs provide strategies for managing these changes and the following are the common types of SCDs:

#### 📌 Fixed (Static) Dimensions
- Also called **Type 0 Slowly Changing Dimensions**
- The attributes never change once inserted
- Any change is ignored (used for fixed entities like country codes, currency symbols, etc.)
- `USE CASE` : static reference data - e.g. currency (USD, EUR)
- **Example:**

| Customer ID | Name  | Country |
|-------------|-------|---------|
| C001        | Alice | Japan   |

If Alice moves to Singapore, the country remains **Japan** in the dimension.

#### 📌 Type 1 SCD - Overwrite
- When an attribute changes, overwrite the old value
- No history is kept
- `USE CASE` : Fixing incorrect data (e.g. correcting a misspelled name)
- **Example:**

| Customer ID | Name  | Region |
|-------------|-------|--------|
| C001        | Alice | East   |

**After Update:**

| Customer ID | Name  | Region |
|-------------|-------|--------|
| C001        | Alice | West   |

#### 📌 Type 2 SCD - Add New Row
- Creates a new row for each change
- Keep full history with effective dates or versioning
- Fact tables link to the correct historical version
- `USE CASE` : Track customer moving regions, product price changes, etc.
- **Example:**

| Customer ID | Name  | Region | Version | Effective Date |
|-------------|-------|--------|---------|----------------|
| C001        | Alice | East   | 1       | 2023-01-01     |
| C001        | Alice | West   | 2       | 2024-05-01     |

#### 📌 Type 3 SCD - Add New Column
- Keep a limited history by adding new columns
- Only tracks current and previous values
- `USE CASES` : Useful when you only need the last known change (e.g. old vs new region)
- **Example:**

| Customer ID | Name  | Current Region | Previous Region |
|-------------|-------|----------------|-----------------|
| C001        | Alice | West           | East            |

#### Other Less Common Types
- Type 4: Seperate history table (current in main dimension, old values in a seperate table).
- Type 6 (Hybrid): Combines Types 1, 2, and 3 to provide both current values and history in one table.

### Database Types

When designing data models, it's important to consider the data consumers before choosing one of the following database systems:

**🔹 1. Online Transaction Processing (OLTP)**

**Purpose**: Handles day-to-day **transactional operations** like inserts, updates, and deletes.

**Key Characteristics:**
- Highly normalized (often 3NF) -> optimised for low-latency, low-volume queries
- Supports thousands of short transactions per second
- Fast reads and writes
- Real-time data consistency
- Focus: CRUD operations (Create, Read, Update, Delete)

**Examples:**
- Banking systems (money transfers)
- E-commerce platforms (placing orders)
- Inventory management systems

**🔹 OLAP – Online Analytical Processing**

**Purpose**: Handles **complex analytical queries** on historical or aggregated data for decision-making.

**Key Characteristics:**
- Denormalized structure (Star or Snowflake schema), hence minimises `JOINS`
- Optimized for large read-intensive workloads
- Supports multi-dimensional analysis (slice, dice, drill down)
- Focus: Aggregation, Reporting, Data Exploration

**Examples:**
- Business Intelligence dashboards
- Sales forecasting reports
- Customer segmentation analysis

**🧠 OLTP vs OLAP – Comparison Table**

| Feature                  | OLTP                                      | OLAP                                      |
|--------------------------|--------------------------------------------|--------------------------------------------|
| **Purpose**              | Process real-time transactions             | Perform complex analytical queries         |
| **Data Volume**          | Small per transaction                      | Large, historical datasets                 |
| **Operations**           | Insert, Update, Delete                     | Read-heavy: SELECT with aggregates         |
| **Normalization**        | Highly normalized (3NF)                    | Denormalized (Star/Snowflake schema)       |
| **Users**                | Front-line staff, end-users                | Analysts, Executives, Data Scientists      |
| **Query Types**          | Simple and fast                            | Complex, long-running                      |
| **Example Systems**      | POS systems, Banking apps, ERPs            | Data warehouses, BI platforms              |
| **Latency**              | Millisecond response time                  | Seconds to minutes for large queries       |
| **Data Freshness**       | Real-time                                  | Periodically refreshed (batch or stream)   |
| **Concurrency**          | High (many users at once)                  | Medium to low                              |

**🔹 Master Data**

- Table that sits in between the `OLTP` and `OLAP` layers
- Provides clean, complete and deduplicated data that supports both single-record access (`OLTP`) and analystical operations (`OLAP`)
- Often used as a source of truth and preferred over querying snapshots, which can be unreliable.
- Important to have this layer to prevent mismatches (e.g. Modelling an analytical `OLAP` system as a transactional `OLTP` system - Users have to perform multiple `JOIN` which slows the query performance)
- A visual of the flow of systems is as follows:
![image](https://github.com/user-attachments/assets/3e97bc15-3740-4f1b-b2b7-6be19ad92789)
- The `Master Data` table is usually one large table which is a combined version of all the normalised transactional tables from the `OLTP` systems
- After which it can be split into `OLAP` cubes where users of the data can perform their aggregations optimally to generate their metrics

### Normalisation

In the comparison table above, we had mentioned that `OLTP` and `OLAP` differed in terms of normailisation. `OLTP` is highly normalised while `OLAP` is denormalised. But what is it exactly?

`Normalisation` is the process of structuring a relational database in a way that reduces data redundancy and improve data integrity. It involves organising data into multiple related tables and applying rules (called normal forms) to ensure each piece of data is stored only once and in the right place.

>Note: The concept of normalisation applies to transactional systems (i.e. `OLTP`)

This is done so in steps called `normal forms`, each adding more structure:

**🔹 1NF – First Normal Form (Atomicity)**

**Rule**: Eliminate repeating groups. Ensure each column contains **atomic (indivisible)** values.

**❌ Unnormalized Table:**

| OrderID | CustomerName | Products                 | Quantities |
|---------|--------------|--------------------------|------------|
| 1001    | Alice         | TV, Microwave             | 1, 2       |
| 1002    | Bob           | Laptop                    | 1          |

**✅ 1NF Table:**

| OrderID | CustomerName | Product    | Quantity |
|---------|--------------|------------|----------|
| 1001    | Alice         | TV         | 1        |
| 1001    | Alice         | Microwave  | 2        |
| 1002    | Bob           | Laptop     | 1        |

➡ Now, each field contains only **one value per cell** — atomic and organized.

**🔹 2NF – Second Normal Form (No Partial Dependencies)**

**Rule**: Be in 1NF **and** eliminate partial dependencies (i.e., non-key fields must depend on the **whole** primary key).

Assume our current primary key is `(OrderID, Product)`.

**❌ 1NF Table with Partial Dependency:**

| OrderID | Product    | CustomerName | Quantity |
|---------|------------|--------------|----------|
| 1001    | TV         | Alice         | 1        |
| 1001    | Microwave  | Alice         | 2        |
| 1002    | Laptop     | Bob           | 1        |

➡ `CustomerName` depends only on `OrderID`, not on both `OrderID` and `Product`.

**✅ 2NF Tables:**

**Orders Table:**

| OrderID | CustomerName |
|---------|--------------|
| 1001    | Alice         |
| 1002    | Bob           |

**OrderDetails Table:**

| OrderID | Product    | Quantity |
|---------|------------|----------|
| 1001    | TV         | 1        |
| 1001    | Microwave  | 2        |
| 1002    | Laptop     | 1        |

➡ `CustomerName` now lives in a table where it depends **entirely** on the primary key.

**🔹 3NF – Third Normal Form (No Transitive Dependencies)**

**Rule**: Be in 2NF **and** eliminate transitive dependencies (i.e., non-key fields must depend only on the primary key, not on other non-key attributes).

**❌ 2NF Table with Transitive Dependency:**

| CustomerID | CustomerName | ZipCode | City     |
|------------|---------------|---------|----------|
| C001       | Alice          | 10001   | New York |
| C002       | Bob            | 90001   | LA       |

➡ `City` depends on `ZipCode`, which is not a key — this is a transitive dependency.

**✅ 3NF Tables:**

**Customer Table:**

| CustomerID | CustomerName | ZipCode |
|------------|---------------|---------|
| C001       | Alice          | 10001   |
| C002       | Bob            | 90001   |

**ZipCode Table:**

| ZipCode | City     |
|---------|----------|
| 10001   | New York |
| 90001   | LA       |

➡ Now, **each non-key field** depends only on the **primary key** of its table.

### Cumulative Table Design

A `cumulative table design` refers to a data modelling technique where the table is built to store running totals or aggregated snapshots over time, rather than just raw transactional data.

The purpose - to pre-aggregate and persist cumulative values like daily/weekly/monthly totals, so that analytical queries are faster and more efficient. It's often used in data warehouses and BI systems for tracking metrics over time. The benefit of doing so is to avoid re-calculating total on the fly, thereby improving query performance of arbitrarily large time frames.

Lets take the following diagram of the high-level pipeline design for this pattern as an example:
![image](https://github.com/user-attachments/assets/1bf4fed5-f091-4d67-a98b-8e69978759e9)

1. Preparation of Daily Status Tables

   a. Procure the data for today from your source of truth (i.e. Master Data)

   b. Daily transaction data is grouped using `GROUPBY` clause and daily metrics are calculated.
   
   c. We initially build our daily metrics table that is at the grain of whatever our entity is. This data is derived from whatever event sources we have upstream.
   
3. Combining Cumulative Table and Daily Data
 
   a. After we have our daily metrics, we `FULL OUTER JOIN` yesterday's cumulative table with today's daily data and build our metric arrays for each user.
   
   b. We do so also because there maybe data that was in today but not yesterday, or vice-versa.
   
   c. This allows us to bring the new history in without having to scan all of it **(a big performance boost)**

4. Lastly, we write it to last table - the cumulative table is updated or written to a new table

>[!TIP]
> When we perform a `FULL OUTER JOIN` we are essentially combining all rows from both tables (daily metrics table as well as the cumulative metrics table), matching on keys. And these rows from each table are joined horizontally (i.e. side-by-side), not vertically. Hence, if their column names in both tables are identical (and it should!), then the total number of columns should be double after this step. But if you `COALESCE` (function that returns the first non-null value in a list) the fields of the same name from both tables, you can merge tables with a unified view with collapsing fields (i.e. you only have one set of columns with overlapping rows combined).

**✅ Strengths**

- Historical analysis without shuffle - By cumulatively defining metrics, you can avoid using expensive operations such as `GROUPBY` and "shuffles" on large datasets. For example, say that we wanted to see when a user was last active, we can simply have their last 30 days "status" in one row in an `ARRAY`. This way the data of when they were last active is already available in the table. This enables a massively scalable queries on historical data.
- Easy "transition" analysis - with CTD you are able to analyse changes in states such as "Active" today but "Inactive" yesterday easily.

**⚠️ Weaknesses**

- Can only be backfilled sequentially - since it relies on yesterday's data you can't backfill in parallel. This is necessary when the table relies on previous periods' data for its calculations, making parallel backfilling impossible. Example:

*Imagine you have a cumulative table tracking website traffic. Each entry shows the total number of unique visitors up to a specific day. If you need to backfill historical data, you would start with the earliest date and work your way forward. You'd calculate the cumulative traffic for each day based on the traffic from the previous days. If you tried to backfill a later date before an earlier one, you might miss some visitor data from the intervening days, leading to an incorrect cumulative count.*

- Handling Personally Identifiable Information (PII - information that can help identify a person) data can be a mess since deleted/inactive users get carried forward

### The compactness vs usability tradeoff

There is a lot of tradeoffs here and a lot of it goes back to the `OLTP` and `OLAP` systems and the differences there. The most usable tables are ones where the identifiers have dimensions are easy to use. You can easily `WHERE` and `GROUPBY` them. These types of tables are more analytics focused, and hence used by consumers who are less technical in the `OLAP` cube layer.

On the flipside, you have the most compact tables (i.e. not human readable). They are compressed to be as small as possible and cannot be queried directly until they're decoded. In other words, a compact table can just have the identifier as well as a blob of bytes given that the table has been compressed using a compression codex. Hence, in order to read the data you need to first decompress and decode it in order to use it for analytics. From an operation perspective it makes sense so as to minimise the network IO (e.g. In the AirBnB app when you request availability calendar data, you receive a compact table which can be decoded by the app itself - this approach reduces the network IO but is not suitable for analytics). These types of tables are more software engineering focused for production level data, hence you would use this type of table in online systems where latency and data volumes matter a lot. Consumers are usually highly technical.

There is a middle ground between the most compact and most usable table, which is where you use `ARRAY`, `MAP` and `STRUCT` to crunch the data down a little bit, but its a little bit harder to query. These types of tables are used in upstream staging / master data where the majority of  consumers are other data engineers.

### Struct vs Array vs Map

We had spoken a little about each of these complex data types in an earlier section. Now let's discuss on the tradeoffs:

> Note: `STRUCT` and `MAP` are very similar in terms of structuring and presenting the data (i.e. they both group data together), but are very distinct in terms of their usage as well as their individual attributes.

1. `STRUCT`
- **Schema** : We had mentioned that `STRUCT` data type is like a table within a table - i.e. fixed mini-schema
- **Keys** : Predefined and typed (like column names)
- **values** : Can have different types per field
- **Query Access** : Dot notation (`struct.field`)
- Compression is good!
- E.g. Well-known nested structure such as address: `STRUCT<street STRING, city STRING, zip_code STRING>` - all rows in `STRUCT` type column will have this signature:
```json
[
  {
    "street": "123 Orchard Road",
    "city": "Singapore",
    "postal_code": "238823"
  },
  {
    "street": "88 Tanjong Pagar",
    "city": "Singapore",
    "postal_code": "089447"
  },
  {
    "street": "456 Bukit Timah Rd",
    "city": "Singapore",
    "postal_code": "259756"
  }
]

```

2. `MAP`
- **Schema** : Dynamic set of key-value stores
- **Keys** : Flexible, keys can vary across rows
- **values** : All values must be of the same data type
- **Query Access** : Lookup by key (`map["key]`)
- Compression is okay!
- E.g. Unstructured or unpredictable attributes such as currency balances of each user: `MAP<STRING, FLOAT>` - this is where it differs from `STRUCT`, in that each row can vary in terms of structure and it may look something like:
```json
[
  {
    "user_id": "U123",
    "currency_balances": {
      "USD": 100.0,
      "SGD": 135.5,
      "EUR": 92.0
    }
  },
  {
    "user_id": "U456",
    "currency_balances": {
      "JPY": 10000.0,
      "USD": 45.0
    }
  },
  {
    "user_id": "U789",
    "currency_balances": {
      "BTC": 0.003,
      "ETH": 0.05
    }
  }
]
```

3. `ARRAY`
- Holds multiple values of the same data type
- Ordinal - refers to something that has a position or order in sequence
- Arrays are suitable for ordered datasets, and they can contain structs or maps as elements
- E.g. sample data with list of strings for each user's recent purchases : `ARRAY<STRING>` - this is where `UNNEST` is required to flatten the data :
```json
[
  {
    "user_id": "U001",
    "recent_purchases": ["T-shirt", "Sneakers", "Backpack"]
  },
  {
    "user_id": "U002",
    "recent_purchases": ["Laptop"]
  },
  {
    "user_id": "U003",
    "recent_purchases": ["Book", "Pen", "Notebook", "Tablet"]
  },
  {
    "user_id": "U004",
    "recent_purchases": []
  }
]
```
 - A `SQL` query to show a table with a `user_id` column and an `ARRAY` column being flattened as well as an order column being included in result in `postgres`:
```sql
SELECT
  user_id,
  fruit,
  ordinal
FROM user_favorites,
UNNEST(favorite_fruits) WITH ORDINALITY AS fruit(fruit_name, ordinal);
```
### Temporal Cardinality Explosion

💥 Problem: Temporal Cardinality Explosion
Occurs when:

A slowly changing dimension (like `customer_dim`) tracks changes over time (e.g., SCD Type 2)

Each change creates a new row

Over time, a single logical entity (e.g., `customer_id = 123`) has many physical records

🔁 This creates a high cardinality (more unique rows), especially when combined with time granularity (daily, hourly, etc.)

⚠️ Pain Points of High Cardinality in Dimensions
| Problem Area              | Description                                                                 |
|---------------------------|-----------------------------------------------------------------------------|
| 📊 Joins with Fact Tables | Many rows per dimension key (e.g. `customer_id`) due to versioning inflate joins, causing data bloat and duplicates if not properly filtered. |
| 🐢 Query Performance       | More rows to scan, filter, and aggregate slows down query execution — especially in OLAP systems. |
| 💾 Storage Costs           | Versioning and temporal tracking (e.g., SCD Type 2) rapidly increase row counts and disk usage. |
| 🧠 Model Complexity        | Requires more advanced logic (e.g., point-in-time joins, date filters) to return accurate results. |
| 🧩 Analytical Bugs         | Incorrect joins or aggregations can lead to overcounting, undercounting, or misrepresented historical views. |

Let's look at the example given in the lecture. Airbnb has about 6 million listings, and if we want to know the nightly pricing and availability of each night for the next year that's about 365 * 6 million or about 2 billion nights. Should this dataset be:

1. Listing-level with an `ARRAY` of nights?

| Listing_ID | Dates                                                   |
|------------|---------------------------------------------------------|
| 123        | ['2024-01-01', '2024-01-02', '2024-01-03', ...]         |
| 456        | ['2024-01-01', '2024-01-02', '2024-01-03', ...]         |

2. Listing night level with 2 billion rows?

| Listing_ID | Date        |
|------------|-------------|
| 123        | '2024-01-01'|
| 123        | '2024-01-02'|
| 123        | '2024-01-03'|
| 456        | '2024-01-01'|
| 456        | '2024-01-02'|
| 456        | '2024-01-03'|

If you do the sorting right, `PARQUET` will keep these two about the same size. How? -> Using `Run-Length Encoding` (RLE) compression

`RLE` is a process is a lossless compression technique that compresses repeated consecutive values by storing the value and number of time it repeats. It compresses columns independently and works well if adjacent values repeat (hence sorting is important!). In our example, we have 2 billion rows, assuming data is sorted by `Listing_ID` (which is critical for `RLE` to be effective), `RLE` stores the column as:

```python
[
  { value: 123, run_length: 3 },
  { value: 456, run_length: 3 }
]
```

> Note: Only the repeated columns are compressed, not the temporal column due to high cardinality. This process reduces the data size being stored and improves the performance significantly making it just as fast as the `ARRAY` table, arguably.
