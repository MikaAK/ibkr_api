defmodule IbkrApi.MockConfig do
  @moduledoc """
  Mock configuration module for testing rate limiting with custom configurations.
  """

  def new(rate_limits \\ []) do
    %{rate_limits: rate_limits}
  end

  def rate_limit(%{rate_limits: rate_limits}, :global) do
    global_config = Keyword.get(rate_limits, :global, [limit: 50, time_window_ms: 1_000])
    
    %{
      limit: Keyword.get(global_config, :limit, 50),
      time_window_ms: Keyword.get(global_config, :time_window_ms, 1_000)
    }
  end

  def rate_limit(%{rate_limits: rate_limits}, endpoint) do
    endpoint_config = Keyword.get(rate_limits, endpoint, [limit: 10, time_window_ms: 1_000])
    
    %{
      limit: Keyword.get(endpoint_config, :limit, 10),
      time_window_ms: Keyword.get(endpoint_config, :time_window_ms, 1_000)
    }
  end
end
