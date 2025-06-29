# Week 2 Notes

### Table of contents

- [Dimensional Data Modelling Complex Data Type and Cumulation](#dimensional-data-modelling-complex-data-type-and-cumulation)
  - [Data Modelling Types](#data-modelling-types)
  - [Cumulative Table Design](#cumulative-table-design)

## Dimensional Data Modelling Complex Data Type and Cumulation

A Data Engineer's primary role is to design, build, and maintain the infrastructure and systems that allow organisations to collect, store, process and analyse data. They ensure that the data is readily available and in a usable format for data scientists, analysts, and other stakeholders to derive valuable insights and make informed decisions.

Essentially, the final product is a data warehouse / lakehouse that is built and maintained by the data engieers for the perusal of the business. This should not be functional but rather performant. This means that that the data should not be just available at the request of its users but also fast when users query the database.

Now, to optimise the database the tables within need to built in a certain strucure, and hence the term data modelling was coined. It is simply techniques in which data is structured for querying and analysis, particularly for data warehouses and business intelligence systems. It organises data into `facts` and `dimensions` tables, making it easier to understand and retrieve information. This design is optimised for data retrieval and provide a clear, concise representation of data for business users. The resulting structure is often visualised as a `star` or `snowflake` schema.

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
### 📌 Benefits of Using an Array of STRUCTs
| Benefit               | Why It Matters                                                                 |
|------------------------|--------------------------------------------------------------------------------|
| **Natural hierarchy**  | Reflects real-world nested relationships (e.g., orders with multiple items)   |
| **Cohesive data**      | Keeps multi-field repeating data together, avoiding index mismatches          |
| **Easier denormalization** | Simplifies modeling by avoiding joins while retaining structure         |
| **Query flexibility**  | Easily flatten nested data using `UNNEST` or `explode` for analysis           |
| **Interoperability**   | Maps well to semi-structured formats like JSON, Avro, and Parquet             |
| **Performance**        | Modern engines optimize nested queries and storage for efficiency             |
