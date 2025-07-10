defmodule IbkrApi.ClientPortal.TradeTest do
  use ExUnit.Case
  
  alias IbkrApi.ClientPortal.Trade
  alias IbkrApi.Support.HTTPMock
  alias IbkrApi.Support.HTTPStubs.TradeStub

  describe "list_trades/0" do
    test "returns trades with default mock" do
      # Mock the list_trades HTTP call with default response
      TradeStub.stub_list_trades()
      
      # Call the function
      assert {:ok, trades} = Trade.list_trades()
      
      # Verify response
      assert length(trades) == 1
      trade = List.first(trades)
      assert trade.symbol == "AAPL"
      assert trade.side == "BUY"
      assert trade.size == 100
    end
    
    test "returns custom trades with custom mock" do
      # Create a custom response
      custom_trades = [
        %{
          "execution_id" => "0000999988887777",
          "symbol" => "MSFT",
          "side" => "SELL",
          "order_description" => "SOLD -50 MSFT @300.50",
          "trade_time" => "20250710-10:15:45",
          "trade_time_r" => 1720025745,
          "size" => 50,
          "price" => 300.50,
          "order_ref" => "api-654321",
          "submitter" => "API",
          "exchange" => "NASDAQ",
          "commission" => 1.00,
          "net_amount" => 15025.0,
          "account" => "U12345678",
          "account_id" => "U12345678",
          "contract_description_1" => "MICROSOFT CORP",
          "contract_id" => 272093,
          "position" => "-50"
        }
      ]
      
      # Use the custom response in the mock
      TradeStub.stub_list_trades(fn -> HTTPMock.success(custom_trades) end)
      
      # Call the function
      assert {:ok, trades} = Trade.list_trades()
      
      # Verify custom response
      assert length(trades) == 1
      trade = List.first(trades)
      assert trade.symbol == "MSFT"
      assert trade.side == "SELL"
      assert trade.size == 50
      assert trade.price == 300.50
    end
    
    test "handles error response" do
      # Mock an error response
      error_response = %{"error" => "Unable to retrieve trades", "code" => 1234}
      TradeStub.stub_list_trades(fn -> HTTPMock.error(error_response, 400) end)
      
      # Call the function
      assert {:error, _error} = Trade.list_trades()
    end
    
    test "handles network error" do
      # Mock a network error
      TradeStub.stub_list_trades(fn -> HTTPMock.network_error(:timeout) end)
      
      # Call the function
      assert {:error, :timeout} = Trade.list_trades()
    end
  end
end