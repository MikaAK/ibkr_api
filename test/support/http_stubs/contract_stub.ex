defmodule IbkrApi.Support.HTTPStubs.ContractStub do
  @moduledoc """
  Stub module for IbkrApi.ClientPortal.Contract HTTP requests.
  """
  
  alias IbkrApi.Support.HTTPMock
  alias IbkrApi.Support.HTTPSandbox

  @base_url "https://localhost:5050/v1/api"
  
  @doc """
  Stubs the contract info endpoint.
  """
  def stub_contract_info(response_fn \\ nil) do
    url = "#{@base_url}/iserver/contract/info"
    
    default_fn = fn ->
      HTTPMock.success(%{
        "symbol" => "AAPL",
        "company_name" => "APPLE INC",
        "exchange" => "NASDAQ",
        "conid" => 265598,
        "currency" => "USD",
        "instrument_type" => "STK"
      })
    end
    
    HTTPSandbox.set_post_responses([{url, response_fn || default_fn}])
  end
  
  @doc """
  Stubs the stocks by symbol endpoint.
  """
  def stub_stocks_by_symbol(response_fn \\ nil) do
    url_pattern = ~r{#{@base_url}/trsrv/stocks\?symbols=.*}
    
    default_fn = fn ->
      HTTPMock.success([
        %{
          "symbol" => "AAPL",
          "description" => "APPLE INC",
          "conid" => 265598,
          "exchange" => "NASDAQ",
          "type" => "cs",
          "data" => %{"chineseName" => ""}
        }
      ])
    end
    
    HTTPSandbox.set_get_responses([{url_pattern, response_fn || default_fn}])
  end
  
  @doc """
  Stubs the futures by symbol endpoint.
  """
  def stub_futures_by_symbol(response_fn \\ nil) do
    url_pattern = ~r{#{@base_url}/trsrv/futures\?symbols=.*}
    
    default_fn = fn ->
      HTTPMock.success([
        %{
          "symbol" => "ES",
          "description" => "E-mini S&P 500",
          "conid" => 371767438,
          "exchange" => "CME"
        }
      ])
    end
    
    HTTPSandbox.set_get_responses([{url_pattern, response_fn || default_fn}])
  end
  
  @doc """
  Stubs the trading schedule endpoint.
  """
  def stub_trading_schedule(response_fn \\ nil) do
    url_pattern = ~r{#{@base_url}/trsrv/secdef/schedule\?conid=.*}
    
    default_fn = fn ->
      HTTPMock.success(%{
        "id" => 265598,
        "schedules" => [
          %{
            "date" => "20250710",
            "sessions" => [
              %{
                "exchange" => "NASDAQ",
                "type" => "REGULAR_SESSION",
                "times" => [
                  %{
                    "open" => "0930",
                    "close" => "1600"
                  }
                ]
              }
            ]
          }
        ]
      })
    end
    
    HTTPSandbox.set_get_responses([{url_pattern, response_fn || default_fn}])
  end
  
  @doc """
  Stubs the search by symbol endpoint.
  """
  def stub_search_by_symbol(response_fn \\ nil) do
    url_pattern = ~r{#{@base_url}/iserver/secdef/search\?symbol=.*}
    
    default_fn = fn ->
      HTTPMock.success([
        %{
          "conid" => 265598,
          "symbol" => "AAPL",
          "description" => "APPLE INC",
          "companyHeader" => "Apple Inc. (AAPL)",
          "companyName" => "Apple Inc.",
          "sections" => [
            %{
              "secType" => "STK",
              "exchange" => "NASDAQ",
              "conid" => "265598"
            },
            %{
              "secType" => "OPT",
              "months" => "JUL25 AUG25 SEP25 OCT25",
              "conid" => "265598"
            }
          ]
        }
      ])
    end
    
    HTTPSandbox.set_get_responses([{url_pattern, response_fn || default_fn}])
  end
  
  @doc """
  Stubs the exchange rate endpoint.
  """
  def stub_exchange_rate(response_fn \\ nil) do
    url_pattern = ~r{#{@base_url}/portal/iserver/marketdata/unsubscribe.*}
    
    default_fn = fn ->
      HTTPMock.success(%{
        "rate" => 0.85,
        "fromCurrency" => "USD",
        "toCurrency" => "EUR"
      })
    end
    
    HTTPSandbox.set_get_responses([{url_pattern, response_fn || default_fn}])
  end
  
  @doc """
  Stubs the currency pairs endpoint.
  """
  def stub_currency_pairs(response_fn \\ nil) do
    url = "#{@base_url}/portal/portfolio/positions/c-currency-pairs"
    
    default_fn = fn ->
      HTTPMock.success([
        %{"symbol" => "EUR.USD", "fromCurrency" => "EUR", "toCurrency" => "USD"},
        %{"symbol" => "USD.JPY", "fromCurrency" => "USD", "toCurrency" => "JPY"},
        %{"symbol" => "GBP.USD", "fromCurrency" => "GBP", "toCurrency" => "USD"}
      ])
    end
    
    HTTPSandbox.set_get_responses([{url, response_fn || default_fn}])
  end
  
  @doc """
  Stubs the secdef by conid endpoint.
  """
  def stub_secdef_by_conid(response_fn \\ nil) do
    url_pattern = ~r{#{@base_url}/iserver/secdef/info.*}
    
    default_fn = fn ->
      HTTPMock.success(%{
        "symbol" => "AAPL",
        "fullName" => "APPLE INC",
        "conid" => 265598,
        "assetClass" => "STK"
      })
    end
    
    HTTPSandbox.set_get_responses([{url_pattern, response_fn || default_fn}])
  end
  
  @doc """
  Stubs the search contracts endpoint.
  """
  def stub_search_contracts(response_fn \\ nil) do
    url_pattern = ~r{#{@base_url}/iserver/secdef/search}
    
    default_fn = fn ->
      HTTPMock.success([
        %{
          "conid" => "265598",
          "symbol" => "AAPL",
          "company_name" => "APPLE INC",
          "company_header" => "APPLE INC",
          "description" => "Apple Inc. Common Stock",
          "restricted" => false,
          "fop" => false,
          "opt" => true,
          "war" => false,
          "sections" => [
            %{
              "sec_type" => "STK",
              "exchange" => "NASDAQ",
              "conid" => "265598",
              "months" => []
            },
            %{
              "sec_type" => "OPT",
              "exchange" => "NASDAQ",
              "conid" => "265598",
              "months" => ["JUL25", "AUG25", "OCT25"]
            }
          ],
          "issuers" => []
        }
      ])
    end
    
    HTTPSandbox.set_get_responses([{url_pattern, response_fn || default_fn}])
  end
  
  @doc """
  Stubs the get strikes endpoint.
  """
  def stub_get_strikes(response_fn \\ nil) do
    url_pattern = ~r{#{@base_url}/iserver/secdef/strikes}
    
    default_fn = fn ->
      HTTPMock.success(%{
        "call" => ["140", "145", "150", "155", "160"],
        "put" => ["140", "145", "150", "155", "160"]
      })
    end
    
    HTTPSandbox.set_get_responses([{url_pattern, response_fn || default_fn}])
  end
  
  @doc """
  Stubs the symbol info endpoint.
  """
  def stub_symbol_info(response_fn \\ nil) do
    url_pattern = ~r{#{@base_url}/iserver/marketdata/symbol.*}
    
    default_fn = fn ->
      HTTPMock.success(%{
        "31" => "APPLE INC",
        "55" => "NASDAQ",
        "6004" => "AAPL",
        "6008" => "STK",
        "conid" => 265598,
        "minTick" => "0.01"
      })
    end
    
    HTTPSandbox.set_get_responses([{url_pattern, response_fn || default_fn}])
  end
  
  @doc """
  Stubs the all conids by exchange endpoint.
  """
  def stub_all_conids_by_exchange(response_fn \\ nil) do
    url_pattern = ~r{#{@base_url}/trsrv/stocks/allConids.*}
    
    default_fn = fn ->
      HTTPMock.success([
        %{"conid" => 265598, "symbol" => "AAPL"},
        %{"conid" => 8894, "symbol" => "IBM"},
        %{"conid" => 272093, "symbol" => "MSFT"}
      ])
    end
    
    HTTPSandbox.set_get_responses([{url_pattern, response_fn || default_fn}])
  end
end