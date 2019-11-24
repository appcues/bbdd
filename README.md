# Bbdd -- Boop Boop Dedupe

Bbdd is a deduplication engine. It is built on DynamoDB and follows the design
described by Joanna Solmon in a blog post called [Tweaking DynamoDB Tables for
Fun and Profit](https://eng.localytics.com/tweaking-dynamodb-tables/).

## TL;DR

Goals:
* Deduplicate a data set based on a UUID attached to each data point.
* Keep reads and writes under 1KB to minimize bandwidth costs.
* Age out old records to keep total size manageable.

Strategy:
* Use a fixed-length prefix of these UUIDs as primary keys in a K/V store.
* Under each key, store the remaining suffixes in a set data type according
  to the calendar month of their addition.
* With each DB write, ensure that the suffix set from two months ago is
  removed.

## Usage

* `Bbdd.mark(uuid)` marks an ID.
* `Bbdd.clear(uuid)` unmarks an ID.
* `Bbdd.marked?(uuid)` returns whether an ID has been marked within the
  last two months.
* `Bbdd.clear?(uuid)` returns the opposite of `Bbdd.marked?(uuid)`.

## Configuration

Config values can be passed through `opts` or set in `config/config.exs`:

    config :bbdd,
      table: "my_table_name",  # required
      prefix_length: 9         # optional (default 9)

ExAws will need to be configured in `config.exs` as well.

    config :ex_aws, :dynamodb,
      access_key_id: "123",
      secret_access_key: "abc",
      region: "us-west-2"
