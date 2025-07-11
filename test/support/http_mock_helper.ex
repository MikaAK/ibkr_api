defmodule IbkrApi.Support.HTTPMockHelper do
  @moduledoc """
  Helper module for using HTTP mocks in tests.

  **DEPRECATED**: This module is deprecated in favor of using HTTPSandbox and the explicit stub modules.

  Use the stub modules directly instead:

  ```elixir
  alias IbkrApi.Support.HTTPStubs.{AuthStub, TradeStub, ContractStub, MarketDataStub, PortfolioStub, OrderStub}

  # Register stubs in your test
  test "example test" do
    AuthStub.stub_auth_status()
    TradeStub.stub_list_trades()
    
    # Make your assertions
  end
  ```

  See the documentation in guides/how-to/testing_with_http_mocks.md for more details.

  @deprecated "Use HTTPSandbox and explicit stub modules instead"
  """
  
  # Alias removed - HTTPSandbox is now the preferred approach
  # alias IbkrApi.SharedUtils.HTTP
  
  @doc """
  Macro that imports the helper functions for HTTP mocking.
  """
  defmacro __using__(_opts) do
    quote do
      import IbkrApi.Support.HTTPMockHelper
      
      setup do
        # Reset all mocks before each test
        reset_http_mocks()
        :ok
      end
    end
  end

  @doc """
  Mocks an HTTP function for a specific module.
  
  ## Parameters
  - module_key: The module key (:auth, :trade, :contract, :market_data, :portfolio, :order)
  - function_name: The name of the stub function to use (e.g. :stub_list_trades)
  - custom_response: Optional custom response function
  
  ## Examples
      mock_http(:trade, :stub_list_trades)
      mock_http(:auth, :stub_auth_status, my_custom_response_fn)
  """
  def mock_http(module_key, function_name, custom_response \\ nil)
  
  def mock_http(module_list, _, _) when is_list(module_list) do
    Enum.each(module_list, fn {module_key, function_name} ->
      mock_http(module_key, function_name)
    end)
  end
  
  def mock_http(:auth, function_name, custom_response) do
    mock_module_function(IbkrApi.Support.HTTPMocks.Auth, function_name, custom_response)
  end
  
  def mock_http(:trade, function_name, custom_response) do
    mock_module_function(IbkrApi.Support.HTTPMocks.Trade, function_name, custom_response)
  end
  
  def mock_http(:contract, function_name, custom_response) do
    mock_module_function(IbkrApi.Support.HTTPMocks.Contract, function_name, custom_response)
  end
  
  def mock_http(:market_data, function_name, custom_response) do
    mock_module_function(IbkrApi.Support.HTTPMocks.MarketData, function_name, custom_response)
  end
  
  def mock_http(:portfolio, function_name, custom_response) do
    mock_module_function(IbkrApi.Support.HTTPMocks.Portfolio, function_name, custom_response)
  end
  
  def mock_http(:order, function_name, custom_response) do
    mock_module_function(IbkrApi.Support.HTTPMocks.Order, function_name, custom_response)
  end
  
  defp mock_module_function(module, function_name, custom_response) do
    response_fn = if custom_response, do: custom_response, else: apply(module, function_name, [])
    
    # Map function names to HTTP methods
    http_method = function_name_to_http_method(function_name)
    
    # Apply the mock
    apply_mock(http_method, response_fn)
  end
  
  defp function_name_to_http_method(function_name) do
    cond do
      String.contains?(Atom.to_string(function_name), "delete") -> :delete
      String.contains?(Atom.to_string(function_name), "post") || 
      String.contains?(Atom.to_string(function_name), "place") || 
      String.contains?(Atom.to_string(function_name), "create") || 
      String.contains?(Atom.to_string(function_name), "modify") || 
      String.contains?(Atom.to_string(function_name), "update") -> :post
      String.contains?(Atom.to_string(function_name), "put") -> :put
      true -> :get
    end
  end
  
  defp apply_mock(:get, _response_fn) do
    IO.warn(":meck has been replaced with HTTPSandbox - use explicit stub modules instead")
    # Fallback implementation that logs but doesn't fail
    # This is just to prevent errors during transition
  end
  
  defp apply_mock(:post, _response_fn) do
    IO.warn(":meck has been replaced with HTTPSandbox - use explicit stub modules instead")
    # Fallback implementation that logs but doesn't fail
  end
  
  defp apply_mock(:put, _response_fn) do
    IO.warn(":meck has been replaced with HTTPSandbox - use explicit stub modules instead")
    # Fallback implementation that logs but doesn't fail
  end
  
  defp apply_mock(:delete, _response_fn) do
    IO.warn(":meck has been replaced with HTTPSandbox - use explicit stub modules instead")
    # Fallback implementation that logs but doesn't fail
  end
  
  @doc """
  Reset all HTTP mocks to their original implementations.
  
  @deprecated "Use HTTPSandbox.reset() instead"
  """
  def reset_http_mocks do
    IO.warn(":meck has been replaced with HTTPSandbox - use HTTPSandbox.reset() instead")
    # No-op implementation to avoid errors
  end
end