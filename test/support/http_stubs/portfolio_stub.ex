defmodule IbkrApi.Support.HTTPStubs.PortfolioStub do
  @moduledoc """
  Stub module for IbkrApi.ClientPortal.Portfolio HTTP requests.
  """
  
  alias IbkrApi.Support.HTTPMock
  alias IbkrApi.Support.HTTPSandbox

  @base_url "https://localhost:5000/v1/api"
  
  @doc """
  Stubs the list_accounts endpoint.
  """
  def stub_list_accounts(response_fn \\ nil) do
    url = "#{@base_url}/portfolio/accounts"
    
    default_fn = fn ->
      HTTPMock.success([
        %{
          "id" => "U12345678",
          "accountId" => "U12345678",
          "accountVan" => "U12345678",
          "accountTitle" => "Individual Account",
          "displayName" => "My Account",
          "accountAlias" => "",
          "accountStatus" => 0,
          "currency" => "USD",
          "type" => "INDIVIDUAL",
          "tradingType" => "CASH",
          "faclient" => false,
          "clearingStatus" => "O",
          "covestor" => false,
          "parent" => %{},
          "desc" => "Individual Account"
        }
      ])
    end
    
    HTTPSandbox.set_get_responses([{url, response_fn || default_fn}])
  end
  
  @doc """
  Stubs the list_sub_accounts endpoint.
  """
  def stub_list_sub_accounts(response_fn \\ nil) do
    url = "#{@base_url}/portfolio/subaccounts"
    
    default_fn = fn ->
      HTTPMock.success([
        %{
          "id" => "U12345678",
          "accountId" => "U12345678",
          "accountVan" => "U12345678",
          "accountTitle" => "Individual Account",
          "displayName" => "My Account",
          "accountAlias" => "",
          "accountStatus" => 0,
          "currency" => "USD",
          "type" => "INDIVIDUAL",
          "tradingType" => "CASH",
          "faclient" => false,
          "clearingStatus" => "O",
          "covestor" => false
        }
      ])
    end
    
    HTTPSandbox.set_get_responses([{url, response_fn || default_fn}])
  end
  
  @doc """
  Stubs the account_info endpoint.
  """
  def stub_account_info(response_fn \\ nil) do
    url_pattern = ~r{#{@base_url}/portfolio/\d+/meta}
    
    default_fn = fn ->
      HTTPMock.success(%{
        "id" => "U12345678",
        "accountId" => "U12345678",
        "accountVan" => "U12345678",
        "accountTitle" => "Individual Account",
        "displayName" => "My Account",
        "accountAlias" => "",
        "accountStatus" => 0,
        "currency" => "USD",
        "type" => "INDIVIDUAL",
        "tradingType" => "CASH",
        "faclient" => false,
        "clearingStatus" => "O",
        "covestor" => false
      })
    end
    
    HTTPSandbox.set_get_responses([{url_pattern, response_fn || default_fn}])
  end
  
  @doc """
  Stubs the account_summary endpoint.
  """
  def stub_account_summary(response_fn \\ nil) do
    url_pattern = ~r{#{@base_url}/portfolio/accounts/.+/summary}
    
    default_fn = fn ->
      HTTPMock.success(%{
        "accountready" => %{
          "amount" => nil,
          "currency" => nil,
          "isNull" => false,
          "timestamp" => 1720029300,
          "value" => true,
          "severity" => 0
        },
        "accounttype" => %{
          "amount" => nil,
          "currency" => nil,
          "isNull" => false,
          "timestamp" => 1720029300,
          "value" => "INDIVIDUAL",
          "severity" => 0
        },
        "availablefunds" => %{
          "amount" => 250000.0,
          "currency" => "USD",
          "isNull" => false,
          "timestamp" => 1720029300,
          "value" => "250,000.00",
          "severity" => 0
        },
        "buyingpower" => %{
          "amount" => 1000000.0,
          "currency" => "USD",
          "isNull" => false,
          "timestamp" => 1720029300,
          "value" => "1,000,000.00",
          "severity" => 0
        },
        "cashbalance" => %{
          "amount" => 250000.0,
          "currency" => "USD",
          "isNull" => false,
          "timestamp" => 1720029300,
          "value" => "250,000.00",
          "severity" => 0
        },
        "totalcashvalue" => %{
          "amount" => 250000.0,
          "currency" => "USD",
          "isNull" => false,
          "timestamp" => 1720029300,
          "value" => "250,000.00",
          "severity" => 0
        }
      })
    end
    
    HTTPSandbox.set_get_responses([{url_pattern, response_fn || default_fn}])
  end
  
  @doc """
  Stubs the account_ledger endpoint.
  """
  def stub_account_ledger(response_fn \\ nil) do
    url_pattern = ~r{#{@base_url}/portfolio/accounts/.+/ledger}
    
    default_fn = fn ->
      HTTPMock.success(%{
        "BASE" => %{
          "cashbalance" => 250000.0,
          "cashavailable" => 250000.0,
          "pendingmarketvalue" => 0.0,
          "realizedpnl" => 150.25,
          "unrealizedpnl" => 275.50
        },
        "USD" => %{
          "cashbalance" => 250000.0,
          "cashavailable" => 250000.0,
          "pendingmarketvalue" => 0.0,
          "realizedpnl" => 150.25,
          "unrealizedpnl" => 275.50,
          "sessionid" => "87654321-abcd-1234-efgh-abcdef123456"
        }
      })
    end
    
    HTTPSandbox.set_get_responses([{url_pattern, response_fn || default_fn}])
  end
  
  @doc """
  Stubs the list_brokerage_accounts endpoint.
  """
  def stub_list_brokerage_accounts(response_fn \\ nil) do
    url = "#{@base_url}/ibcust/brokerage"
    
    default_fn = fn ->
      HTTPMock.success(%{
        "sessionId" => "12345678-abcd-1234-efgh-abcdef123456",
        "accounts" => [
          %{
            "isPrimary" => true,
            "enabled" => true,
            "desc" => "Individual Account",
            "type" => "INDIVIDUAL",
            "id" => "U12345678"
          }
        ],
        "serverInfo" => %{
          "serverVersion" => "985.5l",
          "serverName" => "v176-196-15-11-1"
        }
      })
    end
    
    HTTPSandbox.set_get_responses([{url, response_fn || default_fn}])
  end
  
  @doc """
  Stubs the switch_account endpoint.
  """
  def stub_switch_account(response_fn \\ nil) do
    url = "#{@base_url}/iserver/account"
    
    default_fn = fn ->
      HTTPMock.success(%{"acctId" => "U12345678"})
    end
    
    HTTPSandbox.set_post_responses([{url, response_fn || default_fn}])
  end
  
  @doc """
  Stubs the get_pnl endpoint.
  """
  def stub_get_pnl(response_fn \\ nil) do
    url = "#{@base_url}/iserver/account/pnl/partitioned"
    
    default_fn = fn ->
      HTTPMock.success(%{
        "upnl" => %{
          "full" => %{
            "total" => %{
              "amount" => 275.5,
              "convertedAmount" => 275.5,
              "convertedCurrency" => "USD",
              "currency" => "USD",
              "instrumentId" => 0,
              "instrumentIds" => [],
              "value" => "$275.50"
            },
            "positionsPnl" => 275.5
          }
        }
      })
    end
    
    HTTPSandbox.set_get_responses([{url, response_fn || default_fn}])
  end
  
  @doc """
  Stubs the account_allocation endpoint.
  """
  def stub_account_allocation(response_fn \\ nil) do
    url_pattern = ~r{#{@base_url}/portfolio/accounts/.+/allocation}
    
    default_fn = fn ->
      HTTPMock.success(%{
        "long" => %{
          "assetClass" => %{
            "STK" => 100.0
          },
          "currency" => %{
            "USD" => 100.0
          },
          "group" => %{
            "ETF" => 30.0,
            "Technology" => 70.0
          },
          "sector" => %{
            "Technology" => 70.0,
            "Miscellaneous" => 30.0
          }
        },
        "short" => %{
          "assetClass" => %{},
          "currency" => %{},
          "group" => %{},
          "sector" => %{}
        }
      })
    end
    
    HTTPSandbox.set_get_responses([{url_pattern, response_fn || default_fn}])
  end
  
  @doc """
  Stubs the all_accounts_allocation endpoint.
  """
  def stub_all_accounts_allocation(response_fn \\ nil) do
    url = "#{@base_url}/portfolio/allocation"
    
    default_fn = fn ->
      HTTPMock.success(%{
        "long" => %{
          "assetClass" => %{
            "STK" => 100.0
          },
          "currency" => %{
            "USD" => 100.0
          },
          "group" => %{
            "ETF" => 30.0,
            "Technology" => 70.0
          },
          "sector" => %{
            "Technology" => 70.0,
            "Miscellaneous" => 30.0
          }
        },
        "short" => %{
          "assetClass" => %{},
          "currency" => %{},
          "group" => %{},
          "sector" => %{}
        }
      })
    end
    
    HTTPSandbox.set_get_responses([{url, response_fn || default_fn}])
  end
  
  @doc """
  Stubs the portfolio_positions endpoint.
  """
  def stub_portfolio_positions(response_fn \\ nil) do
    url_pattern = ~r{#{@base_url}/portfolio/accounts/.+/positions/.+}
    
    default_fn = fn ->
      HTTPMock.success([
        %{
          "acctId" => "U12345678",
          "conid" => 265598,
          "contractDesc" => "APPLE INC",
          "position" => 100.0,
          "mktPrice" => 152.50,
          "mktValue" => 15250.0,
          "currency" => "USD",
          "avgCost" => 150.25,
          "avgPrice" => 150.25,
          "realizedPnl" => 0.0,
          "unrealizedPnl" => 225.0,
          "exchs" => "NASDAQ",
          "expiry" => "",
          "putOrCall" => "",
          "strike" => "",
          "ticker" => "AAPL",
          "model" => ""
        }
      ])
    end
    
    HTTPSandbox.set_get_responses([{url_pattern, response_fn || default_fn}])
  end
  
  @doc """
  Stubs the position_by_conid endpoint.
  """
  def stub_position_by_conid(response_fn \\ nil) do
    url_pattern = ~r{#{@base_url}/portfolio/accounts/.+/positions/.+\?conids=.+}
    
    default_fn = fn ->
      HTTPMock.success([
        %{
          "acctId" => "U12345678",
          "conid" => 265598,
          "contractDesc" => "APPLE INC",
          "position" => 100.0,
          "mktPrice" => 152.50,
          "mktValue" => 15250.0,
          "currency" => "USD",
          "avgCost" => 150.25,
          "avgPrice" => 150.25,
          "realizedPnl" => 0.0,
          "unrealizedPnl" => 225.0,
          "exchs" => "NASDAQ",
          "ticker" => "AAPL"
        }
      ])
    end
    
    HTTPSandbox.set_get_responses([{url_pattern, response_fn || default_fn}])
  end
  
  @doc """
  Stubs the invalidate_positions_cache endpoint.
  """
  def stub_invalidate_positions_cache(response_fn \\ nil) do
    url = "#{@base_url}/portfolio/positions/invalidate"
    
    default_fn = fn ->
      HTTPMock.success(%{"status" => "success"})
    end
    
    HTTPSandbox.set_post_responses([{url, response_fn || default_fn}])
  end
end