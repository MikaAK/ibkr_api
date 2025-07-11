defmodule IbkrApi.Config do
  @moduledoc """
  Configuration settings for the IBKR API client.
  
  This module provides functions to access configuration values with sensible defaults.
  Values can be overridden in your application configuration.
  
  ## Example Configuration
  
  ```elixir
  config :ibkr_api,
    host: "https://localhost",
    port: "5050",
    rate_limits: [
      global: [limit: 45, time_window_ms: 1_000],
      endpoints: [
        iserver_marketdata_snapshot: [limit: 9, time_window_ms: 1_000],
        # ... other endpoint-specific limits
      ]
    ]
  ```
  """
  
  # Rate limiting configuration schema
  @rate_limit_schema [
    limit: [
      type: :pos_integer,
      required: true,
      doc: "Maximum number of requests allowed in the time window"
    ],
    time_window_ms: [
      type: :pos_integer,
      required: true,
      doc: "Time window in milliseconds for the rate limit"
    ]
  ]
  
  @rate_limits_schema [
    global: [
      type: :keyword_list,
      required: true,
      keys: @rate_limit_schema,
      doc: "Global rate limit configuration that applies to all requests"
    ],
    endpoints: [
      type: :keyword_list,
      default: [],
      keys: [
        *: [
          type: :keyword_list,
          keys: @rate_limit_schema,
          doc: "Endpoint-specific rate limit configuration"
        ]
      ],
      doc: "Per-endpoint rate limit configurations"
    ]
  ]

  @doc """
  Returns the base URL for the IBKR API.
  """
  def base_url do
    "#{host()}:#{port()}/v1/api"
  end

  @doc """
  Returns the configured host or the default value.
  """
  def host do
    Application.get_env(:ibkr_api, :host, "https://localhost")
  end

  @doc """
  Returns the configured port or the default value.
  """
  def port do
    Application.get_env(:ibkr_api, :port, "5050")
  end

  @doc """
  Returns the rate limiting configuration.

  Rate limits can be configured via application environment:

      config :ibkr_api, :rate_limits,
        global: [limit: 50, time_window_ms: 1_000],
        endpoints: [
          iserver_marketdata_snapshot: [limit: 10, time_window_ms: 1_000],
          iserver_scanner_run: [limit: 1, time_window_ms: 1_000]
        ]

  If no configuration is provided, defaults are returned.
  """
  @spec rate_limit() :: keyword()
  def rate_limit do
    user_config = Application.get_env(:ibkr_api, :rate_limits, [])
    
    case validate_rate_limits(user_config) do
      {:ok, validated_config} ->
        validated_config
      {:error, error} ->
        require Logger
        Logger.error("Invalid rate limit configuration: #{inspect(error)}. Using defaults.")
        default_rate_limits()
    end
  end

  @doc """
  Validates the rate limit configuration.

  Returns `{:ok, validated_config}` if the configuration is valid,
  or `{:error, error}` if the configuration is invalid.
  """
  @spec validate_rate_limits(keyword()) :: {:ok, keyword()} | {:error, any()}
  def validate_rate_limits(config) do
    NimbleOptions.validate(config, @rate_limits_schema)
  end

  @doc """
  Returns the default rate limit configuration.
  """
  @spec default_rate_limits() :: keyword()
  def default_rate_limits do
    [
      global: [limit: 50, time_window_ms: 1_000],
      endpoints: [
        # Gateway default: 10 requests per second
        gateway: [limit: 10, time_window_ms: 1_000],
        
        # Endpoint-specific defaults based on IBKR documentation
        iserver_marketdata_snapshot: [limit: 10, time_window_ms: 1_000],
        iserver_scanner_params: [limit: 1, time_window_ms: 15 * 60_000],
        iserver_scanner_run: [limit: 1, time_window_ms: 1_000],
        iserver_trades: [limit: 1, time_window_ms: 5_000],
        iserver_orders: [limit: 1, time_window_ms: 5_000],
        iserver_account_pnl_partitioned: [limit: 1, time_window_ms: 5_000],
        portfolio_accounts: [limit: 1, time_window_ms: 5_000],
        portfolio_subaccounts: [limit: 1, time_window_ms: 5_000],
        pa_performance: [limit: 1, time_window_ms: 15 * 60_000],
        pa_summary: [limit: 1, time_window_ms: 15 * 60_000],
        pa_transactions: [limit: 1, time_window_ms: 15 * 60_000],
        fyi_unreadnumber: [limit: 1, time_window_ms: 1_000],
        fyi_settings: [limit: 1, time_window_ms: 1_000],
        fyi_settings_typecode: [limit: 1, time_window_ms: 1_000],
        fyi_disclaimer_typecode: [limit: 1, time_window_ms: 1_000],
        fyi_deliveryoptions: [limit: 1, time_window_ms: 1_000],
        fyi_deliveryoptions_email: [limit: 1, time_window_ms: 1_000],
        fyi_deliveryoptions_device: [limit: 1, time_window_ms: 1_000],
        fyi_deliveryoptions_deviceId: [limit: 1, time_window_ms: 1_000],
        fyi_notifications: [limit: 1, time_window_ms: 1_000],
        fyi_notifications_more: [limit: 1, time_window_ms: 1_000],
        fyi_notifications_notificationId: [limit: 1, time_window_ms: 1_000],
        tickle: [limit: 1, time_window_ms: 1_000],
        sso_validate: [limit: 1, time_window_ms: 60_000]
      ]
    ]
  end

  @doc """
  Returns the rate limit configuration for a specific endpoint or global limit.

  ## Parameters
    - key: Atom representing either `:global` or an endpoint name like `:iserver_marketdata_snapshot`

  ## Returns
    - %{limit: integer, time_window_ms: integer} containing rate limit configuration
  """
  def rate_limit(key) when is_atom(key) do
    config = rate_limit()
    
    if key === :global do
      Map.new(config[:global])
    else
      endpoints = config[:endpoints] || []
      endpoint_config = Keyword.get(endpoints, key)
      
      if endpoint_config do
        Map.new(endpoint_config)
      else
        # Fall back to global limit if endpoint not configured
        Map.new(config[:global])
      end
    end
  end
end
