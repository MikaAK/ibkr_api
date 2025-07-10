defmodule IbkrApi.Support.HTTPStubs.AuthStub do
  @moduledoc """
  Stub module for IbkrApi.ClientPortal.Auth HTTP requests.
  """
  
  alias IbkrApi.Support.HTTPMock
  alias IbkrApi.Support.HTTPSandbox

  @base_url "https://localhost:5050/v1/api"
  
  @doc """
  Stubs the reauthenticate endpoint.
  
  ## Examples
      
      AuthStub.stub_reauthenticate()
      # Or with custom response:
      AuthStub.stub_reauthenticate(HTTPMock.success(%{"authenticated" => false}))
  """
  def stub_reauthenticate(response_fn \\ nil) do
    url = "#{@base_url}/iserver/reauthenticate"
    
    default_fn = fn ->
      HTTPMock.success(%{
        "authenticated" => true,
        "message" => "Reauthenticated.",
        "status" => "success"
      })
    end
    
    HTTPSandbox.set_post_responses([{url, response_fn || default_fn}])
  end
  
  @doc """
  Stubs the end_session endpoint.
  
  ## Examples
      
      AuthStub.stub_end_session()
      # Or with custom response:
      AuthStub.stub_end_session(HTTPMock.success(%{"logout" => true}))
  """
  def stub_end_session(response_fn \\ nil) do
    url = "#{@base_url}/logout"
    
    default_fn = fn ->
      HTTPMock.success(%{"logout" => true})
    end
    
    HTTPSandbox.set_post_responses([{url, response_fn || default_fn}])
  end
  
  @doc """
  Stubs the validate_sso endpoint.
  
  ## Examples
      
      AuthStub.stub_validate_sso()
      # Or with custom response:
      AuthStub.stub_validate_sso(HTTPMock.success(%{"RESULT" => true}))
  """
  def stub_validate_sso(response_fn \\ nil) do
    url = "#{@base_url}/sso/validate"
    
    default_fn = fn ->
      HTTPMock.success(%{
        "RESULT" => true,
        "AUTH_TIME" => 1720025745000,
        "EXPIRES" => 1720029345000,
        "USER_NAME" => "testuser",
        "LOGIN_TYPE" => 2
      })
    end
    
    HTTPSandbox.set_get_responses([{url, response_fn || default_fn}])
  end
  
  @doc """
  Stubs the check_auth_status endpoint.
  
  ## Examples
      
      AuthStub.stub_check_auth_status()
      # Or with custom response:
      AuthStub.stub_check_auth_status(HTTPMock.success(%{"authenticated" => true}))
  """
  def stub_check_auth_status(response_fn \\ nil) do
    url = "#{@base_url}/iserver/auth/status"
    
    default_fn = fn ->
      HTTPMock.success(%{
        "authenticated" => true,
        "competing" => false,
        "connected" => true,
        "message" => "",
        "MAC" => "00:00:00:00:00:00",
        "serverInfo" => %{
          "serverName" => "v176-196-15-11-1",
          "serverVersion" => "985.5l"
        }
      })
    end
    
    HTTPSandbox.set_post_responses([{url, response_fn || default_fn}])
  end
  
  @doc """
  Stubs the ping_server endpoint.
  
  ## Examples
      
      AuthStub.stub_ping_server()
      # Or with custom response:
      AuthStub.stub_ping_server(HTTPMock.success(%{"iserver" => %{"authStatus" => %{"authenticated" => true}}}))
  """
  def stub_ping_server(response_fn \\ nil) do
    url = "#{@base_url}/tickle"
    
    default_fn = fn ->
      HTTPMock.success(%{
        "iserver" => %{"authStatus" => %{"authenticated" => true, "connected" => true}},
        "sso" => %{"statusText" => "", "authenticated" => true},
        "server_name" => "v176-196-15-11-1"
      })
    end
    
    HTTPSandbox.set_post_responses([{url, response_fn || default_fn}])
  end
end