defmodule IbkrApi.RateLimiter do
  @moduledoc """
  Rate limiting implementation for IBKR API requests using Hammer v7.

  Enforces both global and per-endpoint rate limits according to IBKR's published limits:
  - Global: 50 requests per second
  - Gateway: 10 requests per second
  - Per-endpoint: Various limits as documented

  Rate limits are configurable through options passed to each function.
  """

  require Logger

  # Embedded Hammer rate limiter module
  defmodule RateLimit do
    @moduledoc false
    use Hammer, backend: :ets
  end

  @options_schema [
    rate_limits: [
      type: :keyword_list,
      required: false,
      doc: "Rate limit configuration as a keyword list. If not provided, uses Config defaults."
    ],
    bucket_prefix: [
      type: :string,
      default: "",
      doc: "Prefix for rate limit buckets (useful for test isolation)"
    ]
  ]

  @doc """
  Checks if a request should be allowed based on the rate limits.

  ## Options

  #{NimbleOptions.docs(@options_schema)}

  ## Returns

  - `:ok` if the request is allowed
  - `{:error, reason}` if the request exceeds rate limits
  """
  @spec check_rate(binary, keyword) :: :ok | {:error, any}
  def check_rate(url_path, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @options_schema)

    with :ok <- check_global_rate(opts),
         :ok <- check_endpoint_rate(url_path, extract_endpoint(url_path), opts) do
      :ok
    else
      {:error, _} = error -> error
    end
  end

  @doc """
  Checks the global rate limit for all IBKR API requests.

  By default, this is 50 requests per second for authenticated users.
  """
  @spec check_global_rate(keyword) :: :ok | {:error, any}
  def check_global_rate(opts \\ []) do
    opts = NimbleOptions.validate!(opts, @options_schema)
    rate_limits = Keyword.get(opts, :rate_limits) || IbkrApi.Config.default_rate_limits()
    bucket_prefix = Keyword.get(opts, :bucket_prefix, "")
    limit_config = get_rate_limit(rate_limits, :global)

    case RateLimit.hit(
      "#{bucket_prefix}global",
      limit_config.time_window_ms,
      limit_config.limit
    ) do
      {:allow, _count} -> :ok
      {:deny, _limit} ->
        Logger.warning("Global rate limit exceeded: #{inspect(limit_config)}")
        {:error, :rate_limit_exceeded}
    end
  end

  @doc """
  Checks the endpoint-specific rate limit.

  Each endpoint may have its own rate limit as defined in IBKR's documentation.
  """
  @spec check_endpoint_rate(binary, atom, keyword) :: :ok | {:error, any}
  def check_endpoint_rate(_url_path, endpoint, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @options_schema)
    rate_limits = Keyword.get(opts, :rate_limits) || IbkrApi.Config.default_rate_limits()
    bucket_prefix = Keyword.get(opts, :bucket_prefix, "")
    limit_config = get_rate_limit(rate_limits, endpoint)

    case RateLimit.hit(
      "#{bucket_prefix}#{endpoint}",
      limit_config.time_window_ms,
      limit_config.limit
    ) do
      {:allow, _count} -> :ok
      {:deny, _limit} ->
        Logger.warning("Endpoint rate limit exceeded for #{endpoint}: #{inspect(limit_config)}")
        {:error, :rate_limit_exceeded}
    end
  end

  @doc """
  Extracts the endpoint name from a URL path.

  Examples:
    "/iserver/marketdata/snapshot" -> "iserver_marketdata_snapshot"
    "/iserver/scanner/run" -> "iserver_scanner_run"
  """
  @spec extract_endpoint(binary) :: atom
  def extract_endpoint(url_path) when is_binary(url_path) do
    url_path
    |> String.trim_leading("/")
    |> String.replace("/", "_")
    |> String.replace(~r/\/\d+/, "")  # Replace numeric IDs with empty string
    |> String.to_atom()
  end

  @doc """
  Executes a function with rate limiting.

  Returns the function result if the rate limit allows the request,
  or `{:error, error_message}` if the rate limit is exceeded.
  """
  @spec with_rate_limit(binary, keyword, function) :: any | {:error, any}
  def with_rate_limit(url_path, opts \\ [], fun) do
    opts = NimbleOptions.validate!(opts, @options_schema)

    case check_rate(url_path, opts) do
      :ok ->
        fun.()
      {:error, :rate_limit_exceeded} ->
        {:error, ErrorMessage.too_many_requests("Too Many Requests", %{url_path: url_path})}
    end
  end

  # Private helper to get rate limit from keyword list config
  defp get_rate_limit(rate_limits, :global) when is_list(rate_limits) do
    global_config = Keyword.get(rate_limits, :global, [])
    %{
      limit: Keyword.get(global_config, :limit, 50),
      time_window_ms: Keyword.get(global_config, :time_window_ms, 1_000)
    }
  end

  defp get_rate_limit(rate_limits, endpoint) when is_list(rate_limits) do
    endpoints_config = Keyword.get(rate_limits, :endpoints, [])
    endpoint_config = Keyword.get(endpoints_config, endpoint, [])

    %{
      limit: Keyword.get(endpoint_config, :limit, 10),
      time_window_ms: Keyword.get(endpoint_config, :time_window_ms, 1_000)
    }
  end
end
