defmodule IbkrApi.ClientPortal.Contract do
  defmodule Secdef do
    defstruct [
      conid: nil, currency: nil, cross_currency: nil, time: nil, chinese_name: nil,
      all_exchanges: nil, listing_exchange: nil, name: nil, asset_class: nil,
      expiry: nil, last_trading_day: nil, group: nil, put_or_call: nil, sector: nil,
      sector_group: nil, strike: nil, ticker: nil, und_conid: nil, multiplier: nil,
      type: nil, und_comp: nil, und_sym: nil, has_options: nil, full_name: nil,
      is_us: nil, increment_rules: %{}
    ]
  end

  defmodule TradingSchedule do
    defstruct [
      id: nil, trade_venue_id: nil, schedules: []
    ]
  end

  defmodule SecurityFutures do
    defstruct symbol: [], futures: []
  end

  defmodule SecurityStocks do
    defstruct symbol: [], stocks: []
  end

  defmodule ContractDetails do
    defstruct [
      r_t_h: nil, con_id: nil, company_name: nil, exchange: nil, local_symbol: nil,
      instrument_type: nil, currency: nil, companyName: nil, category: nil,
      industry: nil, rules: %{}
    ]
  end

  alias IbkrApi.HTTP

  @base_url IbkrApi.Config.base_url()

  @spec contract_details(String.t()) :: ErrorMessage.t_res()
  def contract_details(conid) do
    HTTP.get(Path.join(@base_url, "/iserver/contract/#{conid}/info"))
  end

  @spec security_stocks_by_symbol(String.t()) :: ErrorMessage.t_res()
  def security_stocks_by_symbol(symbols) do
    HTTP.get(Path.join(@base_url, "/trsrv/stocks"), %{"symbols" => symbols})
  end

  @spec security_futures_by_symbol(String.t()) :: ErrorMessage.t_res()
  def security_futures_by_symbol(symbols) do
    HTTP.get(Path.join(@base_url, "/trsrv/futures"), %{"symbols" => symbols})
  end


  @spec get_trading_schedule(String.t(), String.t(), String.t(), String.t()) :: ErrorMessage.t_res()
  def get_trading_schedule(asset_class, symbol, exchange, exchange_filter) do
    query_params = %{
      "assetClass" => asset_class,
      "symbol" => symbol,
      "exchange" => exchange,
      "exchangeFilter" => exchange_filter
    }
    HTTP.get(Path.join(@base_url, "/trsrv/secdef/schedule"), query_params)
  end


  @spec secdef_by_conid(list(integer())) :: ErrorMessage.t_res()
  def secdef_by_conid(conids) do
    body = %{"conids" => conids}
    with {:ok, response} <- HTTP.post(Path.join(@base_url, "/trsrv/secdef"), body) do
      {:ok, Enum.map(response, &struct(Secdef, &1))}
    end
  end
end
