defmodule IbkrApi.ClientPortal.Profile do
  defmodule AccountParent do
    defstruct [
      account_id: nil,
      is_m_child: nil,
      is_m_parent: nil,
      is_multiplex: nil,
      mmc: []
    ]
  end

  defmodule LargeSubAccountsMetadata do
    defstruct [
      total: nil,
      page_num: nil,
      page_size: nil
    ]
  end

  defmodule LargeSubAccounts do
    defstruct [
      metadata: %LargeSubAccountsMetadata{},
      subaccounts: [] # List of Account structs
    ]
  end

  defmodule Account do
    defstruct [
      id: nil,
      parent: %AccountParent{},
      type: nil,
      desc: nil,
      currency: nil,
      account_id: nil,
      account_alias: nil,
      account_status: nil,
      account_title: nil,
      account_van: nil,
      acct_cust_type: nil,
      brokerage_access: nil,
      business_type: nil,
      clearing_status: nil,
      covestor: nil,
      display_name: nil,
      faclient: nil,
      ib_entity: nil,
      no_client_trading: nil,
      "prepaid_crypto-_p": nil,
      "prepaid_crypto-_z": nil,
      track_virtual_fx_portfolio: nil,
      trading_type: nil
    ]
  end

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
      warrantsmarketvalue: nil
    ]
  end


  @base_url IbkrApi.Config.base_url()

  alias IbkrApi.HTTP

  @base_url IbkrApi.Config.base_url()
    @spec list_accounts() :: ErrorMessage.t_res()
  def list_accounts do
    with {:ok, response} <- HTTP.get(Path.join(@base_url, "/portfolio/accounts")) do
      {:ok, Enum.map(response, &struct(Account, &1))}
    end
  end

  @spec list_sub_accounts() :: ErrorMessage.t_res()
  def list_sub_accounts do
    with {:ok, response} <- HTTP.get(Path.join(@base_url, "/portfolio/subaccounts")) do
      {:ok, Enum.map(response, &struct(Account, &1))}
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

  @spec account_allocation(String.t()) :: ErrorMessage.t_res()
  def account_allocation(account_id) do
    with {:ok, response} <- HTTP.get(Path.join(@base_url, "/portfolio/#{account_id}/allocation")) do
      {:ok, struct(AccountAllocation, response)}
    end
  end

  @spec all_accounts_allocation(map) :: ErrorMessage.t_res()
  def all_accounts_allocation(account_ids) do
    body = %{"acctIds" => account_ids}

    with {:ok, response} <- HTTP.post(Path.join(@base_url, "/portfolio/allocation"), body) do
      {:ok, struct(AccountAllocation, response)}
    end
  end

  @spec portfolio_positions(String.t(), String.t(), Keyword.t()) :: ErrorMessage.t_res()
  def portfolio_positions(account_id, page_id, opts \\ []) do
    query_string = URI.encode_query(opts)

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

  @spec account_summary(String.t()) :: ErrorMessage.t_res()
  def account_summary(account_id) do
    HTTP.get(Path.join(@base_url, "/portfolio/#{account_id}/summary"))
  end

  @spec account_ledger(String.t()) :: ErrorMessage.t_res()
  def account_ledger(account_id) do
    with {:ok, response} <- HTTP.get(Path.join(@base_url, "/portfolio/#{account_id}/ledger")) do
      {:ok, Map.new(response, fn {key, value} -> {key, struct(LedgerCurrency, value)} end)}
    end
  end
end

