defmodule TransactionBatcher.MixProject do
  use Mix.Project

  def project do
    [
      app: :transaction_batcher,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:amqp, :logger],
      mod: {TransactionBatcher.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:amqp, "~> 3.1"},
      {:csv, "~> 3.0"},
      {:jason, "~> 1.3"},
      {:quantum, "~> 3.5"}
    ]
  end
end
