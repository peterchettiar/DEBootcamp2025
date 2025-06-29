# Week 2 Notes

### Table of contents

- [Dimensional Data Modelling Complex Data Type and Cumulation](#dimensional-data-modelling-complex-data-type-and-cumulation)
  - [Complex Data Types](#complex-data-types)
  - [Types of Dimensions](#types-of-dimensions)
  - [Data Modelling Types](#data-modelling-types)
  - [Cumulative Table Design](#cumulative-table-design)

## Dimensional Data Modelling Complex Data Type and Cumulation

A Data Engineer's primary role is to design, build, and maintain the infrastructure and systems that allow organisations to collect, store, process and analyse data. They ensure that the data is readily available and in a usable format for data scientists, analysts, and other stakeholders to derive valuable insights and make informed decisions.

Essentially, the final product is a data warehouse / lakehouse that is built and maintained by the data engieers for the perusal of the business. This should not be functional but rather performant. This means that that the data should not be just available at the request of its users but also fast when users query the database.

Now, to optimise the database, the tables within need to built in a certain strucure, and hence the term data modelling was coined. It is simply techniques in which data is structured for querying and analysis, particularly for data warehouses and business intelligence systems. It organises data into `facts` and `dimensions` tables, making it easier to understand and retrieve information. This design is optimised for data retrieval and provide a clear, concise representation of data for business users. The resulting structure is often visualised as a `star` or `snowflake` schema.

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

#### 1. Fixed (Static) Dimensions
- Also called **Type 0 Slowly Changing Dimensions**
- The attributes never change once inserted
- Any change is ignored (used for fixed entities like country codes, currency symbols, etc.)
- `USE CASE` : static reference data - e.g. currency (USD, EUR)
- **Example:**

| Customer ID | Name  | Country |
|-------------|-------|---------|
| C001        | Alice | Japan   |

If Alice moves to Singapore, the country remains **Japan** in the dimension.

#### 2. Type 1 SCD - Overwrite
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

#### 3. Type 2 SCD - Add New Row
- Creates a new row for each change
- Keep full history with effective dates or versioning
- Fact tables link to the correct historical version
- `USE CASE` : Track customer moving regions, product price changes, etc.
- **Example:**

| Customer ID | Name  | Region | Version | Effective Date |
|-------------|-------|--------|---------|----------------|
| C001        | Alice | East   | 1       | 2023-01-01     |
| C001        | Alice | West   | 2       | 2024-05-01     |

#### 4. Type 3 SCD - Add New Column
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
