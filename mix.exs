defmodule Kanta.PoWriter.Plugin.MixProject do
  use Mix.Project

  def project do
    [
      app: :kanta_po_writer_plugin,
      description: "Kanta plugin for exporting to PO files",
      version: "0.1.0",
      elixir: "~> 1.14",
      package: package(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix_live_view, "~> 0.18"},
      {:kanta, "~> 0.1.3", optional: true},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.3", only: [:dev], runtime: false},
      {:doctor, "~> 0.21.0", only: :dev},
      {:versioce, "~> 2.0.0", only: :dev},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/ravensiris/kanta_po_writer_plugin"},
      files: ~w(lib LICENSE.md mix.exs README.md)
    ]
  end
end
