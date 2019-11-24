defmodule Bbdd.Backend do
  @moduledoc false

  @callback mark(
              prefix :: String.t(),
              suffix :: String.t(),
              opts :: Keyword.t()
            ) :: :ok | {:error, any}
  @callback clear(
              prefix :: String.t(),
              suffix :: String.t(),
              opts :: Keyword.t()
            ) :: :ok | {:error, any}
  @callback marked?(
              prefix :: String.t(),
              suffix :: String.t(),
              opts :: Keyword.t()
            ) :: {:ok, boolean} | {:error, any}
end
