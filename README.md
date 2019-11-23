# Bbdd -- Boop Boop Dedupe

Bbdd is a deduplication engine. It is built on DynamoDB and follows the design
described by Joanna Solmon in a blog post called [Tweaking DynamoDB Tables for
Fun and Profit](https://eng.localytics.com/tweaking-dynamodb-tables/).

Synopsis:

* `Bbdd.mark(uuid)` marks an ID.
* `Bbdd.clear(uuid)` unmarks an ID.
* `Bbdd.marked?(uuid)` returns whether an ID has been marked within the
  last two months.
* `Bbdd.clear?(uuid)` returns the opposite of `Bbdd.marked?(uuid)`.

Config:

    config :bbdd,
      table: "my_table_name",
      prefix_length: 9 Bbdd


