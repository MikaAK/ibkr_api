defmodule IbkrApi.Support.HTTPStubs.OrderStub do
  @moduledoc """
  Stub module for IbkrApi.ClientPortal.Order HTTP requests.
  """
  
  alias IbkrApi.Support.HTTPMock
  alias IbkrApi.Support.HTTPSandbox

  @base_url "https://localhost:5000/v1/api"
  
  @doc """
  Stubs the list_orders endpoint.
  
  ## Examples
      
      OrderStub.stub_list_orders()
      # Or with custom response:
      OrderStub.stub_list_orders(HTTPMock.success([%{"orderId" => "12345", "symbol" => "MSFT", ...}]))
  """
  def stub_list_orders(response_fn \\ nil) do
    url = "#{@base_url}/iserver/account/orders"
    
    default_fn = fn ->
      HTTPMock.success([
        %{
          "acct" => "U12345678",
          "conid" => 265598,
          "orderId" => "987654321",
          "cashCcy" => "USD",
          "sizeAndFills" => "100/0",
          "orderDesc" => "BUY 100 LIMIT 151.50",
          "description1" => "AAPL",
          "ticker" => "AAPL",
          "secType" => "STK",
          "listingExchange" => "NASDAQ",
          "remainingQuantity" => 100.0,
          "filledQuantity" => 0.0,
          "status" => "PendingSubmit",
          "origOrderType" => "LIMIT",
          "side" => "BUY",
          "price" => 151.50,
          "timeInForce" => "GTC",
          "lastExecutionTime" => 0
        }
      ])
    end
    
    HTTPSandbox.set_get_responses([{url, response_fn || default_fn}])
  end
  
  @doc """
  Stubs the get_order_status endpoint.
  """
  def stub_get_order_status(response_fn \\ nil) do
    url_pattern = ~r{#{@base_url}/iserver/account/order/status/\d+}
    
    default_fn = fn ->
      HTTPMock.success(%{
        "orderId" => "987654321",
        "conid" => 265598,
        "symbol" => "AAPL",
        "side" => "BUY",
        "orderType" => "LIMIT",
        "price" => 151.50,
        "quantity" => 100.0,
        "filled" => 0.0,
        "remaining" => 100.0,
        "status" => "PendingSubmit",
        "timeInForce" => "GTC",
        "order_ref" => "API_12345",
        "timestamp" => 1720025740000,
        "outsideRth" => false
      })
    end
    
    HTTPSandbox.set_get_responses([{url_pattern, response_fn || default_fn}])
  end
  
  @doc """
  Stubs the modify_order endpoint.
  """
  def stub_modify_order(response_fn \\ nil) do
    url_pattern = ~r{#{@base_url}/iserver/account/\w+/order/\d+}
    
    default_fn = fn ->
      HTTPMock.success(%{
        "order_id" => "987654321",
        "local_order_id" => 0,
        "order_status" => "PreSubmitted"
      })
    end
    
    HTTPSandbox.set_post_responses([{url_pattern, response_fn || default_fn}])
  end
  
  @doc """
  Stubs the delete_order endpoint.
  """
  def stub_delete_order(response_fn \\ nil) do
    url_pattern = ~r{#{@base_url}/iserver/account/\w+/order/\d+}
    
    default_fn = fn ->
      HTTPMock.success(%{
        "order_id" => "987654321",
        "local_order_id" => 0,
        "order_status" => "Cancelled"
      })
    end
    
    HTTPSandbox.set_delete_responses([{url_pattern, response_fn || default_fn}])
  end
  
  @doc """
  Stubs the what_if endpoint.
  """
  def stub_what_if(response_fn \\ nil) do
    url = "#{@base_url}/iserver/account/whatif"
    
    default_fn = fn ->
      HTTPMock.success(%{
        "amount" => -15150.0,
        "initial" => %{"value" => "0.00", "currency" => "USD"},
        "current" => %{"value" => "0.00", "currency" => "USD"},
        "change" => %{"value" => "0.00", "currency" => "USD"},
        "maintenance" => %{"value" => "3,030.00", "currency" => "USD"},
        "warn" => nil,
        "error" => nil
      })
    end
    
    HTTPSandbox.set_post_responses([{url, response_fn || default_fn}])
  end
  
  @doc """
  Stubs the place_order endpoint.
  """
  def stub_place_order(response_fn \\ nil) do
    url = "#{@base_url}/iserver/account/U12345678/orders"
    
    default_fn = fn ->
      HTTPMock.success([
        %{
          "id" => "987654321",
          "message" => "Order Submitted",
          "order_id" => "987654321",
          "order_status" => "PreSubmitted",
          "warning_message" => ""
        }
      ])
    end
    
    HTTPSandbox.set_post_responses([{url, response_fn || default_fn}])
  end
  
  @doc """
  Stubs the place_order_for_fa_group endpoint.
  """
  def stub_place_order_for_fa_group(response_fn \\ nil) do
    url = "#{@base_url}/iserver/account/orders"
    
    default_fn = fn ->
      HTTPMock.success([
        %{
          "id" => "987654321",
          "message" => "Order Submitted",
          "order_id" => "987654321",
          "order_status" => "PreSubmitted",
          "warning_message" => ""
        }
      ])
    end
    
    HTTPSandbox.set_post_responses([{url, response_fn || default_fn}])
  end
  
  @doc """
  Stubs the place_order_reply endpoint.
  """
  def stub_place_order_reply(response_fn \\ nil) do
    url_pattern = ~r{#{@base_url}/iserver/reply/\w+}
    
    default_fn = fn ->
      HTTPMock.success([
        %{
          "id" => "987654321",
          "message" => "Order Confirmed",
          "order_id" => "987654321",
          "order_status" => "Submitted",
          "warning_message" => ""
        }
      ])
    end
    
    HTTPSandbox.set_post_responses([{url_pattern, response_fn || default_fn}])
  end
end