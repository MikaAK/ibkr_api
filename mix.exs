defmodule IbkrApi.MixProject do
  use Mix.Project

  @source_url "https://github.com/MikaAK/ibkr_api"
  @version "1.0.3"
  @description "Elixir client for Interactive Brokers' Client Portal API"

  def project do
    [
      app: :ibkr_api,
      version: @version,
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: @description,
      package: package(),
      docs: docs(),
      source_url: @source_url
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(_), do: ["lib", "test/support"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {IbkrApi.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:finch, "~> 0.16"},
      {:proper_case, "~> 1.3"},
      {:error_message, "~> 0.3"},
      {:jason, "~> 1.4"},
      {:hammer, "~> 7.0"},
      {:nimble_options, "~> 1.1"},
      {:websockex, "~> 0.4.3"},
      {:ex_doc, "~> 0.29", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Mika Kalathil"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE test/support)
    ]
  end

  defp docs do
    [
      main: "readme",
      source_url: @source_url,
      extras: [
        "README.md",
        "guides/tutorials/getting_started.md",
        "guides/tutorials/authentication.md",
        "guides/how-to/account_management.md",
        "guides/how-to/trading.md",
        "guides/how-to/websocket_streaming.md",
        "guides/how-to/testing_with_http_mocks.md",
        "guides/how-to/backtesting.md",
        "guides/reference/api_reference.md",
        "guides/explanations/architecture.md"
      ],
      groups_for_extras: [
        Tutorials: ~r/guides\/tutorials\/.?/,
        "How-To Guides": ~r/guides\/how-to\/.?/,
        Reference: ~r/guides\/reference\/.?/,
        Explanation: ~r/guides\/explanations\/.?/
      ],
      groups_for_modules: [
        "Client Portal": [
          IbkrApi.ClientPortal.Auth,
          IbkrApi.ClientPortal.Account,
          IbkrApi.ClientPortal.Contract,
          IbkrApi.ClientPortal.Order,
          IbkrApi.ClientPortal.Profile,
          IbkrApi.ClientPortal.Trade
        ],
        "WebSocket": [
          IbkrApi.Websocket,
          IbkrApi.Websocket.Client
        ],
        "Backtesting": [
          IbkrApi.Backtester.Bar,
          IbkrApi.Backtester.Portfolio,
          IbkrApi.Backtester.Strategy,
          IbkrApi.Backtester.Engine,
          IbkrApi.Backtester.Strategies.MA,
          IbkrApi.Backtester.Example
        ],
        "Core": [
          IbkrApi,
          IbkrApi.Application,
          IbkrApi.Config,
          IbkrApi.HTTP
        ]
      ]
    ]
  end
end
