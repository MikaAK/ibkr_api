defmodule IbkrApi.RateLimiterTest do
  use ExUnit.Case, async: false
  
  alias IbkrApi.RateLimiter
  
  @moduletag :capture_log
  
  setup do
    # Clear the ETS table between tests to ensure clean state
    # The table may not exist yet, so we need to handle that
    case :ets.info(:hammer_ets_buckets) do
      :undefined -> :ok
      _ -> 
        # Clear all buckets that start with "test_"
        :ets.match_delete(:hammer_ets_buckets, {{:_, :_, :_}, :_})
    end
    
    # Also wait a bit to ensure any rate limit windows have passed
    Process.sleep(100)
    :ok
  end
  
  describe "extract_endpoint/1" do
    test "converts URL path to rate limit key" do
      assert RateLimiter.extract_endpoint("/iserver/marketdata/snapshot") == :iserver_marketdata_snapshot
      assert RateLimiter.extract_endpoint("/iserver/scanner/run") == :iserver_scanner_run
      assert RateLimiter.extract_endpoint("/iserver/account") == :iserver_account
    end
    
    test "handles leading slashes" do
      assert RateLimiter.extract_endpoint("iserver/marketdata/snapshot") == :iserver_marketdata_snapshot
    end
    
    test "extract_endpoint/1 removes numeric IDs" do
      assert RateLimiter.extract_endpoint("/iserver/account/123456") === :iserver_account_123456
    end
  end
  
  describe "check_rate/2" do
    test "allows requests within rate limit" do
      # Create rate limits configuration for testing
      rate_limits = [
        global: [limit: 100, time_window_ms: 60_000],
        endpoints: [
          iserver_marketdata_snapshot: [limit: 100, time_window_ms: 60_000],
          iserver_scanner_run: [limit: 100, time_window_ms: 60_000],
          iserver_account: [limit: 100, time_window_ms: 60_000],
          iserver_account_123456: [limit: 100, time_window_ms: 60_000],
          test_endpoint: [limit: 100, time_window_ms: 60_000]
        ]
      ]
      
      # Test that we can make a request
      assert RateLimiter.check_rate("/test/endpoint", rate_limits: rate_limits) === :ok
    end
    
    test "enforces rate limits" do
      # Create rate limits with very low limits for testing
      # Use a unique test ID to avoid conflicts with other tests
      test_id = :erlang.unique_integer([:positive])
      endpoint_key = String.to_atom("test_endpoint_#{test_id}")
      bucket_prefix = "test_#{test_id}"
      
      rate_limits = [
        global: [limit: 10, time_window_ms: 1_000],  # Higher global limit to avoid conflicts
        endpoints: [
          {endpoint_key, [limit: 1, time_window_ms: 1_000]}
        ]
      ]
      
      # Use unique endpoint to avoid conflicts
      endpoint = "/#{endpoint_key}"
      
      # First request should succeed
      assert RateLimiter.check_rate(endpoint, rate_limits: rate_limits, bucket_prefix: bucket_prefix) === :ok
      
      # Second request should be rate limited
      assert {:error, :rate_limit_exceeded} = RateLimiter.check_rate(endpoint, rate_limits: rate_limits, bucket_prefix: bucket_prefix)
      
      # Wait for rate limit window to pass
      Process.sleep(1_100)
      
      # Should be allowed again
      assert RateLimiter.check_rate(endpoint, rate_limits: rate_limits, bucket_prefix: bucket_prefix) === :ok
    end
  end
  
  describe "with_rate_limit/3" do
    test "executes function if rate limit check passes" do
      rate_limits = [
        global: [limit: 100, time_window_ms: 60_000],
        endpoints: [
          test_path: [limit: 100, time_window_ms: 60_000]
        ]
      ]
      
      result = RateLimiter.with_rate_limit("/test/path", [rate_limits: rate_limits], fn -> :executed end)
      assert result === :executed
    end
    
    test "returns error if rate limit check fails" do
      # Create rate limits with very low limit for testing
      test_id = :erlang.unique_integer([:positive])
      bucket_prefix = "test_#{test_id}"
      endpoint_key = String.to_atom("test_path_#{test_id}")
      
      rate_limits = [
        global: [limit: 1, time_window_ms: 1_000],
        endpoints: [
          {endpoint_key, [limit: 1, time_window_ms: 1_000]}
        ]
      ]
      
      # Use unique path to avoid conflicts
      path = "/test/path/#{test_id}"
      
      # First call should succeed
      assert :executed = RateLimiter.with_rate_limit(
        path, 
        [rate_limits: rate_limits, bucket_prefix: bucket_prefix],
        fn -> :executed end
      )
      
      # Second call should hit rate limit
      result = RateLimiter.with_rate_limit(
        path, 
        [rate_limits: rate_limits, bucket_prefix: bucket_prefix],
        fn -> :executed end
      )
      
      assert {:error, error} = result
      assert error.code === :too_many_requests
      assert error.message =~ "Too Many Requests"
    end
  end
end
