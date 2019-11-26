# Bbdd -- Boop Boop Dedupe

<!--start-docs-->

Bbdd is a deduplication engine. It is built on DynamoDB and follows the design
described by Joanna Solmon in a blog post called [Tweaking DynamoDB Tables for
Fun and Profit](https://eng.localytics.com/tweaking-dynamodb-tables/).

## TL;DR

Goals:
* Deduplicate a data set based on a UUID attached to each data point.
* Keep records under 1KB to minimize write bandwidth costs.
* Age out old records to keep total size manageable.

Strategy:
* Use a fixed-length prefix of these UUIDs as primary keys in a K/V store.
* Under each key, store the remaining suffixes in a set data type according
  to the calendar month of their addition.
* With each DB write, ensure that the suffix set from two months ago is
  removed.

Enhancement to original strategy:
* Allow UUIDs to be encoded as base 16, 32, or 64 in DynamoDB. This provides
  a range of record and total size options. See the `Bbdd.Size` docs for
  more information. (Input UUIDs must still be encoded as a base 16 string,
  i.e. hexadecimal with optional hyphens.)

## Usage

* `Bbdd.mark(uuid)` marks an ID.
* `Bbdd.clear(uuid)` unmarks an ID.
* `Bbdd.marked?(uuid)` returns whether an ID has been marked within the
  last two calendar months.
* `Bbdd.clear?(uuid)` returns the opposite of `Bbdd.marked?(uuid)`.

`uuid` must be a 128-bit value encoded as a hexadecimal string,
with optional hyphens, e.g. `7574e9c6-5960-499e-9a7e-9b6495eb23ed`
or `CC317EBA4A514CC28E7A887738FC6B25`.

## Configuration

Config values can be passed through `opts` or set in `config/config.exs`:

    config :bbdd,
      table: "my_table_name",
      prefix_length: 9

ExAws will need to be configured in `config.exs` as well.

    config :ex_aws, :dynamodb,
      access_key_id: "123",
      secret_access_key: "abc",
      region: "us-west-2"

Common configs:

* `:table` (string) The name of the DynamoDB table to use. Required.
* `:base` (`16`, `32`, or `64`) The method of representing the UUID in
  DynamoDB: hexadecimal/base 16, base 32, or base 64. Default 16.
* `:prefix_length` (integer) The number of characters of each `base`-
  encoded UUID to use as a primary key. Default 9.

Other configs:

* `:backend` (module) Deduping backend. Default `Bbdd.Backend.DynamoDB`.
* `:column_prefix` (string) Prefix for each DynamoDB column. E.g., a prefix
  of `xyz` in November 2019 would result in a column named `xyz_2019_11`.
* `:cache` (module or `:none`) Cache backend. Default `Bbdd.Cache.Cachex`.
  Set to `:none` to skip caching entirely.
* `:cache_name` (atom) Cachex cache name to use. Default `:bbdd_cache`.
  Changing this parameter requires starting the given cache manually;
  see Cachex documentation.

