defmodule Pixie.Mixfile do
  use Mix.Project

  @source_url "https://bitbucket.org/messagerocket/pixie/"

  def project do
    [
      app: :pixie,
      version: "0.0.3",
      elixir: "~> 1.0",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps,
      preferred_cli_env: [espec: :test],
      package: package,
      description: description,
      source_url: @source_url
    ]
  end

  defp package do
    [
      contributors: ["James Harton"],
      licenses: ["MIT"],
      links: %{
        "bitbucket" => @source_url,
        "messagerocket" => "https://messagerocket.co/"
      }
    ]
  end

  defp description do
    """
    Faye compatible server written in Elixir.
    """
  end

  def application do
    [
      applications: [:logger, :cowboy, :plug],
      mod: {Pixie, []}
    ]
  end

  defp deps do
    [
      {:cowboy,        "~> 1.0.2", optional: true},
      {:poison,        "~> 1.4.0"},
      {:secure_random, "~> 0.1"},
      {:ex_minimatch,  "~> 0.0.1"},
      {:timex,         "~> 0.19.2"},
      {:espec,         "~> 0.7.0", only: :test},
      {:plug,          "~> 1.0.0"},
      {:exredis,       "~> 0.2.0", optional: true},
      {:poolboy,       "~> 1.5.1"}
    ]
  end
end
