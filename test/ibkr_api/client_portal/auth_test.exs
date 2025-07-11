defmodule IbkrApi.ClientPortal.AuthTest do
  use ExUnit.Case
  
  alias IbkrApi.ClientPortal.Auth
  alias IbkrApi.Support.HTTPMock
  alias IbkrApi.Support.HTTPStubs.AuthStub

  describe "auth_status/0" do
    test "returns authentication status with default mock" do
      # Mock the auth_status HTTP call with default response
      AuthStub.stub_check_auth_status()
      
      # Call the function
      assert {:ok, status} = Auth.check_auth_status()
      
      # Verify the response
      assert status.authenticated
      assert status.connected
      assert status.server_info.server_name != nil
      assert status.message == ""
    end
    
    test "returns custom authentication status with custom mock" do
      # Create a custom response
      custom_status = %{
        :authenticated => false,
        :competing => true,
        :fail => "Another session is already authenticated",
        :message => "Competing session"
      }
      
      # Use the custom response in the mock
      AuthStub.stub_check_auth_status(fn -> HTTPMock.success(custom_status) end)
      
      # Call the function
      assert {:ok, status} = Auth.check_auth_status()
      
      # Verify the response
      refute status.authenticated
      assert status.competing
      assert status.message == "Competing session"
    end
    
    test "handles error response" do
      # Mock an error response
      error_response = %{"error" => "Unable to retrieve authentication status", "code" => 1234}
      AuthStub.stub_check_auth_status(fn -> HTTPMock.error(error_response, 400) end)
      
      # Call the function
      assert {:error, error} = Auth.check_auth_status()
      assert error.status == 400
    end
    
    test "handles network error" do
      # Mock a network error
      AuthStub.stub_check_auth_status(fn -> HTTPMock.network_error(:timeout) end)
      
      # Call the function
      assert {:error, :timeout} = Auth.check_auth_status()
    end
  end
  
  describe "reauthenticate/0" do
    test "successfully reauthenticates with default mock" do
      AuthStub.stub_reauthenticate()
      
      assert {:ok, result} = Auth.reauthenticate()
      assert result.message == "Reauthenticated."
    end
    
    test "fails to reauthenticate with custom mock" do
      # Create a custom failure response
      AuthStub.stub_reauthenticate(fn -> HTTPMock.success(%{:message => "Failed to reauthenticate"}) end)
      
      assert {:ok, result} = Auth.reauthenticate()
      assert result.message == "Failed to reauthenticate"
    end
  end
  
  describe "validate/0" do
    test "successfully validates with default mock" do
      AuthStub.stub_validate_sso()
      
      assert {:ok, result} = Auth.validate_sso()
      assert result.result
    end
  end
  
  describe "tickle/0" do
    test "ping_server/0 successfully pings session with default mock" do
      AuthStub.stub_ping_server()
      
      assert {:ok, result} = Auth.ping_server()
      assert result.iserver.auth_status.authenticated
    end
  end
  
  describe "end_session/0" do
    test "successfully logs out with default mock" do
      AuthStub.stub_end_session()
      
      assert {:ok, result} = Auth.end_session()
      assert result.status
    end
  end
  
  test "chaining multiple auth operations" do
    # Set up multiple stubs for a workflow test
    AuthStub.stub_check_auth_status()
    AuthStub.stub_validate_sso()
    AuthStub.stub_ping_server()
    AuthStub.stub_end_session()
    
    # Check auth status
    assert {:ok, status} = Auth.check_auth_status()
    assert status.authenticated
    
    # Validate SSO token
    assert {:ok, validate_result} = Auth.validate_sso()
    assert validate_result.result
    
    # Ping the server
    assert {:ok, tickle_result} = Auth.ping_server()
    assert tickle_result.iserver.auth_status.authenticated
    
    # Logout
    assert {:ok, result} = Auth.end_session()
    assert result.status
  end
end