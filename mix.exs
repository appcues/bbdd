defmodule Bbdd.MixProject do
  use Mix.Project

  def project do
    [
      app: :bbdd,
      version: "0.2.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),

      ## Docs
      name: "Boop Boop Dedupe",
      docs: [
        main: "Bbdd",
      ],
    ]
  end

  defp package do
    [
      organization: "appcues",
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Bbdd.Application, []},
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_aws, "~> 2.1"},
      {:ex_aws_dynamo, "~> 2.3"},
      {:hackney, "~> 1.0"},
      {:poison, "~> 5.0"},
      {:cachex, "~> 3.0"},
      {:dialyxir, "~> 1.0.0-rc.7", runtime: false},
      {:freedom_formatter, "~> 1.0", runtime: false},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      {:uuid, "~> 1.0", only: [:dev, :test]},
    ]
  end
end
