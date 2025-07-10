defmodule IbkrApi.Support.HTTPStubs.MarketDataStub do
  @moduledoc """
  Stub module for IbkrApi.ClientPortal.MarketData HTTP requests.
  """
  
  alias IbkrApi.Support.HTTPMock
  alias IbkrApi.Support.HTTPSandbox

  @base_url "https://localhost:5050/v1/api"
  
  @doc """
  Stubs the get_historical_data endpoint.
  
  ## Examples
      
      MarketDataStub.stub_get_historical_data()
      # Or with custom response:
      MarketDataStub.stub_get_historical_data(fn -> HTTPMock.success(%{"data" => [...custom bars...]}) end)
  """
  def stub_get_historical_data(response_fn \\ nil) do
    url_pattern = ~r{#{@base_url}/iserver/marketdata/history.*}
    
    default_fn = fn ->
      HTTPMock.success(%{
        "symbol" => "AAPL",
        "text" => "APPLE INC",
        "priceFactor" => 1,
        "chartVersion" => 2,
        "data" => [
          %{
            "o" => 150.25,
            "c" => 151.75,
            "h" => 152.30,
            "l" => 149.80,
            "v" => 450000,
            "t" => 1720021800
          },
          %{
            "o" => 151.75,
            "c" => 153.00,
            "h" => 153.50,
            "l" => 151.00,
            "v" => 380000,
            "t" => 1720025400
          },
          %{
            "o" => 153.00,
            "c" => 152.50,
            "h" => 153.75,
            "l" => 152.00,
            "v" => 420000,
            "t" => 1720029000
          }
        ],
        "points" => 3,
        "travelTime" => 42
      })
    end
    
    HTTPSandbox.set_get_responses([{url_pattern, response_fn || default_fn}])
  end
  
  @doc """
  Stubs the live_market_data_snapshots endpoint.
  
  ## Examples
      
      MarketDataStub.stub_live_market_data_snapshots()
      # Or with custom response:
      MarketDataStub.stub_live_market_data_snapshots(HTTPMock.success([...custom market data...]))
  """
  def stub_live_market_data_snapshots(response_fn \\ nil) do
    url_pattern = ~r{#{@base_url}/iserver/marketdata/snapshot.*}
    
    default_fn = fn ->
      HTTPMock.success([
        %{
          "conid" => 265598,
          "31" => "APPLE INC",
          "55" => "NASDAQ",
          "6004" => "AAPL",
          "6008" => "STK",
          "7057" => "SMART",
          "7059" => "STK",
          "7068" => "USD",
          "71" => 152.50,
          "82" => 152.50,
          "83" => 152.53,
          "84" => 152.48,
          "85" => 152.50,
          "86" => 152.51,
          "88" => 152.51,
          "6070" => 100,
          "6072" => 200,
          "6073" => 1720029300,
          "high" => 153.75,
          "low" => 149.80,
          "open" => 150.25,
          "close" => 152.50,
          "volume" => 1250000,
          "bid_size" => 100,
          "ask_size" => 200
        }
      ])
    end
    
    HTTPSandbox.set_get_responses([{url_pattern, response_fn || default_fn}])
  end
end