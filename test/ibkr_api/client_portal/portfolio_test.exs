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
      assert Enum.all?(accounts, fn account -> 
        %IbkrApi.ClientPortal.Portfolio.Account{} = account
        account.id !== nil
      end)
    end
    
    test "returns custom accounts list with custom mock" do
      # Create a custom response
      custom_accounts = [
        %{id: "TEST123", account_id: "TEST123", account_title: "Test Account"},
        %{id: "TEST456", account_id: "TEST456", account_title: "Another Test Account"}
      ]
      
      # Use the custom response in the mock
      PortfolioStub.stub_list_accounts(fn -> HTTPMock.success(custom_accounts) end)
      
      # Call the function
      assert {:ok, accounts} = Portfolio.list_accounts()
      
      # Verify custom response
      assert length(accounts) == 2
      assert Enum.at(accounts, 0).id == "TEST123"
      assert Enum.at(accounts, 1).account_title == "Another Test Account"
    end
  end
  
  describe "account_summary/1" do
    test "returns account summary with default mock" do
      account_id = "DU12345"
      PortfolioStub.stub_account_summary()
      
      assert {:ok, summary} = Portfolio.account_summary(account_id)
      
      # Assert on struct fields - AccountSummary has dynamic fields with SummaryField structs
      assert summary.accountready.value === true
      assert Map.has_key?(summary, :accounttype)
      assert Map.has_key?(summary, :availablefunds)
    end
  end
  
  describe "account_allocation/1" do
    test "returns allocation data with default mock" do
      account_id = "DU12345"
      PortfolioStub.stub_account_allocation()
      
      assert {:ok, allocation} = Portfolio.account_allocation(account_id)
      
      # AccountAllocation struct has group, asset_class, and sector fields
      assert allocation.group !== %{}
      assert allocation.asset_class !== %{}
      assert allocation.sector !== %{}
    end
  end
  
  describe "account_ledger/1" do
    test "returns account ledger with default mock" do
      account_id = "DU12345"
      PortfolioStub.stub_account_ledger()
      
      assert {:ok, ledger} = Portfolio.account_ledger(account_id)
      
      # AccountLedger struct has base and usd fields which are LedgerCurrency structs
      assert Map.has_key?(ledger, :base)
    end
  end
  
  describe "portfolio_positions/1" do
    test "returns positions list with default mock" do
      account_id = "DU12345"
      PortfolioStub.stub_portfolio_positions()
      
      assert {:ok, positions} = Portfolio.portfolio_positions(account_id)
      
      assert is_list(positions)
      assert length(positions) > 0
      assert Enum.all?(positions, fn pos -> pos.conid !== nil end)
    end
  end
  
  describe "position_by_conid/2" do
    test "returns position data with default mock" do
      account_id = "DU12345"
      conid = "265598"
      PortfolioStub.stub_position_by_conid()
      
      assert {:ok, position} = Portfolio.position_by_conid(account_id, conid)
      
      # Position response is a list with position data
      assert is_list(position)
      first_position = List.first(position)
      assert to_string(first_position.conid) == conid
    end
  end
  
  describe "get_pnl/0" do
    test "returns PnL data with default mock" do
      PortfolioStub.stub_get_pnl()
      
      assert {:ok, pnl} = Portfolio.get_pnl()
      
      assert pnl.upnl !== nil || pnl.nl !== nil
    end
  end
  
  describe "switch_account/1" do
    test "successfully switches account with default mock" do
      account_id = "DU12345"
      PortfolioStub.stub_switch_account()
      
      assert {:ok, result} = Portfolio.switch_account(account_id)
      
      # Check that we have an account ID in the result
      assert result.acctId !== nil
    end
  end
  
  test "portfolio workflow with multiple endpoint mocks" do
    # Set up multiple stubs for a workflow test
    PortfolioStub.stub_list_accounts()
    PortfolioStub.stub_account_summary()
    PortfolioStub.stub_portfolio_positions()
    PortfolioStub.stub_switch_account()
    
    # List accounts
    assert {:ok, accounts} = Portfolio.list_accounts()
    first_account = List.first(accounts)
    assert %IbkrApi.ClientPortal.Portfolio.Account{} = first_account
    account_id = first_account.id
    
    # Get account summary
    assert {:ok, summary} = Portfolio.account_summary(account_id)
    assert summary.accountready !== nil
    
    # List positions
    assert {:ok, positions} = Portfolio.portfolio_positions(account_id)
    assert is_list(positions)
    
    # Switch to a different account
    new_account_id = "DU54321"
    assert {:ok, switch_result} = Portfolio.switch_account(new_account_id)
    assert switch_result.acctId !== nil
  end
  
  test "handling error responses" do
    # Mock an error response for account_summary
    error_response = %{"error" => "Account not found", "code" => 404}
    PortfolioStub.stub_account_summary(fn -> HTTPMock.error(error_response, 404) end)
    
    assert {:error, error} = Portfolio.account_summary("INVALID_ACCOUNT")
    assert error.status == 404
  end
  
  test "handling network errors" do
    # Mock a network error for list_accounts
    PortfolioStub.stub_list_accounts(fn -> HTTPMock.network_error(:timeout) end)
    
    assert {:error, :timeout} = Portfolio.list_accounts()
  end
end
