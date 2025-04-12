defmodule IbkrApi.ClientPortal.Account do
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
    desc: nil
  ]

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
      desc: nil
      # Add other fields specific to sub-accounts if they differ from Account
    ]
  end

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

  defmodule AccountSummary do
    defstruct [
      account_ready: nil,
      account_type: nil,
      accrued_cash: nil,
      accrued_cash_c: nil,
      accrued_cash_f: nil,
      accrued_cash_s: nil,
      accrued_dividend: nil,
      accrued_dividend_c: nil,
      accrued_dividend_f: nil,
      accrued_dividend_s: nil,
      available_funds: nil,
      available_funds_c: nil,
      available_funds_f: nil,
      available_funds_s: nil,
      billable: nil,
      billable_c: nil,
      billable_f: nil,
      billable_s: nil,
      buying_power: nil,
      cushion: nil,
      day_trades_remaining: nil,
      day_trades_remaining_t1: nil,
      day_trades_remaining_t2: nil,
      day_trades_remaining_t3: nil,
      day_trades_remaining_t4: nil,
      equity_with_loan_value: nil,
      equity_with_loan_value_c: nil,
      equity_with_loan_value_f: nil,
      equity_with_loan_value_s: nil,
      excess_liquidity: nil,
      excess_liquidity_c: nil,
      excess_liquidity_f: nil,
      excess_liquidity_s: nil,
      full_available_funds: nil,
      full_available_funds_c: nil,
      full_available_funds_f: nil,
      full_available_funds_s: nil,
      full_excess_liquidity: nil,
      full_excess_liquidity_c: nil,
      full_excess_liquidity_f: nil,
      full_excess_liquidity_s: nil,
      full_init_margin_req: nil,
      full_init_margin_req_c: nil,
      full_init_margin_req_f: nil,
      full_init_margin_req_s: nil,
      full_maint_margin_req: nil,
      full_maint_margin_req_c: nil,
      full_maint_margin_req_f: nil,
      full_maint_margin_req_s: nil,
      gross_position_value: nil,
      gross_position_value_c: nil,
      gross_position_value_f: nil,
      gross_position_value_s: nil,
      # Additional fields as required
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
      commoditymarketvalue: nil,
      corporatebondsmarketvalue: nil,
      warrantsmarketvalue: nil,
      netliquidationvalue: nil,
      interest: nil,
      unrealizedpnl: nil,
      stockmarketvalue: nil,
      moneyfunds: nil,
      realizedpnl: nil,
      funds: nil,
      issueroptionsmarketvalue: nil,
      settledcash: nil,
      futuremarketvalue: nil,
      futureoptionmarketvalue: nil,
      futuresonlypnl: nil
    ]
  end

  defmodule AccountLedger do
    defstruct [
      BASE: %LedgerCurrency{}
      # Include other currency keys as needed, in snake case
    ]
  end

  defmodule BrokerageAccountsResponse do
    defstruct [
      accounts: [],
      aliases: %{},
      selected_account: nil
    ]
  end

  defmodule SwitchAccountResponse do
    defstruct [set: nil, acctId: nil]
  end

  defmodule PnLResponse do
    defstruct [acctId: %{}]
  end

  alias IbkrApi.HTTP
  @base_url IbkrApi.Config.base_url()

  # Function to list portfolio accounts
  @spec list_accounts() :: ErrorMessage.t_res()
  def list_accounts do
    with {:ok, response} <- HTTP.get(Path.join(@base_url, "/portfolio/accounts")) do
      {:ok, Enum.map(response, &struct(Account, &1))}
    end
  end

  # Function to list sub-accounts
  @spec list_sub_accounts() :: ErrorMessage.t_res()
  def list_sub_accounts do
    with {:ok, response} <- HTTP.get(Path.join(@base_url, "/portfolio/subaccounts")) do
      {:ok, Enum.map(response, &struct(SubAccount, &1))}
    end
  end

  # Function to list large sub-accounts
  @spec list_large_sub_accounts(String.t()) :: ErrorMessage.t_res()
  def list_large_sub_accounts(page) do
    with {:ok, response} <- HTTP.get(Path.join(@base_url, "/portfolio/subaccounts2?page=#{page}")) do
      {:ok, struct(LargeSubAccounts, response)}
    end
  end

  # Function to get account information
  @spec account_info(String.t()) :: ErrorMessage.t_res()
  def account_info(account_id) do
    with {:ok, response} <- HTTP.get(Path.join(@base_url, "/portfolio/#{account_id}/meta")) do
      {:ok, struct(__MODULE__, response)}
    end
  end

  # Function to get account summary
  @spec account_summary(String.t()) :: ErrorMessage.t_res()
  def account_summary(account_id) do
    with {:ok, response} <- HTTP.get(Path.join(@base_url, "/portfolio/#{account_id}/summary")) do
      {:ok, struct(AccountSummary, response)}
    end
  end

  # Function to get account ledger
  @spec account_ledger(String.t()) :: ErrorMessage.t_res()
  def account_ledger(account_id) do
    with {:ok, response} <- HTTP.get(Path.join(@base_url, "/portfolio/#{account_id}/ledger")) do
      {:ok, struct(AccountLedger, response)}
    end
  end

  # Function to list brokerage accounts
  @spec list_brokerage_accounts() :: ErrorMessage.t_res()
  def list_brokerage_accounts do
    with {:ok, response} <- HTTP.get(Path.join(@base_url, "/iserver/accounts")) do
      {:ok, struct(BrokerageAccountsResponse, response)}
    end
  end

  # Function to switch accounts
  @spec switch_account(String.t()) :: ErrorMessage.t_res()
  def switch_account(acctId) do
    body = %{"acctId" => acctId}
    with {:ok, response} <- HTTP.post(Path.join(@base_url, "/iserver/account"), body) do
      {:ok, struct(SwitchAccountResponse, response)}
    end
  end

  # Function to get PnL
  @spec get_pnl() :: ErrorMessage.t_res()
  def get_pnl do
    with {:ok, response} <- HTTP.get(Path.join(@base_url, "/iserver/account/pnl/partitioned")) do
      {:ok, struct(PnLResponse, response)}
    end
  end
end
