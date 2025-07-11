defmodule IbkrApi.ClientPortal.Contract do
  @moduledoc """
  Contract-related functionality for the IBKR Client Portal API.

  This module provides functions to retrieve contract information, trading schedules,
  security definitions, and currency exchange rates.
  """

  defmodule Secdef do
    @moduledoc "Security definition structure"
    defstruct [
      conid: nil, currency: nil, cross_currency: nil, time: nil, chinese_name: nil,
      all_exchanges: nil, listing_exchange: nil, name: nil, asset_class: nil,
      expiry: nil, last_trading_day: nil, group: nil, put_or_call: nil, sector: nil,
      sector_group: nil, strike: nil, ticker: nil, und_conid: nil, multiplier: nil,
      type: nil, und_comp: nil, und_sym: nil, has_options: nil, full_name: nil,
      is_us: nil, increment_rules: %{}
    ]
  end

  defmodule TradingTime do
    @moduledoc "Trading time information within a trading schedule"
    defstruct [
      cancel_day_orders: nil,
      closing_time: nil,
      opening_time: nil
    ]
  end

  defmodule Session do
    @moduledoc "Trading session information"
    defstruct [
      closing_time: nil,
      opening_time: nil,
      prop: nil
    ]
  end

  defmodule Schedule do
    @moduledoc "Daily trading schedule information"
    defstruct [
      sessions: [],
      clearing_cycle_end_time: nil,
      trading_schedule_date: nil,
      tradingtimes: []
    ]
  end

  defmodule TradingSchedule do
    @moduledoc "Complete trading schedule for an exchange"
    defstruct [
      id: nil,
      exchange: nil,
      description: nil,
      trade_venue_id: nil,
      schedules: [],
      timezone: nil
    ]
  end

  defmodule Contract do
    @moduledoc "Contract information within stock security definition"
    defstruct [
      exchange: nil,
      contract_id: nil,
      is_us: nil
    ]
  end

  defmodule StockSecurityDefinition do
    @moduledoc "Stock security definition response"
    defstruct [
      name: nil,
      chinese_name: nil,
      asset_class: nil,
      contracts: []
    ]
  end

  defmodule ContractId do
    @moduledoc "Contract ID information"
    defstruct [
      exchange: nil,
      ticker: nil,
      contract_id: nil
    ]
  end

  defmodule CurrencyPair do
    @moduledoc "Available currency pair information"
    defstruct [
      symbol: nil,
      contract_id: nil,
      ccy_pair: nil
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
      instrument_type: nil, currency: nil, category: nil,
      industry: nil, rules: %{}
    ]
  end

  defmodule StrikesResponse do
    @moduledoc "Response structure for option strikes"
    defstruct [
      call: [],
      put: []
    ]
  end

  defmodule ContractSection do
    @moduledoc "Contract section information within search results"
    defstruct [
      sec_type: nil,
      months: [],
      exchange: nil,
      conid: nil
    ]
  end

  defmodule ContractIssuer do
    @moduledoc "Bond issuer information"
    defstruct [
      id: nil,
      name: nil
    ]
  end

  defmodule SearchContract do
    @moduledoc "Contract search result"
    defstruct [
      conid: nil,
      company_header: nil,
      company_name: nil,
      symbol: nil,
      description: nil,
      restricted: nil,
      fop: nil,
      opt: nil,
      war: nil,
      sections: [],
      issuers: [],
      bondid: nil
    ]
  end

  defmodule SecdefInfo do
    @moduledoc "Detailed contract information from secdef/info endpoint"
    defstruct [
      conid: nil,
      symbol: nil,
      sec_type: nil,
      listing_exchange: nil,
      exchange: nil,
      currency: nil,
      valid_exchanges: nil,
      maturity_date: nil,
      right: nil,
      strike: nil,
      coupon: nil,
      cusip: nil,
      desc1: nil,
      desc2: nil,
      multiplier: nil,
      show_prips: nil,
      trading_class: nil
    ]
  end

  alias IbkrApi.HTTP

  @base_url IbkrApi.Config.base_url()

  def get_options_for_symbol(symbol, opts \\ []) do
    opts = Keyword.put_new(opts, :retry?, true)

    with {:ok, {contract_id, strikes}} <- get_strikes_by_symbol(symbol) do
      strikes
        |> Enum.group_by(
          fn {date, _} -> date end,
          fn {date,  %IbkrApi.ClientPortal.Contract.StrikesResponse{call: calls, put: puts}} ->
            Enum.map((calls ++ puts), fn strike ->
              with {:ok, contract} <- get_option_contract_info(contract_id, date, strike, opts) do
                contract
              end
            end)
        end)
        |> Map.new(fn {date, contracts} -> {date, Enum.map(contracts, fn {:ok, contract} -> contract end)} end)
        |> then(&{:ok, &1})
    end
  end

  defp get_option_contract_info(contract_id, %Date{} = month, strike, opts) do
    if opts[:retry?] do
      with {:error, %ErrorMessage{code: :too_many_requests}} <- get_contract_info(contract_id,
        sec_type: "OPT",
        month: format_month_for_ibkr(month),
        strike: strike
      ) do
        Process.sleep(opts[:retry_interval] || :timer.seconds(5))
        get_option_contract_info(contract_id, month, strike, opts)
      end
    else
      get_contract_info(contract_id,
        sec_type: "OPT",
        month: format_month_for_ibkr(month),
        strike: strike,
        retry?: true
      )
    end
  end

  @spec contract_details(String.t()) :: ErrorMessage.t_res()
  def contract_details(conid) do
    HTTP.get(Path.join(@base_url, "/iserver/contract/#{conid}/info"))
  end

  @spec security_stocks_by_symbol(String.t()) :: ErrorMessage.t_res()
  def security_stocks_by_symbol(symbols) do
    HTTP.get(Path.join(@base_url, "/trsrv/stocks"), params: %{symbols: symbols})
  end

  @spec security_futures_by_symbol(String.t()) :: ErrorMessage.t_res()
  def security_futures_by_symbol(symbols) do
    HTTP.get(Path.join(@base_url, "/trsrv/futures"), params: %{symbols: symbols})
  end


  @spec get_trading_schedule(String.t(), String.t(), Keyword.t()) :: ErrorMessage.t_res()
  def get_trading_schedule(asset_class, symbol, opts \\ []) do
    query_params = %{
      "assetClass" => asset_class,
      "symbol" => symbol,
      "exchange" => opts[:exchange],
      "exchangeFilter" => opts[:exchange_filter]
    }

    with {:ok, response} <- HTTP.get(Path.join(@base_url, "/trsrv/secdef/schedule"), [], params: query_params) do
      {:ok, Enum.map(response, &parse_trading_schedule/1)}
    end
  end

  def get_nyse_trading_schedule(symbol \\ "NVDA", asset_class \\ "STK") do
    get_trading_schedule(
      asset_class,
      symbol,
      exchange: "NASDAQ",
      exchange_filter: "NYSE"
    )
  end

  @spec get_stock_security_definition(String.t()) :: ErrorMessage.t_res()
  def get_stock_security_definition(symbol) do
    with {:ok, response} <- HTTP.get(Path.join(@base_url, "/trsrv/stocks"), [], params: %{symbols: symbol}) do
      symbol_atom = String.downcase(symbol) |> String.to_atom()

      case Map.get(response, symbol_atom) do
        stocks when is_list(stocks) ->
          {:ok, Enum.map(stocks, &parse_stock_security_definition/1)}
        _ ->
          {:ok, []}
      end
    end
  end

  @spec get_contract_ids(String.t()) :: ErrorMessage.t_res()
  def get_contract_ids(exchange) do
    with {:ok, response} <- HTTP.get(Path.join(@base_url, "/trsrv/all-conids"), [], params: %{exchange: exchange}) do
      {:ok, Enum.map(response, &parse_contract_id/1)}
    end
  end

  @spec get_currency_exchange_rate(String.t(), String.t()) :: ErrorMessage.t_res()
  def get_currency_exchange_rate(target, source) do
    with {:ok, response} <- HTTP.get(Path.join(@base_url, "/iserver/exchangerate"), [], params: %{target: target, source: source}) do
      {:ok, response[:rate]}
    end
  end

  @spec get_available_currency_pairs(String.t()) :: ErrorMessage.t_res()
  def get_available_currency_pairs(currency \\ "USD") do
    with {:ok, response} <- HTTP.get(Path.join(@base_url, "/iserver/currency/pairs"), [], params: %{currency: currency}) do
      currency_atom = String.downcase(currency) |> String.to_atom()

      case Map.get(response, currency_atom) do
        pairs when is_list(pairs) ->
          {:ok, Enum.map(pairs, &parse_currency_pair/1)}
        _ ->
          {:ok, []}
      end
    end
  end

  @spec secdef_by_conid(list(integer())) :: ErrorMessage.t_res()
  def secdef_by_conid(conids) do
    body = %{"conids" => conids}
    with {:ok, response} <- HTTP.post(Path.join(@base_url, "/trsrv/secdef"), body) do
      {:ok, Enum.map(response, &struct(Secdef, &1))}
    end
  end

  @doc """
  Search for contracts based on symbol and other criteria.

  ## Parameters
  - `symbol`: The ticker symbol, bond issuer type, or company name
  - `opts`: Optional parameters:
    - `:sec_type`: Security type ("STK", "IND", "BOND") - defaults to "STK"
    - `:name`: Boolean indicating if symbol is part of company name
    - `:more`: Boolean for additional results
    - `:fund`: Boolean for fund search
    - `:fund_family_conid_ex`: String for fund family
    - `:pattern`: Boolean for pattern search
    - `:referrer`: String referrer

  ## Examples
      iex> search_contracts("AAPL")
      {:ok, [%SearchContract{symbol: "AAPL", conid: "265598", ...}]}
  """
  @spec search_contracts(String.t(), Keyword.t()) :: ErrorMessage.t_res()
  def search_contracts(symbol, opts \\ []) do
    query_params = %{
      "symbol" => symbol,
      "secType" => Keyword.get(opts, :sec_type, "STK")
    }
    |> maybe_add_param("name", opts[:name])
    |> maybe_add_param("more", opts[:more])
    |> maybe_add_param("fund", opts[:fund])
    |> maybe_add_param("fundFamilyConidEx", opts[:fund_family_conid_ex])
    |> maybe_add_param("pattern", opts[:pattern])
    |> maybe_add_param("referrer", opts[:referrer])

    with {:ok, response} <- HTTP.get(Path.join(@base_url, "/iserver/secdef/search"), [], params: query_params) do
      {:ok, Enum.map(response, &parse_search_contract/1)}
    end
  end

  @doc """
  Get option strikes for a given contract.

  ## Parameters
  - `contract_id`: Contract identifier of the underlying or derivative
  - `sec_type`: Security type (e.g., "OPT" for options)
  - `month`: Elixir Date struct representing the expiration month
  - `opts`: Optional parameters including exchange (defaults to "SMART")

  ## Examples
      iex> date = ~D[2024-01-15]
      iex> get_strikes("265598", "OPT", date)
      {:ok, %StrikesResponse{call: [70, 75, 80], put: [70, 75, 80]}}
  """
  @spec get_strikes(String.t(), String.t(), Date.t(), Keyword.t()) :: ErrorMessage.t_res()
  def get_strikes(contract_id, sec_type, months, opts \\ [])

  def get_strikes(contract_id, sec_type, months, opts) when is_list(months) do
    months
    |> Task.async_stream(fn month ->
      with {:ok, strikes} <- get_strikes(contract_id, sec_type, month, opts) do
        {month, strikes}
      end
    end, shutdown: :brutal_kill)
    |> Stream.map(fn {:ok, value} -> value end)
    |> Enum.to_list
    |> Enum.group_by(fn {month, _} -> month end, fn {_, strikes} -> strikes end)
    |> Map.new(fn {month, [strikes]} -> {month, strikes} end)
    |> then(fn strikes_by_date -> {:ok, strikes_by_date} end)
  end

  @spec get_strikes(String.t(), String.t(), Date.t(), Keyword.t()) :: ErrorMessage.t_res()
  def get_strikes(contract_id, sec_type, %Date{} = month, opts) do
    month_str = format_month_for_ibkr(month)
    exchange = Keyword.get(opts, :exchange, "SMART")

    query_params = %{
      "conid" => contract_id,
      "sectype" => sec_type,
      "month" => month_str,
      "exchange" => exchange
    }

    with {:ok, response} <- HTTP.get(Path.join(@base_url, "/iserver/secdef/strikes"), [], params: query_params) do
      {:ok, %StrikesResponse{
        call: response["call"] || response[:call] || [],
        put: response["put"] || response[:put] || []
      }}
    end
  end

  @doc """
  Convenience function to get strikes for a symbol by first searching for the contract.

  This function searches for the symbol, finds the first matching contract with options,
  then retrieves the strikes for the current month.

  ## Parameters
  - `symbol`: The ticker symbol to search for
  - `opts`: Optional parameters:
    - `:month`: Date struct for expiration month (defaults to current month)
    - `:sec_type`: Security type for search (defaults to "STK")

  ## Examples
      iex> get_strikes("AAPL")
      {:ok, %StrikesResponse{call: [150, 155, 160], put: [150, 155, 160]}}
  """
  @spec get_strikes_by_symbol(String.t(), Keyword.t()) :: ErrorMessage.t_res()
  def get_strikes_by_symbol(symbol, opts \\ []) when is_binary(symbol) do
    sec_type = Keyword.get(opts, :sec_type, "STK")

    with {:ok, contracts} <- search_contracts(symbol, sec_type: sec_type),
         {:ok, {contract, months}} <- find_optionable_contract(contracts),
         {:ok, strikes} <- get_strikes(contract.conid, "OPT", opts[:months] || months) do
      {:ok, {contract.conid, strikes}}
    else
      {:error, :no_optionable_contract} ->
        {:error, "No optionable contract found for symbol #{symbol}"}
      error -> error
    end
  end

  @doc """
  Get detailed contract information using the secdef/info endpoint.

  Returns a list of contract information objects matching the criteria.

  ## Parameters
  - `conid` - Contract identifier (required)
  - `opts` - Optional parameters:
    - `:sec_type` - Security type
    - `:month` - Expiration month for derivatives
    - `:exchange` - Specific exchange
    - `:strike` - Strike price for options
    - `:right` - "C" for Call, "P" for Put options
    - `:issuer_id` - Issuer ID for bonds
    - `:filters` - Comma-separated list of additional filters for bonds

  ## Examples
      iex> IbkrApi.ClientPortal.Contract.get_contract_info("8314")
      {:ok, [%SecdefInfo{conid: 8314, symbol: "IBM", sec_type: "STK", ...}]}

      iex> IbkrApi.ClientPortal.Contract.get_contract_info("265598", sec_type: "OPT", strike: 250)
      {:ok, [%SecdefInfo{conid: 795753109, symbol: "NVDA", right: "C", ...}, ...]}
  """
  def get_contract_info(conid, opts \\ []) do
    query_params = %{"conid" => conid}
    |> maybe_add_param("sectype", opts[:sec_type])
    |> maybe_add_param("month", opts[:month])
    |> maybe_add_param("exchange", opts[:exchange])
    |> maybe_add_param("strike", opts[:strike])
    |> maybe_add_param("right", opts[:right])
    |> maybe_add_param("issuerId", opts[:issuer_id])
    |> maybe_add_param("filters", opts[:filters])

    with {:ok, response} <- HTTP.get(Path.join(@base_url, "/iserver/secdef/info"), [], params: query_params) do
      secdef_infos = Enum.map(response, &parse_secdef_info/1)
      {:ok, secdef_infos}
    end
  end

  # Private helper functions for parsing API responses

  defp parse_trading_schedule(schedule_data) do
    schedules = schedule_data["schedules"] || schedule_data[:schedules] || []

    %TradingSchedule{
      id: schedule_data["id"] || schedule_data[:id],
      exchange: schedule_data["exchange"] || schedule_data[:exchange],
      description: schedule_data["description"] || schedule_data[:description],
      trade_venue_id: schedule_data["trade_venue_id"] || schedule_data[:trade_venue_id],
      timezone: schedule_data["timezone"] || schedule_data[:timezone],
      schedules: Enum.map(schedules, &parse_schedule/1)
    }
  end

  defp parse_schedule(schedule_data) do
    sessions = schedule_data["sessions"] || schedule_data[:sessions] || []
    tradingtimes = schedule_data["tradingtimes"] || schedule_data[:tradingtimes] || []

    %Schedule{
      sessions: Enum.map(sessions, &parse_session/1),
      clearing_cycle_end_time: schedule_data["clearing_cycle_end_time"] || schedule_data[:clearing_cycle_end_time],
      trading_schedule_date: schedule_data["trading_schedule_date"] || schedule_data[:trading_schedule_date],
      tradingtimes: Enum.map(tradingtimes, &parse_trading_time/1)
    }
  end

  defp parse_session(session_data) do
    %Session{
      closing_time: session_data["closing_time"] || session_data[:closing_time],
      opening_time: session_data["opening_time"] || session_data[:opening_time],
      prop: session_data["prop"] || session_data[:prop]
    }
  end

  defp parse_trading_time(trading_time_data) do
    %TradingTime{
      cancel_day_orders: trading_time_data["cancel_day_orders"] || trading_time_data[:cancel_day_orders],
      closing_time: trading_time_data["closing_time"] || trading_time_data[:closing_time],
      opening_time: trading_time_data["opening_time"] || trading_time_data[:opening_time]
    }
  end

  defp parse_stock_security_definition(stock_data) do
    contracts = stock_data["contracts"] || stock_data[:contracts] || []

    %StockSecurityDefinition{
      name: stock_data["name"] || stock_data[:name],
      chinese_name: stock_data["chinese_name"] || stock_data[:chinese_name],
      asset_class: stock_data["asset_class"] || stock_data[:asset_class],
      contracts: Enum.map(contracts, &parse_contract/1)
    }
  end

  defp parse_contract(contract_data) do
    %Contract{
      exchange: contract_data["exchange"] || contract_data[:exchange],
      contract_id: contract_data["conid"] || contract_data[:conid],
      is_us: contract_data["is_us"] || contract_data[:is_us]
    }
  end

  defp parse_contract_id(contract_data) do
    %ContractId{
      exchange: contract_data["exchange"] || contract_data[:exchange],
      ticker: contract_data["ticker"] || contract_data[:ticker],
      contract_id: contract_data["conid"] || contract_data[:conid]
    }
  end

  defp parse_currency_pair(pair_data) do
    %CurrencyPair{
      symbol: pair_data["symbol"] || pair_data[:symbol],
      contract_id: pair_data["conid"] || pair_data[:conid],
      ccy_pair: pair_data["ccy_pair"] || pair_data[:ccy_pair]
    }
  end

  defp parse_search_contract(contract_data) do
    sections = contract_data["sections"] || contract_data[:sections] || []
    issuers = contract_data["issuers"] || contract_data[:issuers] || []

    %SearchContract{
      conid: contract_data["conid"] || contract_data[:conid],
      company_header: contract_data["company_header"] || contract_data[:company_header],
      company_name: contract_data["company_name"] || contract_data[:company_name],
      symbol: contract_data["symbol"] || contract_data[:symbol],
      description: contract_data["description"] || contract_data[:description],
      restricted: contract_data["restricted"] || contract_data[:restricted],
      fop: contract_data["fop"] || contract_data[:fop],
      opt: contract_data["opt"] || contract_data[:opt],
      war: contract_data["war"] || contract_data[:war],
      sections: Enum.map(sections, &parse_contract_section/1),
      issuers: Enum.map(issuers, &parse_contract_issuer/1),
      bondid: contract_data["bondid"] || contract_data[:bondid]
    }
  end

  defp parse_secdef_info(info_data) when is_list(info_data) do
    Enum.map(info_data, &parse_secdef_info/1)
  end

  defp parse_secdef_info(info_data) do
    %SecdefInfo{
      conid: info_data["conid"] || info_data[:conid],
      symbol: info_data["symbol"] || info_data[:symbol] || info_data[:ticker],
      sec_type: info_data["sec_type"] || info_data[:sec_type],
      listing_exchange: info_data["listing_exchange"] || info_data[:listing_exchange],
      exchange: info_data["exchange"] || info_data[:exchange],
      currency: info_data["currency"] || info_data[:currency],
      valid_exchanges: info_data["valid_exchanges"] || info_data[:valid_exchanges],
      maturity_date: info_data["maturity_date"] || info_data[:maturity_date],
      right: info_data["right"] || info_data[:right],
      strike: info_data["strike"] || info_data[:strike],
      coupon: info_data["coupon"] || info_data[:coupon],
      cusip: info_data["cusip"] || info_data[:cusip],
      desc1: info_data["desc1"] || info_data[:desc1],
      desc2: info_data["desc2"] || info_data[:desc2],
      multiplier: info_data["multiplier"] || info_data[:multiplier],
      show_prips: info_data["show_prips"] || info_data[:show_prips],
      trading_class: info_data["trading_class"] || info_data[:trading_class]
    }
  end

  defp parse_contract_section(section_data) do
    %ContractSection{
      sec_type: section_data["sec_type"] || section_data[:sec_type],
      months: parse_months_string(section_data["months"] || section_data[:months] || ""),
      exchange: parse_exchange(section_data["exchange"] || section_data[:exchange] || ""),
      conid: section_data["conid"] || section_data[:conid]
    }
  end

  defp parse_contract_issuer(issuer_data) do
    %ContractIssuer{
      id: issuer_data["id"] || issuer_data[:id],
      name: issuer_data["name"] || issuer_data[:name]
    }
  end

  defp format_month_for_ibkr(%Date{year: year, month: month}) do
    month_abbr = case month do
      1 -> "JAN"
      2 -> "FEB"
      3 -> "MAR"
      4 -> "APR"
      5 -> "MAY"
      6 -> "JUN"
      7 -> "JUL"
      8 -> "AUG"
      9 -> "SEP"
      10 -> "OCT"
      11 -> "NOV"
      12 -> "DEC"
    end

    year_suffix = Integer.to_string(year) |> String.slice(-2, 2)
    "#{month_abbr}#{year_suffix}"
  end

  defp parse_months_string(nil), do: []
  defp parse_months_string(""), do: []
  defp parse_months_string(months_list) when is_list(months_list), do: months_list
  defp parse_months_string(months_str) when is_binary(months_str) do
    months_str
    |> String.split(";")
    |> Enum.map(&parse_ibkr_month_to_date/1)
    |> Enum.reject(&is_nil/1)
  end

  defp parse_exchange(nil), do: nil
  defp parse_exchange(exchange) when is_binary(exchange), do: String.split(exchange, ";")

  defp parse_ibkr_month_to_date(month_str) do
    case String.length(month_str) do
      5 ->
        month_abbr = String.slice(month_str, 0, 3)
        year_suffix = String.slice(month_str, 3, 2)

        month_num = case month_abbr do
          "JAN" -> 1
          "FEB" -> 2
          "MAR" -> 3
          "APR" -> 4
          "MAY" -> 5
          "JUN" -> 6
          "JUL" -> 7
          "AUG" -> 8
          "SEP" -> 9
          "OCT" -> 10
          "NOV" -> 11
          "DEC" -> 12
          _ -> nil
        end

        case {month_num, Integer.parse(year_suffix)} do
          {month_num, {year_suffix_int, ""}} when is_integer(month_num) ->
            # Convert 2-digit year to 4-digit year (assuming 20xx for now)
            full_year = 2000 + year_suffix_int
            Date.new(full_year, month_num, 1)
            |> case do
              {:ok, date} -> date
              {:error, _} -> nil
            end
          _ -> nil
        end
      _ -> nil
    end
  end

  defp maybe_add_param(params, _key, nil), do: params
  defp maybe_add_param(params, key, value), do: Map.put(params, key, value)

  defp find_optionable_contract([]), do: {:error, :no_optionable_contract}
  defp find_optionable_contract([contract | rest]) do
    # Look for a contract that has options (OPT section)
    case Enum.find(contract.sections, fn section ->
      section.sec_type == "OPT"
    end) do
      nil -> find_optionable_contract(rest)
      section -> {:ok, {contract, section.months}}
    end
  end
end
