defmodule Bbdd.Backend do
  @callback mark(prefix :: String.t, suffix :: String.t, opts \\ Keyword.t) :: :ok | {:error, any}
  @callback clear(prefix :: String.t, suffix :: String.t, opts \\ Keyword.t) :: :ok | {:error, any}
  @callback marked?(prefix :: String.t, suffix :: String.t, opts \\ Keyword.t) :: {:ok, boolean} | {:error, any}
  @callback clear?(prefix :: String.t, suffix :: String.t, opts \\ Keyword.t) :: {:ok, boolean} | {:error, any}
end
