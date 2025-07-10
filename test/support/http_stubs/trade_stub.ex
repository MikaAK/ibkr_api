defmodule IbkrApi.Support.HTTPStubs.TradeStub do
  @moduledoc """
  Stub module for IbkrApi.ClientPortal.Trade HTTP requests.
  """
  
  alias IbkrApi.Support.HTTPMock
  alias IbkrApi.Support.HTTPSandbox

  @base_url "https://localhost:5000/v1/api"
  
  @doc """
  Stubs the list_trades endpoint.
  
  ## Examples
      
      TradeStub.stub_list_trades()
      # Or with custom response:
      TradeStub.stub_list_trades(HTTPMock.success([%{"symbol" => "MSFT", "side" => "SELL", "size" => 50}]))
  """
  def stub_list_trades(response_fn \\ nil) do
    url = "#{@base_url}/iserver/account/trades"
    
    default_fn = fn ->
      HTTPMock.success([%{
        "execution_id" => "0000111122223333",
        "symbol" => "AAPL",
        "side" => "BUY",
        "order_description" => "BOT +100 AAPL @150.25",
        "trade_time" => "20250710-09:30:15",
        "trade_time_r" => 1720021815,
        "size" => 100,
        "price" => 150.25,
        "order_ref" => "api-123456",
        "submitter" => "API",
        "exchange" => "NASDAQ",
        "commission" => 1.00,
        "net_amount" => 15025.0,
        "account" => "U12345678",
        "account_id" => "U12345678",
        "contract_description_1" => "APPLE INC",
        "contract_id" => 265598,
        "position" => "100"
      }])
    end
    
    HTTPSandbox.set_get_responses([{url, response_fn || default_fn}])
  end
end