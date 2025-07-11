defmodule IbkrApi.ClientPortal.MarketData do
  @moduledoc """
  Market Data functionality for the IBKR Client Portal API.

  This module provides functions to retrieve live market data snapshots and other
  market data related information.
  """

  defmodule HistoricalBar do
    @moduledoc """
    Historical market data bar structure.
    """

    defstruct [
      :timestamp,
      :open,
      :high,
      :low,
      :close,
      :volume
    ]

    @type t :: %__MODULE__{
            timestamp: DateTime.t(),
            open: float(),
            high: float(),
            low: float(),
            close: float(),
            volume: float()
          }

    @doc """
    Converts IBKR API response data to HistoricalBar struct.
    """
    @spec from_ibkr(map()) :: t()
    def from_ibkr(%{"t" => ts, "o" => o, "h" => h, "l" => l, "c" => c, "v" => v}) do
      %__MODULE__{
        timestamp: DateTime.from_unix!(ts, :millisecond),
        open: o,
        high: h,
        low: l,
        close: c,
        volume: v
      }
    end
  end

  defmodule MarketDataSnapshot do
    @moduledoc """
    Market data snapshot response structure with descriptive field names.
    All numeric field codes are mapped to their descriptive equivalents.
    """

    defstruct [
      # Price fields
      last_price: nil,              # 31 - Last Price
      bid_price: nil,               # 84 - Bid Price
      ask_price: nil,               # 86 - Ask Price
      high: nil,                    # 70 - Current day high price
      low: nil,                     # 71 - Current day low price
      open: nil,                    # 7295 - Today's opening price
      close: nil,                   # 7296 - Today's closing price
      prior_close: nil,             # 7741 - Yesterday's closing price

      # Volume and size fields
      volume: nil,                  # 87 - Volume for the day
      volume_long: nil,             # 7762 - High precision volume
      bid_size: nil,                # 88 - Bid size
      ask_size: nil,                # 85 - Ask size
      last_size: nil,               # 7059 - Last trade size
      average_volume: nil,          # 7282 - 90-day average volume

      # Change fields
      change: nil,                  # 82 - Price change from prior close
      change_percent: nil,          # 83 - Change percentage
      change_since_open: nil,       # 7682 - Change since open

      # PnL fields
      market_value: nil,            # 73 - Market value of position
      avg_price: nil,               # 74 - Average price of position
      unrealized_pnl: nil,          # 75 - Unrealized PnL
      unrealized_pnl_percent: nil,  # 80 - Unrealized PnL %
      daily_pnl: nil,               # 78 - Daily PnL
      daily_pnl_raw: nil,           # 7920 - Daily PnL Raw
      realized_pnl: nil,            # 79 - Realized PnL
      cost_basis: nil,              # 7292 - Cost basis
      cost_basis_raw: nil,          # 7921 - Cost basis raw
      formatted_position: nil,      # 76 - Formatted position
      formatted_unrealized_pnl: nil, # 77 - Formatted unrealized PnL
      percent_of_mark_value: nil,   # 7639 - % of mark value

      # Contract information
      symbol: nil,                  # 55 - Symbol
      text: nil,                    # 58 - Text
      conid: nil,                   # 6008 - Contract ID
      exchange: nil,                # 6004 - Exchange
      sec_type: nil,                # 6070 - Security type
      months: nil,                  # 6072 - Months
      regular_expiry: nil,          # 6073 - Regular expiry
      underlying_conid: nil,        # 6457 - Underlying contract ID
      conid_exchange: nil,          # 7094 - Conid + Exchange

      # Exchange information
      ask_exch: nil,                # 7057 - Ask exchange
      last_exch: nil,               # 7058 - Last exchange
      bid_exch: nil,                # 7068 - Bid exchange
      listing_exchange: nil,        # 7221 - Listing exchange

      # Company information
      company_name: nil,            # 7051 - Company name
      contract_description: nil,    # 7219 - Contract description
      contract_description_alt: nil, # 7220 - Alternative contract description
      industry: nil,                # 7280 - Industry
      category: nil,                # 7281 - Category

      # Financial metrics
      market_cap: nil,              # 7289 - Market cap
      pe_ratio: nil,                # 7290 - P/E ratio
      eps: nil,                     # 7291 - Earnings per share
      dividend_amount: nil,         # 7286 - Dividend amount
      dividend_yield_percent: nil,  # 7287 - Dividend yield %
      dividends: nil,               # 7671 - Expected dividends (12 months)
      dividends_ttm: nil,           # 7672 - Dividends trailing 12 months
      ex_dividend_date: nil,        # 7288 - Ex-dividend date
      week_52_high: nil,            # 7293 - 52-week high
      week_52_low: nil,             # 7294 - 52-week low

      # Options-related fields
      implied_vol_percent: nil,     # 7283 - Option implied volatility %
      implied_vol_hist_vol_percent: nil, # 7084 - Implied vol/historical vol %
      put_call_interest: nil,       # 7085 - Put/call interest ratio
      put_call_volume: nil,         # 7086 - Put/call volume ratio
      put_call_ratio: nil,          # 7285 - Put/call ratio
      historical_vol_percent: nil,  # 7087 - 30-day historical volatility %
      historical_vol_close_percent: nil, # 7088 - Historical vol based on close %
      option_volume: nil,           # 7089 - Option volume
      option_volume_change_percent: nil, # 7607 - Option volume change %
      option_implied_vol_percent: nil, # 7633 - Implied vol % for specific strike
      option_open_interest: nil,    # 7638 - Option open interest

      # Greeks (for options)
      delta: nil,                   # 7308 - Delta
      gamma: nil,                   # 7309 - Gamma
      theta: nil,                   # 7310 - Theta
      vega: nil,                    # 7311 - Vega

      # Moving averages
      ema_200: nil,                 # 7674 - EMA(200)
      ema_100: nil,                 # 7675 - EMA(100)
      ema_50: nil,                  # 7676 - EMA(50)
      ema_20: nil,                  # 7677 - EMA(20)
      price_ema_200_ratio: nil,     # 7678 - Price/EMA(200) ratio
      price_ema_100_ratio: nil,     # 7679 - Price/EMA(100) ratio
      price_ema_50_ratio: nil,      # 7724 - Price/EMA(50) ratio
      price_ema_20_ratio: nil,      # 7681 - Price/EMA(20) ratio

      # Trading permissions and availability
      can_be_traded: nil,           # 7184 - If contract is tradeable
      has_trading_permissions: nil, # 7768 - If user has trading permissions
      market_data_availability: nil, # 6509 - Market data availability
      service_params: nil,          # 6508 - Service parameters
      marker: nil,                  # 6119 - Market data delivery marker

      # Short selling
      shortable_shares: nil,        # 7636 - Shares available for shorting
      fee_rate: nil,                # 7637 - Interest rate on borrowed shares
      shortable: nil,               # 7644 - Difficulty level for short selling

      # Bond-specific fields
      last_yield: nil,              # 7698 - Last yield
      bid_yield: nil,               # 7699 - Bid yield
      ask_yield: nil,               # 7720 - Ask yield
      organization_type: nil,       # 7704 - Organization type
      debt_class: nil,              # 7705 - Debt class
      ratings: nil,                 # 7706 - Bond ratings
      bond_state_code: nil,         # 7707 - Bond state code
      bond_type: nil,               # 7708 - Bond type
      last_trading_date: nil,       # 7714 - Last trading date
      issue_date: nil,              # 7715 - Issue date

      # Risk metrics
      beta: nil,                    # 7718 - Beta against standard index
      mark: nil,                    # 7635 - Mark price

      # Events (requires Wall Street Horizon subscription)
      upcoming_event: nil,          # 7683 - Next major company event
      upcoming_event_date: nil,     # 7684 - Date of next event
      upcoming_analyst_meeting: nil, # 7685 - Next analyst meeting
      upcoming_earnings: nil,       # 7686 - Next earnings event
      upcoming_misc_event: nil,     # 7687 - Next shareholder meeting
      recent_analyst_meeting: nil,  # 7688 - Most recent analyst meeting
      recent_earnings: nil,         # 7689 - Most recent earnings
      recent_misc_event: nil,       # 7690 - Most recent shareholder meeting

      # Probability fields
      probability_max_return: nil,  # 7694 - Probability of max return
      probability_max_return_alt: nil, # 7700 - Alternative probability max return
      probability_max_loss: nil,    # 7702 - Probability of max loss
      profit_probability: nil,      # 7703 - Probability of any gain
      break_even: nil,              # 7695 - Break even points

      # Futures-specific
      futures_open_interest: nil,   # 7697 - Futures open interest
      spx_delta: nil,               # 7696 - SPX Delta (beta weighted)

      # Morningstar
      morningstar_rating: nil       # 7655 - Morningstar rating
    ]
  end

  alias IbkrApi.HTTP

  @base_url IbkrApi.Config.base_url()

  # All available field codes - by default we request all of them
  @all_field_codes [
    "31", "55", "58", "70", "71", "73", "74", "75", "76", "77", "78", "79", "80", "82", "83", "84", "85", "86", "87", "88",
    "6004", "6008", "6070", "6072", "6073", "6119", "6457", "6508", "6509",
    "7051", "7057", "7058", "7059", "7068", "7084", "7085", "7086", "7087", "7088", "7089", "7094",
    "7184", "7219", "7220", "7221", "7280", "7281", "7282", "7283", "7284", "7285", "7286", "7287", "7288", "7289", "7290", "7291", "7292", "7293", "7294", "7295", "7296",
    "7308", "7309", "7310", "7311", "7607", "7633", "7635", "7636", "7637", "7638", "7639", "7644", "7655",
    "7671", "7672", "7674", "7675", "7676", "7677", "7678", "7679", "7724", "7681", "7682", "7683", "7684", "7685", "7686", "7687", "7688", "7689", "7690",
    "7694", "7695", "7696", "7697", "7698", "7699", "7700", "7702", "7703", "7704", "7705", "7706", "7707", "7708", "7714", "7715", "7718", "7720", "7741", "7762", "7768", "7920", "7921"
  ]

  @doc """
  Retrieves historical market data for a contract.

  ## Parameters
  - `conid`: Contract identifier
  - `period`: Duration of data to fetch (e.g., "1w", "1mo", "1d", "2h")
  - `bar`: Bar size (e.g., "1hour", "5min", "1day")
  - `opts`: Optional parameters
    - `:outside_rth` - Include extended hours? (default: false)
    - `:exchange` - Optional exchange (default: "SMART")

  ## Examples
      iex> get_historical_data("265598", "2w", "1hour")
      {:ok, [%HistoricalBar{timestamp: ~U[2024-02-05 14:00:00Z], open: 189.9, ...}, ...]}

      iex> get_historical_data("265598", "1d", "5min", outside_rth: true)
      {:ok, [%HistoricalBar{...}, ...]}
  """
  @spec get_historical_data(String.t(), String.t(), String.t(), keyword()) :: {:ok, [HistoricalBar.t()]} | {:error, ErrorMessage.t()}
  def get_historical_data(conid, period, bar, opts \\ []) do
    outside_rth = Keyword.get(opts, :outside_rth, false)
    exchange = Keyword.get(opts, :exchange, "SMART")

    params = %{
      "conid" => conid,
      "period" => period,
      "bar" => bar,
      "outsideRth" => outside_rth,
      "exchange" => exchange
    }

    case HTTP.get("#{@base_url}/iserver/marketdata/history", params) do
      {:ok, %{"data" => data}} when is_list(data) ->
        bars = Enum.map(data, &HistoricalBar.from_ibkr/1)
        {:ok, bars}
      {:ok, body} ->
        {:error, ErrorMessage.internal_server_error("Unexpected response format: #{inspect(body)}")}
      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Retrieves live market data snapshots for one or more contracts.

  For derivative contracts, /iserver/secdef/search must be called first.

  ## Parameters
  - `conids`: Contract identifier(s) - can be a single string or comma-separated string
  - `opts`: Optional parameters
    - `:fields` - List of specific field codes to request (defaults to all fields)

  ## Examples
      iex> live_market_data_snapshots("265598")
      {:ok, [%MarketDataSnapshot{symbol: "AAPL", last_price: 150.25, ...}]}

      iex> live_market_data_snapshots("265598,8314", fields: ["31", "55"])
      {:ok, [%MarketDataSnapshot{last_price: 150.25, symbol: "AAPL"}, ...]}
  """
  @spec live_market_data_snapshots(String.t(), keyword()) :: {:ok, [MarketDataSnapshot.t()]} | {:error, ErrorMessage.t()}
  def live_market_data_snapshots(conids, opts \\ []) do
    fields = Keyword.get(opts, :fields, @all_field_codes)
    fields_param = if is_list(fields), do: Enum.join(fields, ","), else: fields

    query_params = %{
      "conids" => conids,
      "fields" => fields_param
    }

    with {:ok, response} <- HTTP.get(Path.join(@base_url, "/iserver/marketdata/snapshot"), [], params: query_params) do
      # Parse the response and convert to MarketDataSnapshot structs
        parsed_snapshots = Enum.map(response, &parse_market_data_response/1)
        {:ok, parsed_snapshots}
    end
  end

  # Field code to struct field mapping - will be used once we see the actual response format
  @field_mapping %{
    "31" => :last_price,
    "55" => :symbol,
    "58" => :text,
    "70" => :high,
    "71" => :low,
    "73" => :market_value,
    "74" => :avg_price,
    "75" => :unrealized_pnl,
    "76" => :formatted_position,
    "77" => :formatted_unrealized_pnl,
    "78" => :daily_pnl,
    "79" => :realized_pnl,
    "80" => :unrealized_pnl_percent,
    "82" => :change,
    "83" => :change_percent,
    "84" => :bid_price,
    "85" => :ask_size,
    "86" => :ask_price,
    "87" => :volume,
    "88" => :bid_size,
    "6004" => :exchange,
    "6008" => :conid,
    "6070" => :sec_type,
    "6072" => :months,
    "6073" => :regular_expiry,
    "6119" => :marker,
    "6457" => :underlying_conid,
    "6508" => :service_params,
    "6509" => :market_data_availability,
    "7051" => :company_name,
    "7057" => :ask_exch,
    "7058" => :last_exch,
    "7059" => :last_size,
    "7068" => :bid_exch,
    "7084" => :implied_vol_hist_vol_percent,
    "7085" => :put_call_interest,
    "7086" => :put_call_volume,
    "7087" => :historical_vol_percent,
    "7088" => :historical_vol_close_percent,
    "7089" => :option_volume,
    "7094" => :conid_exchange,
    "7184" => :can_be_traded,
    "7219" => :contract_description,
    "7220" => :contract_description_alt,
    "7221" => :listing_exchange,
    "7280" => :industry,
    "7281" => :category,
    "7282" => :average_volume,
    "7283" => :implied_vol_percent,
    "7284" => :historical_vol_percent, # Deprecated
    "7285" => :put_call_ratio,
    "7286" => :dividend_amount,
    "7287" => :dividend_yield_percent,
    "7288" => :ex_dividend_date,
    "7289" => :market_cap,
    "7290" => :pe_ratio,
    "7291" => :eps,
    "7292" => :cost_basis,
    "7293" => :week_52_high,
    "7294" => :week_52_low,
    "7295" => :open,
    "7296" => :close,
    "7308" => :delta,
    "7309" => :gamma,
    "7310" => :theta,
    "7311" => :vega,
    "7607" => :option_volume_change_percent,
    "7633" => :option_implied_vol_percent,
    "7635" => :mark,
    "7636" => :shortable_shares,
    "7637" => :fee_rate,
    "7638" => :option_open_interest,
    "7639" => :percent_of_mark_value,
    "7644" => :shortable,
    "7655" => :morningstar_rating,
    "7671" => :dividends,
    "7672" => :dividends_ttm,
    "7674" => :ema_200,
    "7675" => :ema_100,
    "7676" => :ema_50,
    "7677" => :ema_20,
    "7678" => :price_ema_200_ratio,
    "7679" => :price_ema_100_ratio,
    "7724" => :price_ema_50_ratio,
    "7681" => :price_ema_20_ratio,
    "7682" => :change_since_open,
    "7683" => :upcoming_event,
    "7684" => :upcoming_event_date,
    "7685" => :upcoming_analyst_meeting,
    "7686" => :upcoming_earnings,
    "7687" => :upcoming_misc_event,
    "7688" => :recent_analyst_meeting,
    "7689" => :recent_earnings,
    "7690" => :recent_misc_event,
    "7694" => :probability_max_return,
    "7695" => :break_even,
    "7696" => :spx_delta,
    "7697" => :futures_open_interest,
    "7698" => :last_yield,
    "7699" => :bid_yield,
    "7700" => :probability_max_return_alt,
    "7702" => :probability_max_loss,
    "7703" => :profit_probability,
    "7704" => :organization_type,
    "7705" => :debt_class,
    "7706" => :ratings,
    "7707" => :bond_state_code,
    "7708" => :bond_type,
    "7714" => :last_trading_date,
    "7715" => :issue_date,
    "7718" => :beta,
    "7720" => :ask_yield,
    "7741" => :prior_close,
    "7762" => :volume_long,
    "7768" => :has_trading_permissions,
    "7920" => :daily_pnl_raw,
    "7921" => :cost_basis_raw
  }

  # Private helper function to parse API response and convert to MarketDataSnapshot struct
  defp parse_market_data_response(response_item) do
    # Convert numeric string keys to descriptive struct fields
    parsed_fields =
      response_item
      |> Enum.reduce(%{}, fn {key, value}, acc ->
        case key do
          # Handle special non-numeric keys
          :conid -> Map.put(acc, :conid, value)
          "conid" -> Map.put(acc, :conid, value)
          :server_id -> Map.put(acc, :server_id, value)
          "server_id" -> Map.put(acc, :server_id, value)
          :_updated -> Map.put(acc, :_updated, value)
          "_updated" -> Map.put(acc, :_updated, value)
          "conid_ex" -> Map.put(acc, :conid_ex, value)
          :conid_ex -> Map.put(acc, :conid_ex, value)

          # Handle string keys (including raw fields and numeric keys)
          key_str when is_binary(key_str) ->
            cond do
              # Check if it's a raw field (ends with _raw)
              String.ends_with?(key_str, "_raw") ->
                base_key = String.replace_suffix(key_str, "_raw", "")
                case Map.get(@field_mapping, base_key) do
                  nil -> acc  # Skip unknown raw fields
                  field_atom -> Map.put(acc, String.to_atom("#{field_atom}_raw"), value)
                end

              # Handle numeric string keys
              true ->
                case Map.get(@field_mapping, key_str) do
                  nil -> acc  # Skip unknown fields
                  field_atom -> Map.put(acc, field_atom, value)
                end
            end

          # Handle atom keys (convert to string first)
          key_atom when is_atom(key_atom) ->
            key_str = Atom.to_string(key_atom)
            case Map.get(@field_mapping, key_str) do
              nil -> acc  # Skip unknown fields
              field_atom -> Map.put(acc, field_atom, value)
            end

          _ -> acc  # Skip any other key types
        end
      end)

    # Create the MarketDataSnapshot struct with parsed fields
    struct(MarketDataSnapshot, parsed_fields)
  end
end
