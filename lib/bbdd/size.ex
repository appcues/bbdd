defmodule Bbdd.Size do
  @moduledoc ~S"""
  A tool for helping choose `:base` and `:prefix_length` parameters for your
  deduper's Dynamo table, with the goal of minimizing cost.

  Starting with the maximum number of IDs you intend to deduplicate each
  month, invoke `run/1` to print the average sizes of each database record and
  the total dataset. The goal is to have the record size under 1024 bytes
  to minimize bandwidth costs, while also minimizing the static cost based
  on the overall size of the dataset.

  100 bytes is added to each record size to account for the table's primary key
  index.

      > Bbdd.Size.estimate(10_000_000_000)
      base: 16, prefix_length: 6      record: 31100 B         total: 522 GB
      base: 16, prefix_length: 7      record: 1970 B          total: 529 GB
      base: 16, prefix_length: 8      record: 220 B           total: 945 GB
      base: 16, prefix_length: 9      record: 116 B           total: 7971 GB
      base: 32, prefix_length: 5      record: 12622 B         total: 424 GB
      base: 32, prefix_length: 6      record: 479 B           total: 514 GB
      base: 32, prefix_length: 7      record: 118 B           total: 4054 GB
      base: 32, prefix_length: 8      record: 108 B           total: 118747 GB
      base: 64, prefix_length: 4      record: 21562 B         total: 362 GB
      base: 64, prefix_length: 5      record: 422 B           total: 453 GB
      base: 64, prefix_length: 6      record: 111 B           total: 7628 GB
      base: 64, prefix_length: 7      record: 107 B           total: 470591 GB
      :ok

  We see from the output that, assuming a workload of 10 billion IDs per month,
  `base: 64 and `prefix_length: 5` has the lowest total size while still being
  well under 1KB per record.  At 422 bytes, the workload could more than double
  before needing to worry about increased bandwidth costs.
  """

  defp id_length(base)
  defp id_length(16), do: 32
  defp id_length(32), do: 26
  defp id_length(64), do: 22

  @doc ~S"""
  Returns `{record_size, total_size}` in bytes.
  """
  def size(ids_per_month, base, prefix_length) do
    record_size = prefix_length + 100 + round((2 * ids_per_month * (id_length(base) - prefix_length)) / :math.pow(base, prefix_length))
    total_size = record_size * round(:math.pow(base, prefix_length))
    {record_size, total_size}
  end

  @runs [
    [16, 6],
    [16, 7],
    [16, 8],
    [16, 9],
    [32, 5],
    [32, 6],
    [32, 7],
    [32, 8],
    [64, 4],
    [64, 5],
    [64, 6],
    [64, 7],
  ]

  @doc ~S"""
  Estimates of the record and total dataset sizes according to the
  given `ids_per_month` and common settings of `:base` and `:prefix_length`
  with `size/3`, and prints estimates to standard output.
  """
  def estimate(ids_per_month) do
    for args <- @runs do
      [base, prefix_length] = args
      {record_size, total_size} = size(ids_per_month, base, prefix_length)
      IO.puts("base: #{base}, " <>
        "prefix_length: #{prefix_length}\t" <>
        "record: #{record_size} B   \t" <>
        "total: #{round(total_size / 1_000_000_000)} GB")
    end
    :ok
  end
end
