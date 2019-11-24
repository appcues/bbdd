defmodule Bbdd.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Cachex, [Bbdd.config(:cache_name, []), []]),
    ]

    opts = [strategy: :one_for_one, name: Bbdd.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
