defmodule IbkrApi.HTTP do
  @moduledoc """
  HTTP client for the Interactive Brokers Client Portal API with rate limiting.

  This module provides functions to make rate-limited HTTP requests to the IBKR API.
  Rate limits are enforced both globally and per-endpoint according to IBKR's documentation.
  """

  alias IbkrApi.{SharedUtils, RateLimiter}

  require Logger

  @app_name :ibkr_http

  @default_opts [
    name: @app_name,
    atomize_keys?: true,
    # follow_redirects?: true,

    pools: [
      default: [
        size: 10,
        count: 10,
        conn_max_idle_time: 500,
        conn_opts: [transport_opts: [
          verify: :verify_none,
          timeout: :timer.seconds(5)
        ]]
      ]
    ]
  ]

  @doc """
  Returns a child specification for the HTTP client.
  """
  def child_spec(opts) do
    SharedUtils.HTTP.child_spec({@app_name, Keyword.merge(@default_opts, opts)})
  end

  @doc """
  Makes a rate-limited GET request to the specified URL.

  ## Parameters
    - url: The URL to request
    - headers: HTTP headers to include
    - opts: Additional options
  """
  def get(url, headers \\ [], opts \\ []) do
    with_rate_limiting(url, fn ->
      url
        |> SharedUtils.HTTP.get(add_default_headers(headers), Keyword.merge(opts, @default_opts))
        |> handle_response()
    end)
  end

  @doc """
  Makes a rate-limited POST request to the specified URL.

  ## Parameters
    - url: The URL to request
    - body: The request body
    - headers: HTTP headers to include
    - opts: Additional options
  """
  def post(url, body, headers \\ [], opts \\ []) do
    with_rate_limiting(url, fn ->
      url
        |> SharedUtils.HTTP.post(body, add_default_headers(headers), Keyword.merge(opts, @default_opts))
        |> handle_response()
    end)
  end

  @doc """
  Makes a rate-limited DELETE request to the specified URL.

  ## Parameters
    - url: The URL to request
    - headers: HTTP headers to include
    - opts: Additional options
  """
  def delete(url, headers \\ [], opts \\ []) do
    with_rate_limiting(url, fn ->
      url
        |> SharedUtils.HTTP.delete(add_default_headers(headers), Keyword.merge(opts, @default_opts))
        |> handle_response()
    end)
  end

  @doc """
  Makes a rate-limited PUT request to the specified URL.

  ## Parameters
    - url: The URL to request
    - body: The request body
    - headers: HTTP headers to include
    - opts: Additional options
  """
  def put(url, body, headers \\ [], opts \\ []) do
    with_rate_limiting(url, fn ->
      url
        |> SharedUtils.HTTP.put(body, add_default_headers(headers), Keyword.merge(opts, @default_opts))
        |> handle_response()
    end)
  end

  @doc """
  Extracts the API path from a URL.
  """
  def extract_path(url) when is_binary(url) do
    case URI.parse(url) do
      %URI{path: path} when is_binary(path) -> path
      _ -> url
    end
  end

  @doc """
  Applies rate limiting to the given function based on the URL.
  """
  def with_rate_limiting(url, func) when is_function(func, 0) do
    path = extract_path(url)
    RateLimiter.with_rate_limit(path, func)
  end

  defp add_default_headers(headers), do: [{"Content-Type", "application/json"} | headers]

  defp handle_response({:ok, {decoded_body, _raw_response}}) do
    {:ok, decoded_body}
  end

  defp handle_response({:error, _} = error) do
    error
  end
end
