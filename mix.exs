defmodule GitStats.Mixfile do

  use Mix.Project

  def project do
    [
      app: :git_stats,
      escript: [main_module: GitStats.CLI],
      version: "0.1.0",
      elixir: "~> 1.4",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {GitStats.App, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:httpoison, "~> 0.11.1"},
      {:monadex,   "~> 1.1"},
      {:poison,    "~> 3.1"}
    ]
  end

end
