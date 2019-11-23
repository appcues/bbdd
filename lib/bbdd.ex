defmodule Bbdd do
  @moduledoc """
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
        prefix_length: 9
  """

  @defaults [
    backend: Bbdd.Backend.DynamoDB,
  ]

  defp config(name, opts) do
    opts[name] || Application.get_env(:bbdd, name) || @defaults[name]
  end

  def mark(uuid, opts \\ []) do
    with {:ok, prefix, suffix} <- split_uuid(uuid, opts) do
      backend = config(:backend, opts)
      backend.mark(prefix, suffix, opts)
    end
  end

  def clear(uuid, opts \\ []) do
    with {:ok, prefix, suffix} <- split_uuid(uuid, opts) do
      backend = config(:backend, opts)
      backend.clear(prefix, suffix, opts)
    end
  end

  def marked?(uuid, opts \\ []) do
    with {:ok, prefix, suffix} <- split_uuid(uuid, opts) do
      backend = config(:backend, opts)
      backend.marked?(prefix, suffix, opts)
    end
  end

  def clear?(uuid, opts \\ []) do
    with {:ok, prefix, suffix} <- split_uuid(uuid, opts) do
      backend = config(:backend, opts)
      backend.clear?(prefix, suffix, opts)
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
    |> String.downcase
    |> String.replace(~r/[^0-9a-f]/, "")
  end
end
