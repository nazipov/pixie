defmodule Pixie.Mixfile do
  use Mix.Project

  def project do
    [
      app:               :pixie,
      version:           "0.3.5",
      elixir:            "~> 1.0",
      build_embedded:    Mix.env == :prod,
      start_permanent:   Mix.env == :prod,
      deps:              deps,
      preferred_cli_env: [espec: :test],
      package:           package,
      description:       description,
      source_url:        "https://github.com/messagerocket/pixie"
    ]
  end

  defp package do
    [
      maintainers: ["James Harton"],
      licenses: ["MIT"],
      links: %{
        "bitbucket"     => "https://bitbucket.org/messagerocket/pixie",
        "messagerocket" => "https://messagerocket.co/",
        "github"        => "https://github.com/messagerocket/pixie"
      }
    ]
  end

  defp description do
    """
    Bayeux compatible server written in Elixir.
    """
  end

  def application do
    [
      applications: [:logger, :crypto, :cowboy, :plug, :gproc, :con_cache, :tzdata],
      mod: {Pixie, []}
    ]
  end

  defp deps do
    [
      {:cowboy,        "~> 1.0.2", optional: true},
      {:poison,        "~> 2.2.0"},
      {:secure_random, "~> 0.1"},
      {:ex_minimatch,  "~> 0.0.1"},
      {:timex,         "~> 3.0"},
      {:plug,          "~> 1.3.0"},
      {:exredis,       "~> 0.2.4", optional: true},
      {:poolboy,       "~> 1.5.1"},
      {:ex_doc,        "~> 0.14", optional: true},
      {:gproc,         "~> 0.3"},
      {:con_cache,     "~> 0.11.1"},
      {:espec,         "~> 1.2.1", only: :test},
      {:faker,         "~> 0.7.0", only: :test}
    ]
  end
end
