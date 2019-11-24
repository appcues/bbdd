defmodule Bbdd.Backend.DynamoDB do
  @moduledoc false

  @behaviour Bbdd.Backend

  @impl true
  def mark(prefix, suffix, opts) do
    request = request_mark(prefix, suffix, opts)

    with {:ok, _response} <- ExAws.request(request) do
      :ok
    end
  end

  @impl true
  def clear(prefix, suffix, opts) do
    request = request_clear(prefix, suffix, opts)

    with {:ok, _response} <- ExAws.request(request) do
      :ok
    end
  end

  @impl true
  def marked?(prefix, suffix, opts) do
    request = request_marked?(prefix, opts)

    with {:ok, response} <- ExAws.request(request),
         {:ok, prev_suffix_set, cur_suffix_set} <-
           decode_response_marked?(response) do
      {:ok,
       MapSet.member?(prev_suffix_set, suffix) ||
         MapSet.member?(cur_suffix_set, suffix)}
    end
  end

  ## Returns the request for `mark`.
  defp request_mark(prefix, suffix, opts) do
    table = Bbdd.config(:table, opts)
    key = %{"prefix" => prefix}

    update_expression = """
      ADD #this_month :suffix
      REMOVE #two_months_ago
    """

    expression_attribute_names = %{
      "#this_month" => n_months_ago(0),
      "#two_months_ago" => n_months_ago(2),
    }

    expression_attribute_values = %{
      "suffix" => %{"SS" => [suffix]},
    }

    ExAws.Dynamo.update_item(table, key,
      update_expression: update_expression,
      expression_attribute_names: expression_attribute_names,
      expression_attribute_values: expression_attribute_values
    )
  end

  ## Returns the request for `clear`.
  defp request_clear(prefix, suffix, opts) do
    table = Bbdd.config(:table, opts)
    key = %{"prefix" => prefix}

    update_expression = """
      DELETE #this_month :suffix, #last_month :suffix
      REMOVE #two_months_ago
    """

    expression_attribute_names = %{
      "#this_month" => n_months_ago(0),
      "#last_month" => n_months_ago(1),
      "#two_months_ago" => n_months_ago(2),
    }

    expression_attribute_values = %{
      "suffix" => %{"SS" => [suffix]},
    }

    ExAws.Dynamo.update_item(table, key,
      update_expression: update_expression,
      expression_attribute_names: expression_attribute_names,
      expression_attribute_values: expression_attribute_values
    )
  end

  ## Returns the request for `marked?`.
  defp request_marked?(prefix, opts) do
    table = Bbdd.config(:table, opts)
    key = %{"prefix" => prefix}
    ExAws.Dynamo.get_item(table, key)
  end

  ## Returns MapSets containing last month's and this month's suffixes.
  defp decode_response_marked?(response) do
    item = response["Item"]
    last_month_set = MapSet.new(item[n_months_ago(1)]["SS"] || [])
    this_month_set = MapSet.new(item[n_months_ago(0)]["SS"] || [])
    {:ok, last_month_set, this_month_set}
  end

  ## Returns the column name for N months ago.
  defp n_months_ago(n) do
    {year, month, _d} = :erlang.date()

    if month > n do
      {year, month - n}
    else
      {year - 1, 12 + month - n}
    end
    |> to_column
  end

  defp to_column({year, month}) do
    "ids_#{year}_#{month}"
  end
end
