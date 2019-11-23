defmodule Bbdd.Backend.DynamoDB do
  @behaviour Bbdd.Backend

  @impl true
  def mark(prefix, suffix, opts) do
    with {:ok, request} <- request_mark(prefix, suffix, opts),
         {:ok, response} <- ExAws.request() do
      :ok
    end
  end

  @impl true
  def clear(prefix, suffix, opts) do
    with {:ok, request} <- request_clear(prefix, suffix, opts),
         {:ok, response} <- ExAws.request() do
      :ok
    end
  end

  @impl true
  def marked?(prefix, suffix, opts) do
    with {:ok, request} <- request_marked?(prefix, opts),
         {:ok, response} <- ExAws.request(),
         {:ok, prev_suffix_set, cur_suffix_set} <- decode_response_marked?(response)
      {:ok, MapSet.member?(prev_suffix_set, suffix) || MapSet.member?(cur_suffix_set, suffix)}
    end
  end

  @impl true
  def clear?(prefix, suffix, opts) do
    with {:ok, marked?} <- marked?(prefix, suffix, opts) do
      {:ok, !marked?}
    end
  end

  defp request_mark(prefix, suffix, opts) do
    table = config(:table, opts)
    key = %{"prefix" => %{"S" => prefix}}
    update_expression = """
      ADD #this_month :suffix
      REMOVE #two_months_ago
    """
    expression_attribute_names = %{
      "#this_month" => n_months_ago(0),
      "#two_months_ago" => n_months_ago(2),
    }
    expression_attribute_values = %{
      ":suffix" => %{"SS" => [suffix]},
    }
    ExAws.Dynamo.update_item(table, key, [
      condition_expression: condition_expression,
      update_expression: update_expression,
      expression_attribute_names: expression_attribute_names,
      expression_attribute_values: expression_attribute_values,
    ])
  end

  defp request_clear(prefix, suffix, opts) do
    table = config(:table, opts)
    key = %{"prefix" => %{"S" => prefix}}
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
      ":suffix" => %{"SS" => [suffix]},
    }
    ExAws.Dynamo.update_item(table, key, [
      condition_expression: condition_expression,
      update_expression: update_expression,
      expression_attribute_names: expression_attribute_names,
      expression_attribute_values: expression_attribute_values,
    ])
  end

  defp request_marked?(prefix, opts) do
    table = config(:table, opts)
    key = %{"prefix" => %{"S" => prefix}}
    ExAws.Dynamo.get_item(table, key)
  end

  defp decode_response_marked?(response) do
    item = ExAWs.Dynamo.decode_item(response, decode_sets: true)
    {:ok, item[n_months_ago(1)] || MapSet.new(), item[n_months_ago(0)] || MapSet.new}
  end

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
