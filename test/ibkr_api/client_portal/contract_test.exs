defmodule IbkrApi.ClientPortal.ContractTest do
  use ExUnit.Case
  
  alias IbkrApi.ClientPortal.Contract
  alias IbkrApi.Support.HTTPMock
  alias IbkrApi.Support.HTTPStubs.ContractStub

  describe "search_contracts/2 and get_strikes/3" do
    test "can chain mocked API calls together" do
      # Mock both search_contracts and get_strikes endpoints
      ContractStub.stub_search_contracts()
      ContractStub.stub_get_strikes()
      
      # Test the combined workflow
      assert {:ok, search_results} = Contract.search_contracts("AAPL")
      assert length(search_results.sections) == 2
      
      # Find the option contract from search results
      option_section = Enum.find(search_results.sections, fn section -> section.sec_type == "OPT" end)
      assert option_section.conid == "265598"
      
      # Now use that contract ID to get strikes
      assert {:ok, strikes} = Contract.get_strikes(option_section.conid, "OPT", ~D[2025-08-15])
      
      # Verify strikes data
      assert strikes.call == ["140", "145", "150", "155", "160"]
      assert strikes.put == ["140", "145", "150", "155", "160"]
    end
    
    test "uses custom mock data for contract search" do
      # Create custom search response with different contract data
      custom_search_response = %{
        "sections" => [
          %{
            "secType" => "STK",
            "symbol" => "TSLA",
            "name" => "TESLA INC",
            "exchange" => "NASDAQ",
            "conid" => "76792991"
          },
          %{
            "secType" => "OPT",
            "months" => "JUL25 AUG25 OCT25",
            "symbol" => "TSLA",
            "name" => "TESLA INC",
            "exchange" => "NASDAQ",
            "conid" => "76792991"
          }
        ]
      }
      
      # Custom strikes response
      custom_strikes_response = %{
        "call" => ["200", "250", "300", "350", "400"],
        "put" => ["200", "250", "300", "350", "400"]
      }
      
      # Mock both endpoints with custom data
      ContractStub.stub_search_contracts(fn -> HTTPMock.success(custom_search_response) end)
      ContractStub.stub_get_strikes(fn -> HTTPMock.success(custom_strikes_response) end)
      
      # Test the search
      assert {:ok, search_results} = Contract.search_contracts("TSLA")
      assert hd(search_results.sections).symbol == "TSLA"
      assert hd(search_results.sections).name == "TESLA INC"
      
      # Get the strikes using the contract ID from search results
      option_section = Enum.find(search_results.sections, fn section -> section.sec_type == "OPT" end)
      assert {:ok, strikes} = Contract.get_strikes(option_section.conid, "OPT", ~D[2025-07-15])
      
      # Verify custom strikes
      assert strikes.call == ["200", "250", "300", "350", "400"]
    end
    
    test "demonstrates mocking multiple endpoints in a complex workflow" do
      # Setup mocks for various contract endpoints
      ContractStub.stub_search_contracts()
      ContractStub.stub_contract_info(fn -> 
        HTTPMock.success(%{
          "symbol" => "AAPL",
          "company_name" => "APPLE INC",
          "exchange" => "NASDAQ",
          "conid" => 265598,
          "instrument_type" => "STK"
        })
      end)
      ContractStub.stub_trading_schedule()
      
      # Execute a series of API calls
      assert {:ok, search_results} = Contract.search_contracts("AAPL")
      conid = hd(search_results.sections).conid
      
      # Get contract info
      assert {:ok, contract_info} = Contract.contract_info(conid)
      assert contract_info.symbol == "AAPL"
      
      # Get trading schedule
      assert {:ok, schedule} = Contract.trading_schedule(conid)
      assert schedule.id == 265598
      assert length(schedule.schedules) > 0
    end
  end
end