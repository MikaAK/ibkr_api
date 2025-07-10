# IBKR API Test Support

This directory contains test helpers and mocks for testing the IBKR API client.

## HTTP Mocks

The HTTP mock system provides easy-to-use mocks for all the HTTP calls made by the IBKR API client.
It allows you to test your code that uses the IBKR API without making actual API calls.

### Usage

#### Basic Usage

```elixir
defmodule YourTest do
  use ExUnit.Case

  alias IbkrApi.ClientPortal.Trade
  alias IbkrApi.Support.HTTPStubs.TradeStub

  setup do
    # Clear any existing responses before each test
    IbkrApi.Support.HTTPSandbox.clear()
    :ok
  end

  test "your test" do
    # Mock an endpoint with default response
    TradeStub.stub_list_trades()
    
    # Your test code that calls the API
    assert {:ok, trades} = Trade.list_trades()
    assert length(trades) > 0
  end
end
```

#### Custom Responses

```elixir
test "test with custom response" do
  # Create a custom response function
  custom_response = fn ->
    IbkrApi.Support.HTTPMock.success(%{
      "your" => "custom",
      "response" => "data"
    })
  end
  
  # Mock with custom response
  IbkrApi.Support.HTTPStubs.PortfolioStub.stub_account_summary(custom_response)
  
  # Test your code
  assert {:ok, result} = IbkrApi.ClientPortal.Portfolio.account_summary("U12345678")
end
```

#### Error Responses

```elixir
test "handles error responses" do
  # Mock an error response
  IbkrApi.Support.HTTPStubs.AuthStub.stub_auth_status(fn ->
    IbkrApi.Support.HTTPMock.error(%{"error" => "Unauthorized"}, 401)
  end)
  
  # Test your error handling
  assert {:error, error} = IbkrApi.ClientPortal.Auth.auth_status()
  assert error.status == 401
end
```

#### Network Errors

```elixir
test "handles network errors" do
  # Mock a network error
  IbkrApi.Support.HTTPStubs.MarketDataStub.stub_get_historical_data(fn ->
    IbkrApi.Support.HTTPMock.network_error(:timeout)
  end)
  
  # Test your error handling
  assert {:error, :timeout} = IbkrApi.ClientPortal.MarketData.get_historical_data(265598)
end
```

#### Multiple Stubs in One Test

```elixir
test "test with multiple mocks" do
  # Set up multiple stubs
  IbkrApi.Support.HTTPStubs.AuthStub.stub_auth_status()
  IbkrApi.Support.HTTPStubs.TradeStub.stub_list_trades()
  IbkrApi.Support.HTTPStubs.ContractStub.stub_contract_info()
  
  # Your test code that calls multiple endpoints
end
```

### Available Mocks

Here's a list of all available mocks organized by module:

#### Auth Module
- `:stub_reauthenticate` - Mocks the reauthentication endpoint
- `:stub_logout` - Mocks the logout endpoint
- `:stub_validate` - Mocks the validation endpoint
- `:stub_auth_status` - Mocks the authentication status endpoint
- `:stub_tickle` - Mocks the tickle endpoint

#### Trade Module
- `:stub_list_trades` - Mocks the list trades endpoint

#### Contract Module
- `:stub_contract_info` - Mocks the contract info endpoint
- `:stub_stocks_by_symbol` - Mocks the stocks by symbol endpoint
- `:stub_futures_by_symbol` - Mocks the futures by symbol endpoint
- `:stub_trading_schedule` - Mocks the trading schedule endpoint
- `:stub_search_by_symbol` - Mocks the search by symbol endpoint
- `:stub_exchange_rate` - Mocks the exchange rate endpoint
- `:stub_currency_pairs` - Mocks the currency pairs endpoint
- `:stub_secdef_by_conid` - Mocks the secdef by conid endpoint
- `:stub_search_contracts` - Mocks the search contracts endpoint
- `:stub_get_strikes` - Mocks the get strikes endpoint
- `:stub_symbol_info` - Mocks the symbol info endpoint
- `:stub_all_conids_by_exchange` - Mocks the all conids by exchange endpoint

#### Market Data Module
- `:stub_get_historical_data` - Mocks the historical data endpoint
- `:stub_get_market_snapshot` - Mocks the market snapshot endpoint

#### Portfolio Module
- `:stub_list_accounts` - Mocks the list accounts endpoint
- `:stub_list_sub_accounts` - Mocks the list sub accounts endpoint
- `:stub_list_sub_accounts_paginated` - Mocks the list sub accounts paginated endpoint
- `:stub_account_info` - Mocks the account info endpoint
- `:stub_account_summary` - Mocks the account summary endpoint
- `:stub_account_ledger` - Mocks the account ledger endpoint
- `:stub_list_brokerage_accounts` - Mocks the list brokerage accounts endpoint
- `:stub_switch_account` - Mocks the switch account endpoint
- `:stub_get_pnl` - Mocks the get pnl endpoint
- `:stub_account_allocation` - Mocks the account allocation endpoint
- `:stub_all_accounts_allocation` - Mocks the all accounts allocation endpoint
- `:stub_portfolio_positions` - Mocks the portfolio positions endpoint
- `:stub_position_by_conid` - Mocks the position by conid endpoint
- `:stub_invalidate_positions_cache` - Mocks the invalidate positions cache endpoint

#### Order Module
- `:stub_list_orders` - Mocks the list orders endpoint
- `:stub_get_order_status` - Mocks the get order status endpoint
- `:stub_modify_order` - Mocks the modify order endpoint
- `:stub_delete_order` - Mocks the delete order endpoint
- `:stub_what_if` - Mocks the what if endpoint
- `:stub_place_order` - Mocks the place order endpoint
- `:stub_place_order_for_fa_group` - Mocks the place order for FA group endpoint
- `:stub_place_order_reply` - Mocks the place order reply endpoint

### HTTPSandbox Registry

The `HTTPSandbox` module is the core of the HTTP mocking system. It provides a registry-based approach to store mock responses for HTTP requests:

```elixir
# How it works (you don't need to call these directly)
IbkrApi.Support.HTTPSandbox.set_get_responses([{url_or_pattern, response_fn}])
IbkrApi.Support.HTTPSandbox.set_post_responses([{url_or_pattern, response_fn}])
IbkrApi.Support.HTTPSandbox.set_put_responses([{url_or_pattern, response_fn}])
IbkrApi.Support.HTTPSandbox.set_delete_responses([{url_or_pattern, response_fn}])

# To clear mocks (useful in setup/teardown)
IbkrApi.Support.HTTPSandbox.clear()
```

### Response Helper Functions

The `HTTPMock` module provides helper functions for creating response functions:

```elixir
alias IbkrApi.Support.HTTPMock

# Create a success response
success_response = fn ->
  HTTPMock.success(
    %{"key" => "value"},           # Response body
    200,                          # Status code (optional, defaults to 200)
    [{"Content-Type", "application/json"}]  # Headers (optional)
  )
end

# Create an error response
error_response = fn ->
  HTTPMock.error(
    %{"error" => "Not found"},     # Error body
    404,                          # Status code (optional, defaults to 400)
    [{"Content-Type", "application/json"}]  # Headers (optional)
  )
end

# Create a network error
network_error = fn -> HTTPMock.network_error(:timeout) end  # :timeout, :closed, or any other atom
```

### Creating Your Own Custom Stubs

If you need to create stubs for your own API calls, you can follow this pattern:

```elixir
defmodule YourApp.Support.HTTPStubs.YourStub do
  alias IbkrApi.Support.HTTPMock
  alias IbkrApi.Support.HTTPSandbox

  @base_url "https://your-api-url.com"
  
  def stub_your_endpoint(response_fn \\ nil) do
    url = "#{@base_url}/your/endpoint"
    
    default_fn = fn ->
      HTTPMock.success(%{
        "data" => "your default mock data"
      })
    end
    
    HTTPSandbox.set_get_responses([{url, response_fn || default_fn}])
  end
end
```

## Running Tests with HTTPSandbox

To run tests with the HTTP sandbox, you need to:

1. Start the registry in `test_helper.exs`:
   ```elixir
   IbkrApi.Support.HTTPSandbox.start_link()
   ```

2. Set up the stubs in your tests:
   ```elixir
   setup do
     # Clear any existing responses
     IbkrApi.Support.HTTPSandbox.clear()
     :ok
   end
   ```

3. Run your tests with `mix test`