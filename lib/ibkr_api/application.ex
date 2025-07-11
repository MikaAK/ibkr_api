defmodule IbkrApi.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Clean period similar to previous cleanup_interval_ms
    hammer_opts = [clean_period: 60_000 * 10]

    children = [
      # Start the Hammer rate limiter
      {IbkrApi.RateLimiter.RateLimit, hammer_opts},

      # HTTP client for API requests
      IbkrApi.HTTP
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: IbkrApi.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
