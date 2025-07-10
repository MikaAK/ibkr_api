defmodule IbkrApi.Support.HTTPMockHelper do
  @moduledoc """
  Helper module for using HTTP mocks in tests.
  
  This module provides a simple interface for mocking HTTP responses in tests.
  It allows you to easily stub responses for HTTP calls in the IBKR Client Portal API.
  
  ## Examples
  
      # Mock a single function
      test "list_trades returns trades", %{conn: conn} do
        use IbkrApi.Support.HTTPMockHelper
        
        mock_http(:trade, :stub_list_trades)
        
        assert {:ok, trades} = IbkrApi.ClientPortal.Trade.list_trades()
        assert length(trades) > 0
      end
      
      # Mock a function with custom response
      test "list_trades with custom response", %{conn: conn} do
        use IbkrApi.Support.HTTPMockHelper
        
        custom_trades = [%{"symbol" => "MSFT", "side" => "BUY", "size" => 200}]
        mock_http(:trade, :stub_list_trades, IbkrApi.Support.HTTPMock.success(custom_trades))
        
        assert {:ok, trades} = IbkrApi.ClientPortal.Trade.list_trades()
        assert length(trades) == 1
        assert hd(trades).symbol == "MSFT"
      end
      
      # Mock multiple functions
      test "multiple mocks", %{conn: conn} do
        use IbkrApi.Support.HTTPMockHelper
        
        mock_http([
          {:auth, :stub_auth_status},
          {:trade, :stub_list_trades}
        ])
        
        # Test code using both mocks
      end
  """
  
  alias IbkrApi.SharedUtils.HTTP
  
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
  
  defp apply_mock(:get, response_fn) do
    :meck.expect(HTTP, :get, response_fn)
  end
  
  defp apply_mock(:post, response_fn) do
    :meck.expect(HTTP, :post, response_fn)
  end
  
  defp apply_mock(:put, response_fn) do
    :meck.expect(HTTP, :put, response_fn)
  end
  
  defp apply_mock(:delete, response_fn) do
    :meck.expect(HTTP, :delete, response_fn)
  end
  
  @doc """
  Reset all HTTP mocks to their original implementations.
  """
  def reset_http_mocks do
    :meck.unload(HTTP)
  end
end