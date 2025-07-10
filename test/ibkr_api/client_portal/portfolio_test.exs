defmodule IbkrApi.ClientPortal.PortfolioTest do
  use ExUnit.Case
  
  alias IbkrApi.ClientPortal.Portfolio
  alias IbkrApi.Support.HTTPMock
  alias IbkrApi.Support.HTTPStubs.PortfolioStub

  setup do
    # Clear the HTTPSandbox registry before each test
    IbkrApi.Support.HTTPSandbox.clear()
    :ok
  end

  describe "list_accounts/0" do
    test "returns list of accounts with default mock" do
      # Set up the default mock
      PortfolioStub.stub_list_accounts()
      
      # Call the function
      assert {:ok, accounts} = Portfolio.list_accounts()
      
      # Verify the response
      assert length(accounts) > 0
      assert Enum.all?(accounts, fn account -> Map.has_key?(account, "id") end)
    end
    
    test "returns custom accounts list with custom mock" do
      # Create a custom response
      custom_accounts = [
        %{"id" => "TEST123", "accountId" => "TEST123", "accountTitle" => "Test Account"},
        %{"id" => "TEST456", "accountId" => "TEST456", "accountTitle" => "Another Test Account"}
      ]
      
      # Use the custom response in the mock
      PortfolioStub.stub_list_accounts(fn -> HTTPMock.success(custom_accounts) end)
      
      # Call the function
      assert {:ok, accounts} = Portfolio.list_accounts()
      
      # Verify custom response
      assert length(accounts) == 2
      assert Enum.at(accounts, 0)["id"] == "TEST123"
      assert Enum.at(accounts, 1)["id"] == "TEST456"
    end
  end
  
  describe "get_account_summary/1" do
    test "returns account summary with default mock" do
      account_id = "DU12345"
      PortfolioStub.stub_account_summary()
      
      assert {:ok, summary} = Portfolio.get_account_summary(account_id)
      
      assert summary["accountReady"]
      assert Map.has_key?(summary, "accountType")
      assert Map.has_key?(summary, "availableFunds")
    end
  end
  
  describe "get_account_ledger/1" do
    test "returns account ledger with default mock" do
      account_id = "DU12345"
      PortfolioStub.stub_get_account_ledger()
      
      assert {:ok, ledger} = Portfolio.get_account_ledger(account_id)
      
      assert Map.has_key?(ledger, "BASE")
    end
  end
  
  describe "list_positions/1" do
    test "returns positions list with default mock" do
      account_id = "DU12345"
      PortfolioStub.stub_list_positions()
      
      assert {:ok, positions} = Portfolio.list_positions(account_id)
      
      assert is_list(positions)
      assert length(positions) > 0
      assert Enum.all?(positions, fn pos -> Map.has_key?(pos, "conid") end)
    end
  end
  
  describe "get_position/2" do
    test "returns position data with default mock" do
      account_id = "DU12345"
      conid = "265598"
      PortfolioStub.stub_position()
      
      assert {:ok, position} = Portfolio.get_position(account_id, conid)
      
      assert position["conid"] == conid
    end
  end
  
  describe "get_pnl/1" do
    test "returns PnL data with default mock" do
      account_id = "DU12345"
      PortfolioStub.stub_get_pnl()
      
      assert {:ok, pnl} = Portfolio.get_pnl(account_id)
      
      assert Map.has_key?(pnl, "totalPnl")
    end
  end
  
  describe "switch_account/1" do
    test "successfully switches account with default mock" do
      account_id = "DU12345"
      PortfolioStub.stub_switch_account()
      
      assert {:ok, result} = Portfolio.switch_account(account_id)
      
      assert result["set"] == true
    end
  end
  
  test "portfolio workflow with multiple endpoint mocks" do
    # Set up multiple stubs for a workflow test
    PortfolioStub.stub_list_accounts()
    PortfolioStub.stub_account_summary()
    PortfolioStub.stub_list_positions()
    PortfolioStub.stub_switch_account()
    
    # List accounts
    assert {:ok, accounts} = Portfolio.list_accounts()
    account_id = List.first(accounts)["id"]
    
    # Get account summary
    assert {:ok, summary} = Portfolio.get_account_summary(account_id)
    assert summary["accountReady"]
    
    # List positions
    assert {:ok, positions} = Portfolio.list_positions(account_id)
    assert is_list(positions)
    
    # Switch to a different account
    new_account_id = "DU54321"
    assert {:ok, switch_result} = Portfolio.switch_account(new_account_id)
    assert switch_result["set"] == true
  end
  
  test "handling error responses" do
    # Mock an error response for get_account_summary
    error_response = %{"error" => "Account not found", "code" => 404}
    PortfolioStub.stub_get_account_summary(fn -> HTTPMock.error(error_response, 404) end)
    
    assert {:error, error} = Portfolio.get_account_summary("INVALID_ACCOUNT")
    assert error.status == 404
  end
  
  test "handling network errors" do
    # Mock a network error for list_accounts
    PortfolioStub.stub_list_accounts(fn -> HTTPMock.network_error(:timeout) end)
    
    assert {:error, :timeout} = Portfolio.list_accounts()
  end
end
