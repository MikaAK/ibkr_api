defmodule IbkrApi.ClientPortal.MarketDataTest do
  use ExUnit.Case
  
  alias IbkrApi.ClientPortal.MarketData
  alias IbkrApi.Support.HTTPMock
  alias IbkrApi.Support.HTTPStubs.MarketDataStub

  setup do
    # Clear the HTTPSandbox registry before each test
    IbkrApi.Support.HTTPSandbox.clear()
    :ok
  end

  describe "get_historical_data/4" do
    test "returns historical data with default mock" do
      # Define test params
      conid = "265598"
      period = "1d"
      bar = "1h"
      
      # Set up the default mock
      MarketDataStub.stub_get_historical_data()
      
      # Call the function
      assert {:ok, data} = MarketData.get_historical_data(conid, period, bar)
      
      # Verify the response
      assert is_list(data)
      assert length(data) > 0
      
      # Check that we have at least one bar and it has the expected fields
      first_bar = Enum.at(data, 0)
      assert %IbkrApi.ClientPortal.MarketData.HistoricalBar{} = first_bar
      # Assert fields are present
      assert is_number(first_bar.open)
      assert is_number(first_bar.close)
      assert is_number(first_bar.high)
      assert is_number(first_bar.low)
      assert is_number(first_bar.volume)
      assert %DateTime{} = first_bar.timestamp  # timestamp
    end
    
    test "returns custom historical data with custom mock" do
      conid = "265598"
      period = "1d"
      bar = "1h"
      
      # Create custom data
      custom_data = %{
        "data" => [
          %{
            "o" => 150.25,
            "c" => 151.75,
            "h" => 152.00,
            "l" => 150.00,
            "v" => 1000000,
            "t" => 1609459200000
          },
          %{
            "o" => 151.75,
            "c" => 153.50,
            "h" => 154.00,
            "l" => 151.50,
            "v" => 1200000,
            "t" => 1609462800000
          }
        ]
      }
      
      # Use custom response in the mock
      MarketDataStub.stub_get_historical_data(fn -> HTTPMock.success(custom_data) end)
      
      # Call the function
      assert {:ok, data} = MarketData.get_historical_data(conid, period, bar)
      
      # Check that our data has the correct values
      first_bar = Enum.at(data, 0)
      assert first_bar.open == 150.25
      assert first_bar.close == 151.75
      assert first_bar.high == 152.0
      assert first_bar.low == 150.0
      assert first_bar.volume == 1_000_000
    end
    
    test "handles error response" do
      conid = "invalid_id"
      period = "1d"
      bar = "1h"
      
      # Mock an error response
      error_response = %{"error" => "Invalid conid", "code" => 400}
      MarketDataStub.stub_get_historical_data(fn -> HTTPMock.error(error_response, 400) end)
      
      # Call the function
      assert {:error, _error_message} = MarketData.get_historical_data(conid, period, bar)
    end
    
    test "handles network error" do
      conid = "265598"
      period = "1d"
      bar = "1h"
      
      # Mock a network error
      MarketDataStub.stub_get_historical_data(fn -> HTTPMock.network_error(:timeout) end)
      
      # Call the function
      assert {:error, :timeout} = MarketData.get_historical_data(conid, period, bar)
    end
  end
  
  describe "live_market_data_snapshots/2" do
    test "returns market snapshot with default mock" do
      # Define test params
      conids = ["265598", "8314"]
      fields = ["31", "84", "86"]
      
      # Set up the default mock
      MarketDataStub.stub_live_market_data_snapshots()
      
      # Call the function
      assert {:ok, snapshots, _response} = MarketData.live_market_data_snapshots(conids, fields: fields)
      
      # Verify the response
      assert is_list(snapshots)
      assert length(snapshots) > 0
      
      # Check the structure of the first snapshot
      first_snapshot = List.first(snapshots)
      assert Map.has_key?(first_snapshot, "conid")
      assert Map.has_key?(first_snapshot, "31")  # last price
    end
    
    test "returns custom market snapshot with custom mock" do
      conids = ["265598", "8314"]
      fields = ["31", "84", "86"]
      
      # Create custom data
      custom_snapshots = [
        %{
          "conid" => "265598",
          "31" => 150.75,  # last price
          "84" => 151.00,  # bid
          "86" => 150.50   # ask
        },
        %{
          "conid" => "8314",
          "31" => 3500.25, # last price
          "84" => 3501.00, # bid
          "86" => 3500.00  # ask
        }
      ]
      
      # Use custom response in the mock
      MarketDataStub.stub_live_market_data_snapshots(fn -> HTTPMock.success(custom_snapshots) end)
      
      # Call the function
      assert {:ok, snapshots, _response} = MarketData.live_market_data_snapshots(conids, fields: fields)
      
      # Verify custom response
      assert length(snapshots) == 2
      assert Enum.at(snapshots, 0)["conid"] == "265598"
      assert Enum.at(snapshots, 1)["conid"] == "8314"
    end
  end
  
  test "market data workflow with multiple endpoint mocks" do
    # Set up multiple stubs for a workflow test
    MarketDataStub.stub_get_historical_data()
    MarketDataStub.stub_live_market_data_snapshots()
    
    # First get historical data
    conid = "265598"
    period = "1d"
    bar = "1h"
    
    assert {:ok, hist_data} = MarketData.get_historical_data(conid, period, bar)
    assert is_list(hist_data)
    
    # Then get current market snapshot
    conids = [conid]
    fields = ["31", "84", "86"]
    
    MarketDataStub.stub_live_market_data_snapshots()
    assert {:ok, snapshots, _response} = MarketData.live_market_data_snapshots(conids, fields: fields)
    assert is_list(snapshots)
    
    snapshot = List.first(snapshots)
    assert to_string(snapshot["conid"]) == conid
  end
end
