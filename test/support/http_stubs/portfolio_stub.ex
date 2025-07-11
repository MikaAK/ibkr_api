defmodule IbkrApi.Support.HTTPStubs.PortfolioStub do
  @moduledoc """
  Stub module for IbkrApi.ClientPortal.Portfolio HTTP requests.
  """

  alias IbkrApi.Support.HTTPMock
  alias IbkrApi.Support.HTTPSandbox

  @base_url "https://localhost:5050/v1/api"

  @doc """
  Stubs the list_accounts endpoint.
  """
  def stub_list_accounts(response_fn \\ nil) do
    url = "#{@base_url}/portfolio/accounts"

    default_fn = fn ->
      HTTPMock.success([
        %{
          :id => "U12345678",
          :account_id => "U12345678",
          :account_van => "U12345678",
          :account_title => "Individual Account",
          :display_name => "My Account",
          :account_alias => "",
          :account_status => 0,
          :currency => "USD",
          :type => "INDIVIDUAL",
          :trading_type => "CASH",
          :faclient => false,
          :clearing_status => "O",
          :covestor => false,
          :parent => %{},
          :desc => "Individual Account"
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
          :id => "U12345678",
          :account_id => "U12345678",
          :account_van => "U12345678",
          :account_title => "Individual Account",
          :display_name => "My Account",
          :account_alias => "",
          :account_status => 0,
          :currency => "USD",
          :type => "INDIVIDUAL",
          :trading_type => "CASH",
          :faclient => false,
          :clearing_status => "O",
          :covestor => false
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
        id: "U12345678",
        account_id: "U12345678",
        account_van: "U12345678",
        account_title: "Individual Account",
        display_name: "My Account",
        account_alias: "",
        account_status: 0,
        currency: "USD",
        type: "INDIVIDUAL",
        trading_type: "CASH",
        faclient: false,
        clearing_status: "O",
        covestor: false
      })
    end

    HTTPSandbox.set_get_responses([{url_pattern, response_fn || default_fn}])
  end

  @doc """
  Stubs the account_summary endpoint.
  """
  def stub_account_summary(response_fn \\ nil) do
    url_pattern = ~r{#{@base_url}/portfolio/.+/summary}

    default_fn = fn ->
      HTTPMock.success(%{
        accountready: %{
          amount: nil,
          currency: nil,
          is_null: false,
          timestamp: 1720029300,
          value: true,
          severity: 0
        },
        accounttype: %{
          amount: nil,
          currency: nil,
          is_null: false,
          timestamp: 1720029300,
          value: "INDIVIDUAL",
          severity: 0
        },
        availablefunds: %{
          amount: 250000.0,
          currency: "USD",
          is_null: false,
          timestamp: 1720029300,
          value: "250,000.00",
          severity: 0
        },
        buyingpower: %{
          amount: 1000000.0,
          currency: "USD",
          is_null: false,
          timestamp: 1720029300,
          value: "1,000,000.00",
          severity: 0
        },
        cashbalance: %{
          amount: 250000.0,
          currency: "USD",
          is_null: false,
          timestamp: 1720029300,
          value: "250,000.00",
          severity: 0
        },
        totalcashvalue: %{
          amount: 250000.0,
          currency: "USD",
          is_null: false,
          timestamp: 1720029300,
          value: "250,000.00",
          severity: 0
        }
      })
    end

    HTTPSandbox.set_get_responses([{url_pattern, response_fn || default_fn}])
  end

  @doc """
  Stubs the account_ledger endpoint.
  """
  def stub_account_ledger(response_fn \\ nil) do
    url_pattern = ~r{#{@base_url}/portfolio/.+/ledger}

    default_fn = fn ->
      HTTPMock.success(%{
        BASE: %{
          cash_balance: 250000.0,
          cash_available: 250000.0,
          pending_market_value: 0.0,
          realized_pnl: 150.25,
          unrealized_pnl: 275.50
        },
        USD: %{
          cash_balance: 250000.0,
          cash_available: 250000.0,
          pending_market_value: 0.0,
          realized_pnl: 150.25,
          unrealized_pnl: 275.50,
          session_id: "87654321-abcd-1234-efgh-abcdef123456"
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
        session_id: "12345678-abcd-1234-efgh-abcdef123456",
        accounts: [
          %{
            is_primary: true,
            enabled: true,
            description: "Individual Account",
            type: "INDIVIDUAL",
            id: "U12345678"
          }
        ],
        server_info: %{
          server_version: "985.5l",
          server_name: "v176-196-15-11-1"
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
      HTTPMock.success(%{account_id: "U12345678"})
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
        upnl: %{
          full: %{
            total: %{
              amount: 275.5,
              converted_amount: 275.5,
              converted_currency: "USD",
              currency: "USD",
              instrument_id: 0,
              instrument_ids: [],
              value: "$275.50"
            },
            positions_pnl: 275.5
          }
        }
      })
    end

    HTTPSandbox.set_get_responses([{url, response_fn || default_fn}])
  end

  @doc """
  Stubs the portfolio_positions endpoint.
  """
  def stub_portfolio_positions(response_fn \\ nil) do
    url_pattern = ~r{#{@base_url}/portfolio/.+/positions/.*\??}

    default_fn = fn ->
      HTTPMock.success([
        %{
          account_id: "U12345678",
          conid: 265598,
          contract_desc: "APPLE INC",
          position: 100.0,
          market_price: 152.50,
          market_value: 15250.0,
          currency: "USD",
          average_cost: 150.25,
          average_price: 150.25,
          realized_pnl: 0.0,
          unrealized_pnl: 225.0,
          exchs: "NASDAQ",
          expiry: "",
          put_or_call: "",
          strike: "",
          ticker: "AAPL",
          model: ""
        }
      ])
    end

    HTTPSandbox.set_get_responses([{url_pattern, response_fn || default_fn}])
  end

  @doc """
  Stubs the position_by_conid endpoint.
  """
  def stub_position_by_conid(response_fn \\ nil) do
    url_pattern = ~r{#{@base_url}/portfolio/.+/position/\d+}

    default_fn = fn ->
      HTTPMock.success([
        %{
          acct_id: "U12345678",
          conid: 265598,
          contract_desc: "APPLE INC",
          position: 100.0,
          mkt_price: 152.50,
          mkt_value: 15250.0,
          currency: "USD",
          avg_cost: 150.25,
          avg_price: 150.25,
          realized_pnl: 0.0,
          unrealized_pnl: 225.0,
          exchs: "NASDAQ",
          ticker: "AAPL"
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
      HTTPMock.success(%{status: "success"})
    end

    HTTPSandbox.set_post_responses([{url, response_fn || default_fn}])
  end

  @doc """
  Stubs the account_allocation endpoint.
  """
  def stub_account_allocation(response_fn \\ nil) do
    url_pattern = ~r{#{@base_url}/portfolio/.+/allocation}

    default_fn = fn ->
      HTTPMock.success(%{
        :long => %{
          :group => %{
            "Technology" => 65.5,
            "Healthcare" => 20.3,
            "Financial" => 14.2
          },
          :asset_class => %{
            "Stocks" => 85.7,
            "Cash" => 14.3
          },
          :sector => %{
            "Information Technology" => 45.2,
            "Healthcare" => 25.8,
            "Financials" => 15.5,
            "Consumer Discretionary" => 13.5
          }
        }
      })
    end

    HTTPSandbox.set_get_responses([{url_pattern, response_fn || default_fn}])
  end
end
