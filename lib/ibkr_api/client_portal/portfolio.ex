defmodule IbkrApi.ClientPortal.Portfolio do
  @moduledoc """
  Portfolio and Account management functions for IBKR Client Portal API.
  Handles account information, positions, allocations, summaries, and ledgers.
  """

  defmodule Account do
    defstruct [
      id: nil,
      account_id: nil,
      account_van: nil,
      account_title: nil,
      display_name: nil,
      account_alias: nil,
      account_status: nil,
      currency: nil,
      type: nil,
      trading_type: nil,
      faclient: nil,
      clearing_status: nil,
      covestor: nil,
      parent: %{},
      desc: nil,
      category: nil,
      acct_cust_type: nil,
      brokerage_access: nil,
      business_type: nil,
      ib_entity: nil,
      no_client_trading: nil,
      "prepaid_crypto-_p": nil,
      "prepaid_crypto-_z": nil,
      track_virtual_fx_portfolio: nil
    ]
  end

  defmodule SubAccount do
    defstruct [
      id: nil,
      account_id: nil,
      account_van: nil,
      account_title: nil,
      display_name: nil,
      account_alias: nil,
      account_status: nil,
      currency: nil,
      type: nil,
      trading_type: nil,
      faclient: nil,
      clearing_status: nil,
      covestor: nil,
      parent: %{},
      desc: nil,
      category: nil,
      acct_cust_type: nil,
      brokerage_access: nil,
      business_type: nil,
      ib_entity: nil,
      no_client_trading: nil,
      "prepaid_crypto-_p": nil,
      "prepaid_crypto-_z": nil,
      track_virtual_fx_portfolio: nil
    ]
  end

  # Updated metadata struct
  defmodule SubAccountsMetadata do
    defstruct [
      total: nil,
      page_size: nil,
      page_nume: nil
    ]
  end

  defmodule LargeSubAccounts do
    defstruct [
      metadata: %SubAccountsMetadata{},
      subaccounts: [] # List of SubAccount structs
    ]
  end

  defmodule SummaryField do
    @moduledoc """
    Represents a single field in an account summary response.
    Each field contains metadata about the value including timestamp, currency, and severity.
    """

    @type t :: %__MODULE__{
      timestamp: integer() | nil,
      value: String.t() | number() | nil,
      currency: String.t() | nil,
      severity: integer() | nil,
      amount: number() | nil,
      is_null: boolean() | nil
    }

    defstruct [
      timestamp: nil,
      value: nil,
      currency: nil,
      severity: nil,
      amount: nil,
      is_null: nil
    ]
  end

  defmodule AccountSummary do
    @moduledoc """
    AccountSummary struct containing all account summary fields.
    Each field is a SummaryField struct with timestamp, value, currency, severity, amount, and is_null information.
    """

    defstruct [
      # Basic account info
      accounttype: nil,
      accountcode: nil,
      accountready: nil,

      # Cash and liquidity
      totalcashvalue: nil,
      netliquidation: nil,
      excessliquidity: nil,
      availablefunds: nil,
      buyingpower: nil,
      cushion: nil,
      settledcashbydate: nil,
      accruedcash: nil,
      accrueddividend: nil,

      # Margin requirements
      initmarginreq: nil,
      maintmarginreq: nil,
      fullinitmarginreq: nil,
      fullmaintmarginreq: nil,
      lookaheadinitmarginreq: nil,
      lookaheadmaintmarginreq: nil,

      # Equity and positions
      equitywithloanvalue: nil,
      grosspositionvalue: nil,
      pasharesvalue: nil,
      physicalcertificatevalue: nil,

      # Lookahead values
      lookaheadavailablefunds: nil,
      lookaheadexcessliquidity: nil,
      lookaheadnextchange: nil,

      # Full values
      fullavailablefunds: nil,
      fullexcessliquidity: nil,

      # Post expiration
      postexpirationexcess: nil,
      postexpirationmargin: nil,

      # Other fields
      guarantee: nil,
      billable: nil,
      highestseverity: nil,
      nlvandmargininreview: nil,
      netliquidationuncertainty: nil,
      incentivecoupons: nil,
      depositoncredithold: nil,
      indianstockhaircut: nil,
      totaldebitcardpendingcharges: nil,

      # Securities segment fields (with -s suffix)
      "netliquidation-s": nil,
      "excessliquidity-s": nil,
      "availablefunds-s": nil,
      "totalcashvalue-s": nil,
      "equitywithloanvalue-s": nil,
      "grosspositionvalue-s": nil,
      "initmarginreq-s": nil,
      "maintmarginreq-s": nil,
      "fullinitmarginreq-s": nil,
      "fullmaintmarginreq-s": nil,
      "lookaheadinitmarginreq-s": nil,
      "lookaheadmaintmarginreq-s": nil,
      "fullavailablefunds-s": nil,
      "fullexcessliquidity-s": nil,
      "buyingpower-s": nil,
      "cushion-s": nil,
      "pasharesvalue-s": nil,
      "physicalcertificatevalue-s": nil,
      "lookaheadavailablefunds-s": nil,
      "lookaheadexcessliquidity-s": nil,
      "lookaheadnextchange-s": nil,
      "postexpirationexcess-s": nil,
      "postexpirationmargin-s": nil,
      "guarantee-s": nil,
      "billable-s": nil,
      "highestseverity-s": nil,
      "nlvandmargininreview-s": nil,
      "netliquidationuncertainty-s": nil,
      "accruedcash-s": nil,
      "accrueddividend-s": nil,
      "incentivecoupons-s": nil,
      "indianstockhaircut-s": nil,
      "totaldebitcardpendingcharges-s": nil,
      "settledcashbydate-s": nil,
      "segmenttitle-s": nil,
      "tradingtype-s": nil,
      "leverage-s": nil,
      "columnprio-s": nil
    ]
  end

  defmodule LedgerCurrency do
    defstruct [
      timestamp: nil,
      currency: nil,
      key: nil,
      severity: nil,
      acctcode: nil,
      cashbalance: nil,
      cashbalancefxsegment: nil,
      commoditymarketvalue: nil,
      corporatebondsmarketvalue: nil,
      dividends: nil,
      exchangerate: nil,
      funds: nil,
      futuremarketvalue: nil,
      futureoptionmarketvalue: nil,
      futuresonlypnl: nil,
      interest: nil,
      issueroptionsmarketvalue: nil,
      moneyfunds: nil,
      netliquidationvalue: nil,
      realizedpnl: nil,
      secondkey: nil,
      sessionid: nil,
      settledcash: nil,
      stockmarketvalue: nil,
      stockoptionmarketvalue: nil,
      tbillsmarketvalue: nil,
      tbondsmarketvalue: nil,
      unrealizedpnl: nil,
      warrantsmarketvalue: nil,
      endofbundle: nil
    ]
  end

  defmodule AccountLedger do
    defstruct [
      base: nil,
      usd: nil
    ]
  end

  defmodule BrokerageAccountsResponse do
    defstruct [
      accounts: [],
      aliases: %{},
      selected_account: nil,
      session_id: nil,
      profiles: [],
      server_info: %{},
      groups: [],
      acct_props: %{},
      allow_features: %{},
      chart_periods: %{},
      is_ft: nil,
      is_paper: nil
    ]
  end

  defmodule SwitchAccountResponse do
    @moduledoc """
    Response from switching accounts.
    Can contain different fields depending on the response:
    - success: String message when account is already set or successfully switched
    - set: Boolean indicating if account was set (in some responses)
    - acctId: Account ID that was switched to (in some responses)
    """

    defstruct [success: "Account set successfully", set: false, acctId: nil]
  end

  defmodule PnLAccountData do
    @moduledoc """
    Represents PnL data for a specific account.
    Contains daily and unrealized PnL information.
    """

    @type t :: %__MODULE__{
      dpl: number() | nil,
      nl: number() | nil,
      upl: number() | nil,
      el: number() | nil,
      mv: number() | nil
    }

    defstruct [
      dpl: nil,  # Daily PnL
      nl: nil,   # Net Liquidation
      upl: nil,  # Unrealized PnL
      el: nil,   # Excess Liquidity
      mv: nil    # Market Value
    ]
  end

  defmodule PnLResponse do
    defstruct [
      upnl: %{},  # Map of account IDs to PnLAccountData structs
      dpl: nil,
      nl: nil,
      upl: nil,
      el: nil,
      mv: nil
    ]
  end

  # AccountAllocation struct for portfolio allocation functions
  defmodule AccountAllocation do
    defstruct [
      group: %{},
      asset_class: %{},
      sector: %{}
    ]
  end

  defmodule PortfolioPosition do
    defstruct [
      acct_id: nil,
      realized_pnl: nil,
      group: nil,
      und_conid: nil,
      mkt_value: nil,
      ticker: nil,
      type: nil,
      has_options: nil,
      base_mkt_price: nil,
      is_event_contract: nil,
      expiry: nil,
      full_name: nil,
      currency: nil,
      position: nil,
      avg_cost: nil,
      chinese_name: nil,
      name: nil,
      conid: nil,
      sector_group: nil,
      und_comp: nil,
      exercise_style: nil,
      page_size: nil,
      last_trading_day: nil,
      model: nil,
      base_realized_pnl: nil,
      country_code: nil,
      sector: nil,
      all_exchanges: nil,
      base_avg_cost: nil,
      display_rule: %{
        display_rule_step: [
          %{decimal_digits: nil, lower_edge: nil, whole_digits: nil}
        ],
        magnification: nil
      },
      exchs: nil,
      strike: nil,
      multiplier: nil,
      time: nil,
      is_us: nil,
      base_unrealized_pnl: nil,
      contract_desc: nil,
      und_sym: nil,
      avg_price: nil,
      mkt_price: nil,
      base_mkt_value: nil,
      increment_rules: [
        %{increment: nil, lower_edge: nil}
      ],
      con_exch_map: [],
      put_or_call: nil,
      base_avg_price: nil,
      cross_currency: nil,
      asset_class: nil,
      unrealized_pnl: nil,
      listing_exchange: nil
    ]
  end

  @base_url IbkrApi.Config.base_url()

  alias IbkrApi.HTTP

  @spec list_accounts() :: ErrorMessage.t_res()
  def list_accounts do
    with {:ok, response} <- HTTP.get(Path.join(@base_url, "/portfolio/accounts")) do
      {:ok, Enum.map(response, &struct(Account, &1))}
    end
  end

  @spec list_sub_accounts() :: ErrorMessage.t_res()
  def list_sub_accounts do
    with {:ok, response} <- HTTP.get(Path.join(@base_url, "/portfolio/subaccounts")) do
      {:ok, Enum.map(response, &struct(SubAccount, &1))}
    end
  end

  @spec list_large_sub_accounts(String.t()) :: ErrorMessage.t_res()
  def list_large_sub_accounts(page) do
    with {:ok, response} <- HTTP.get(Path.join(@base_url, "/portfolio/subaccounts2?page=#{page}")) do
      {:ok, struct(LargeSubAccounts, response)}
    end
  end

  @spec account_info(String.t()) :: ErrorMessage.t_res()
  def account_info(account_id) do
    with {:ok, response} <- HTTP.get(Path.join(@base_url, "/portfolio/#{account_id}/meta")) do
      {:ok, struct(Account, response)}
    end
  end

  @spec account_summary(String.t()) :: ErrorMessage.t_res()
  def account_summary(account_id) do
    with {:ok, response} <- HTTP.get(Path.join(@base_url, "/portfolio/#{account_id}/summary")) do
      # Convert each field in the response to a SummaryField struct
      # Then construct the AccountSummary struct with these nested SummaryField structs
      processed_response =
        response
        |> Enum.map(fn {key, field_data} ->
          {key, struct(SummaryField, field_data)}
        end)
        |> Enum.into(%{})

      {:ok, struct(AccountSummary, processed_response)}
    end
  end

  @spec account_ledger(String.t()) :: ErrorMessage.t_res()
  def account_ledger(account_id) do
    with {:ok, response} <- HTTP.get(Path.join(@base_url, "/portfolio/#{account_id}/ledger")) do
      # Convert each currency entry to a LedgerCurrency struct
      # Keys can be atoms or strings, so handle both cases
      ledger_data =
        response
        |> Enum.map(fn {currency_key, currency_data} ->
          # Convert string keys to atoms, but leave atom keys as-is
          atom_key = if is_binary(currency_key), do: String.to_atom(currency_key), else: currency_key
          {atom_key, struct(LedgerCurrency, currency_data)}
        end)
        |> Enum.into(%{})

      {:ok, struct(AccountLedger, ledger_data)}
    end
  end

  @spec list_brokerage_accounts() :: ErrorMessage.t_res()
  def list_brokerage_accounts do
    with {:ok, response} <- HTTP.get(Path.join(@base_url, "/iserver/accounts")) do
      {:ok, struct(BrokerageAccountsResponse, response)}
    end
  end

  @spec switch_account(String.t()) :: ErrorMessage.t_res()
  def switch_account(account_id) do
    body = %{"acctId" => account_id}
    with {:ok, response} <- HTTP.post(Path.join(@base_url, "/iserver/account"), body) do
      {:ok, struct(SwitchAccountResponse, Map.put(response, :acctId, account_id))}
    end
  end

  @spec get_pnl() :: ErrorMessage.t_res()
  def get_pnl do
    with {:ok, response} <- HTTP.get(Path.join(@base_url, "/iserver/account/pnl/partitioned")) do
      # Handle nested upnl structure - convert each account's PnL data to PnLAccountData struct
      processed_response = case response do
        %{"upnl" => upnl_data} when is_map(upnl_data) ->
          processed_upnl =
            upnl_data
            |> Enum.map(fn {account_key, pnl_data} ->
              {account_key, struct(PnLAccountData, pnl_data)}
            end)
            |> Enum.into(%{})

          Map.put(response, "upnl", processed_upnl)

        %{upnl: upnl_data} when is_map(upnl_data) ->
          processed_upnl =
            upnl_data
            |> Enum.map(fn {account_key, pnl_data} ->
              {account_key, struct(PnLAccountData, pnl_data)}
            end)
            |> Enum.into(%{})

          Map.put(response, :upnl, processed_upnl)

        _ -> response
      end

      {:ok, struct(PnLResponse, processed_response)}
    end
  end

  # Portfolio-specific functions (keeping from original portfolio.ex)
  @spec account_allocation(String.t()) :: ErrorMessage.t_res()
  def account_allocation(account_id) do
    with {:ok, response} <- HTTP.get(Path.join(@base_url, "/portfolio/#{account_id}/allocation")) do
      # Extract allocation data from the 'long' section of the response
      allocation_data = case response do
        %{long: long_data} when is_map(long_data) ->
          %{
            group: Map.get(long_data, :group, %{}),
            asset_class: Map.get(long_data, :asset_class, %{}),
            sector: Map.get(long_data, :sector, %{})
          }
        _ ->
          # Fallback for direct response format
          %{
            group: Map.get(response, :group, %{}),
            asset_class: Map.get(response, :asset_class, %{}),
            sector: Map.get(response, :sector, %{})
          }
      end
      
      {:ok, struct(AccountAllocation, allocation_data)}
    end
  end

  @spec all_accounts_allocation(map) :: ErrorMessage.t_res()
  def all_accounts_allocation(account_ids) do
    body = %{"acctIds" => account_ids}

    with {:ok, response} <- HTTP.post(Path.join(@base_url, "/portfolio/allocation"), body) do
      {:ok, struct(AccountAllocation, response)}
    end
  end

  @spec portfolio_positions(String.t(), Keyword.t()) :: ErrorMessage.t_res()
  def portfolio_positions(account_id, opts \\ []) do
    query_string = URI.encode_query(opts)
    page_id = opts[:page_id] || ""

    with {:ok, response} <- HTTP.get(Path.join(@base_url, "/portfolio/#{account_id}/positions/#{page_id}?#{query_string}")) do
      {:ok, Enum.map(response, &struct(PortfolioPosition, &1))}
    end
  end

  @spec position_by_conid(String.t(), integer) :: ErrorMessage.t_res()
  def position_by_conid(account_id, conid) do
    with {:ok, response} <- HTTP.get(Path.join(@base_url, "/portfolio/#{account_id}/position/#{conid}")) do
      {:ok, Enum.map(response, &struct(PortfolioPosition, &1))}
    end
  end

  @spec invalidate_positions_cache(String.t()) :: ErrorMessage.t_ok_res()
  def invalidate_positions_cache(account_id) do
    with {:ok, %{message: "success"}} <- HTTP.post(Path.join(@base_url, "/portfolio/#{account_id}/positions/invalidate"), %{}) do
      :ok
    end
  end
end
