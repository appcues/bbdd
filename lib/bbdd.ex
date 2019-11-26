defmodule Bbdd do
  @moduledoc File.read!("README.md") |> String.split("<!--start-docs-->") |> Enum.at(1)

  @defaults [
    backend: Bbdd.Backend.DynamoDB,
    column_prefix: "bbdd",
    cache: Bbdd.Cache.Cachex,
    cache_name: :bbdd_cache,
    base: 16,
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
    |> normalize_uuid(opts)
    |> String.split_at(prefix_length)
  end

  defp normalize_uuid(uuid, opts) do
    rebase_fun = case config(:base, opts) do
      16 -> &Base.encode16(&1, case: :lower)
      32 -> &Base.encode32/1
      64 -> &Base.encode64/1
    end

    uuid
    |> String.replace(~r/[^0-9a-fA-F]/, "")
    |> Base.decode16!(case: :mixed)
    |> rebase_fun.()
    |> String.replace("=", "")
  end
end
