defmodule Bbdd do
  @moduledoc """
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
    last two calendar months.
  * `Bbdd.clear?(uuid)` returns the opposite of `Bbdd.marked?(uuid)`.

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
  * `:prefix_length` (integer) The number of UUID characters to use as a
    primary key.  Default 9.

  Other configs:

  * `:backend` (module) Deduping backend. Default `Bbdd.Backend.DynamoDB`.
  * `:column_prefix` (string) Prefix for each DynamoDB column. E.g., a prefix
    of `xyz` in November 2019 would result in a column named `xyz_2019_11`.
  * `:cache` (module or `:none`) Cache backend. Default `Bbdd.Cache.Cachex`.
    Set to `:none` to skip caching entirely.
  * `:cache_name` (atom) Cachex cache name to use. Default `:bbdd_cache`.
    Changing this parameter requires starting the given cache manually;
    see Cachex documentation.
  """

  @defaults [
    backend: Bbdd.Backend.DynamoDB,
    column_prefix: "bbdd",
    cache: Bbdd.Cache.Cachex,
    cache_name: :bbdd_cache,
    prefix_length: 9,
  ]

  @doc false
  def config(name, opts) do
    opts[name] || Application.get_env(:bbdd, name) || @defaults[name]
  end

  @doc ~S"""
  Marks a UUID.  The mark will be purged from the database after two
  calendar months (i.e., 28-62 days), but may still exist in local cache
  after that time.
  """
  @spec mark(String.t(), Keyword.t()) :: :ok | {:error, any}
  def mark(uuid, opts \\ []) do
    {prefix, suffix} = split_uuid(uuid, opts)
    cached_mark(uuid, prefix, suffix, opts)
  end

  defp cached_mark(uuid, prefix, suffix, opts) do
    case config(:cache, opts) do
      :none ->
        uncached_mark(prefix, suffix, opts)

      cache ->
        case cache.get(uuid, opts) do
          {:ok, nil} ->
            with :ok <- uncached_mark(prefix, suffix, opts) do
              cache.put(uuid, true, opts)
            end
        end
    end
  end

  defp uncached_mark(prefix, suffix, opts) do
    backend = config(:backend, opts)
    backend.mark(prefix, suffix, opts)
  end

  @doc ~S"""
  Unmarks a UUID. Note that the mark may persist in other servers' caches.
  """
  @spec clear(String.t(), Keyword.t()) :: :ok | {:error, any}
  def clear(uuid, opts \\ []) do
    {prefix, suffix} = split_uuid(uuid, opts)
    cached_clear(uuid, prefix, suffix, opts)
  end

  defp cached_clear(uuid, prefix, suffix, opts) do
    case config(:cache, opts) do
      :none ->
        uncached_clear(prefix, suffix, opts)

      cache ->
        with :ok <- uncached_clear(prefix, suffix, opts) do
          cache.delete(uuid, opts)
        end
    end
  end

  defp uncached_clear(prefix, suffix, opts) do
    backend = config(:backend, opts)
    backend.clear(prefix, suffix, opts)
  end

  @doc ~S"""
  Returns `{:ok, true}` if the given UUID has been marked in the last two
  calendar months (or possibly before this time, if it was marked or looked
  up using this server and its record is still in cache).
  Returns `{:ok, false}` otherwise.
  """
  @spec marked?(String.t(), Keyword.t()) :: {:ok, boolean} | {:error, any}
  def marked?(uuid, opts \\ []) do
    {prefix, suffix} = split_uuid(uuid, opts)
    cached_marked?(uuid, prefix, suffix, opts)
  end

  defp cached_marked?(uuid, prefix, suffix, opts) do
    case config(:cache, opts) do
      :none ->
        uncached_marked?(prefix, suffix, opts)

      cache ->
        case cache.get(uuid, opts) do
          {:ok, nil} ->
            case uncached_marked?(prefix, suffix, opts) do
              {:ok, true} ->
                with :ok <- cache.put(uuid, true, opts) do
                  {:ok, true}
                end

              other ->
                other
            end

          {:ok, _} ->
            {:ok, true}

          error ->
            error
        end
    end
  end

  defp uncached_marked?(prefix, suffix, opts) do
    backend = config(:backend, opts)
    backend.marked?(prefix, suffix, opts)
  end

  @doc ~S"""
  Returns whether a UUID has not been marked in the last two calendar months;
  in other words, the opposite of `marked?/2`.
  """
  @spec clear?(String.t(), Keyword.t()) :: {:ok, boolean} | {:error, any}
  def clear?(uuid, opts \\ []) do
    case marked?(uuid, opts) do
      {:ok, true} -> {:ok, false}
      {:ok, false} -> {:ok, true}
      error -> error
    end
  end

  defp split_uuid(uuid, opts) do
    prefix_length = config(:prefix_length, opts)

    uuid
    |> normalize_uuid
    |> String.split_at(prefix_length)
  end

  defp normalize_uuid(uuid) do
    uuid
    |> String.downcase()
    |> String.replace(~r/[^0-9a-f]/, "")
  end
end
