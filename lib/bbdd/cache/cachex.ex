defmodule Bbdd.Cache.Cachex do
  @moduledoc false

  @behaviour Bbdd.Cache

  @impl true
  def get(uuid, opts) do
    cache_name = Bbdd.config(:cache_name, opts)
    Cachex.get(cache_name, uuid)
  end

  @impl true
  def put(uuid, value, opts) do
    cache_name = Bbdd.config(:cache_name, opts)

    with {:ok, _} <- Cachex.put(cache_name, uuid, value) do
      :ok
    end
  end

  @impl true
  def delete(uuid, opts) do
    cache_name = Bbdd.config(:cache_name, opts)

    with {:ok, _} <- Cachex.del(cache_name, uuid) do
      :ok
    end
  end
end
