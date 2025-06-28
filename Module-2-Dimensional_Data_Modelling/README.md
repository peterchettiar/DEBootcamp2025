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

- `STRUCT` : Composite data type that groups together multiple fields of different data types (conceptually similar to `dict` in python)
