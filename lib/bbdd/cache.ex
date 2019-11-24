defmodule Bbdd.Cache do
  @moduledoc false
  @callback get(uuid :: String.t(), opts :: Keyword.t()) ::
              {:ok, nil | any} | {:error, any}
  @callback put(uuid :: String.t(), value :: any, opts :: Keyword.t()) ::
              :ok | {:error, any}
  @callback delete(uuid :: String.t(), opts :: Keyword.t()) ::
              :ok | {:error, any}
end
