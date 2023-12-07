defmodule Kanta.PoWriter.Plugin.MixProject do
  use Mix.Project

  def project do
    [
      app: :kanta_po_writer_plugin,
      description: "Kanta plugin for exporting to PO files",
      version: "0.0.1",
      elixir: ">= 1.14.0",
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
      {:kanta, github: "curiosum-dev/kanta", branch: "feature/child-lv-components", override: true},

      # dev
      {:doctor, "~> 0.21.0", only: :dev},
      {:versioce, "~> 2.0.0", only: :dev},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:styler, "~> 0.8", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:gradient, github: "esl/gradient"}
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
