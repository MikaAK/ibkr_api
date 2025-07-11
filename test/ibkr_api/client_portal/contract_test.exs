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
      
      # search_results is now a list of SearchContract structs
      assert is_list(search_results)
      assert length(search_results) > 0
      
      # Find the option contract from search results
      option_contract = Enum.find(search_results, fn contract -> 
        contract.sections && Enum.any?(contract.sections, fn section -> section.sec_type == "OPT" end)
      end)
      
      assert option_contract
      option_section = Enum.find(option_contract.sections, fn section -> section.sec_type == "OPT" end)
      assert option_section.conid == "265598"
      
      # Now use that contract ID to get strikes
      assert {:ok, strikes} = Contract.get_strikes(option_section.conid, "OPT", ~D[2025-08-15])
      
      # Verify strikes data - strikes is now a StrikesResponse struct
      assert strikes.call == ["140", "145", "150", "155", "160"]
      assert strikes.put == ["140", "145", "150", "155", "160"]
    end
    
    test "uses custom mock data for contract search" do
      # Create custom search response with different contract data
      custom_search_response = [
        %{
          "conid" => "76792991",
          "symbol" => "TSLA",
          "company_name" => "TESLA INC",
          "company_header" => "TESLA INC",
          "description" => "Tesla Inc. Common Stock",
          "restricted" => false,
          "fop" => false,
          "opt" => true,
          "war" => false,
          "sections" => [
            %{
              "sec_type" => "STK",
              "exchange" => "NASDAQ",
              "conid" => "76792991",
              "months" => []
            },
            %{
              "sec_type" => "OPT",
              "exchange" => "NASDAQ",
              "conid" => "76792991",
              "months" => ["JUL25", "AUG25", "OCT25"]
            }
          ],
          "issuers" => []
        }
      ]
      
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
      
      # search_results is now a list of SearchContract structs
      assert is_list(search_results)
      assert length(search_results) > 0
      
      # Check the first contract
      first_contract = hd(search_results)
      assert first_contract.symbol == "TSLA"
      assert first_contract.company_name == "TESLA INC"
      
      # Get the strikes using the contract ID from search results
      option_contract = Enum.find(search_results, fn contract -> 
        contract.sections && Enum.any?(contract.sections, fn section -> section.sec_type == "OPT" end)
      end)
      
      assert option_contract
      option_section = Enum.find(option_contract.sections, fn section -> section.sec_type == "OPT" end)
      assert {:ok, strikes} = Contract.get_strikes(option_section.conid, "OPT", ~D[2025-07-15])
      
      # Verify custom strikes - strikes is now a StrikesResponse struct
      assert strikes.call == ["200", "250", "300", "350", "400"]
    end
    
    test "demonstrates mocking multiple endpoints in a complex workflow" do
      # Setup mocks for various contract endpoints
      ContractStub.stub_search_contracts()
      
      # Manually set up the GET response for get_contract_info
      alias IbkrApi.Support.HTTPSandbox
      HTTPSandbox.set_get_responses([
        {"https://localhost:5050/v1/api/iserver/secdef/info", fn -> 
          HTTPMock.success([%{
            "symbol" => "AAPL",
            "company_name" => "APPLE INC",
            "exchange" => "NASDAQ",
            "conid" => 265598,
            "instrument_type" => "STK"
          }])
        end},
        {"https://localhost:5050/v1/api/trsrv/secdef/schedule", fn -> 
          HTTPMock.success([%{
            "id" => 265598,
            "schedules" => [
              %{
                "sessions" => [
                  %{
                    "tradingTimes" => [
                      %{"start" => "09:30", "end" => "16:00"}
                    ],
                    "closingOnly" => false,
                    "date" => "20240710"
                  }
                ],
                "exchange" => "NASDAQ"
              }
            ]
          }])
        end}
      ])
      
      # Execute a series of API calls
      assert {:ok, search_results} = Contract.search_contracts("AAPL")
      
      # search_results is now a list of SearchContract structs
      assert is_list(search_results)
      assert length(search_results) > 0
      
      # Get the contract ID from the first result
      first_contract = hd(search_results)
      conid = first_contract.conid
      
      # Get contract info
      assert {:ok, contract_info_list} = Contract.get_contract_info(conid)
      assert [contract_info | _] = contract_info_list
      assert contract_info.symbol == "AAPL"
      
      # Get trading schedule
      assert {:ok, schedule_list} = Contract.get_trading_schedule(conid, "NASDAQ")
      assert [schedule | _] = schedule_list
      assert schedule.id == 265598
      assert length(schedule.schedules) > 0
    end
  end
end