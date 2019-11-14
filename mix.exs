defmodule Shun.MixProject do
  use Mix.Project

  def project do
    [
      app: :shun,
      version: "0.1.0",
      elixir: "~> 1.9.0",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      package: package(),
      deps: deps(),
      dialyzer: dialyzer(),
      name: "Shun",
      description: "URI, IPv4 and IPv6 Origin Verification",
      source_url: "https://github.com/evadne/shun",
      docs: docs()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp dialyzer do
    [
      plt_add_apps: [:mix, :iex, :ex_unit],
      flags: ~w(error_handling no_opaque race_conditions underspecs unmatched_returns)a,
      ignore_warnings: "dialyzer-ignore-warnings.exs",
      list_unused_filters: true
    ]
  end

  defp deps do
    [
      {:dialyxir, "~> 1.0.0-rc.6", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Evadne Wu"],
      files: package_files(),
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/evadne/shun"}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"]
    ]
  end

  defp package_files do
    ~w(
      lib/shun/*
      mix.exs
    )
  end
end
