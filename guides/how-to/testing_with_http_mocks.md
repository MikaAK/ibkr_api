# Testing with HTTP Mocks

This guide explains how to use the HTTP mocking system when writing tests for the IBKR API client.

> #### Why Use HTTP Mocks? {: .info}
>
> The IBKR API client uses a registry-based HTTP mocking system called `HTTPSandbox` to simulate HTTP responses during testing. This approach allows tests to run without making actual HTTP requests to the IBKR API servers, making them **faster**, **more reliable**, and **independent of external services**.

## Overview

The mocking system consists of:

1. **`HTTPSandbox`** - A registry that stores mock HTTP responses
2. **`HTTPMock`** - Helper functions for creating different types of responses
3. **Stub Modules** - Convenience modules that provide functions for mocking specific API endpoints

## Setting Up Tests

### Starting the Sandbox Registry

The HTTPSandbox registry is automatically started in `test_helper.exs`. Make sure your test helper includes:

```elixir
# Start the HTTPSandbox registry for HTTP mocks
IbkrApi.Support.HTTPSandbox.start_link()
```

## Using Stub Modules

The easiest way to mock HTTP endpoints is to use the provided stub modules:

- `IbkrApi.Support.HTTPStubs.AuthStub`
- `IbkrApi.Support.HTTPStubs.ContractStub`
- `IbkrApi.Support.HTTPStubs.MarketDataStub`
- `IbkrApi.Support.HTTPStubs.OrderStub`
- `IbkrApi.Support.HTTPStubs.PortfolioStub`
- `IbkrApi.Support.HTTPStubs.TradeStub`

### Example: Using Default Mocks

```elixir
# Import the stub module
alias IbkrApi.Support.HTTPStubs.AuthStub

# Set up the default mock
AuthStub.stub_auth_status()

# Call the function that uses the HTTP endpoint
{:ok, status} = IbkrApi.ClientPortal.Auth.auth_status()
```

### Example: Using Custom Response

```elixir
alias IbkrApi.Support.HTTPStubs.AuthStub
alias IbkrApi.Support.HTTPMock

# Create a custom response
custom_status = %{
  "authenticated" => false,
  "competing" => true,
  "message" => "Competing session"
}

# Use the custom response in the mock
AuthStub.stub_auth_status(fn -> HTTPMock.success(custom_status) end)

# Call the function
{:ok, status} = IbkrApi.ClientPortal.Auth.auth_status()
```

## Creating Different Response Types

### Success Response

```elixir
# Simple success response
HTTPMock.success(%{"status" => "ok"})

# Success response with custom status code
HTTPMock.success(%{"status" => "created"}, 201)
```

### Error Response

```elixir
# Error response
HTTPMock.error(%{"error" => "Not found"}, 404)
```

### Network Error

```elixir
# Network error
HTTPMock.network_error(:timeout)
HTTPMock.network_error(:nxdomain)
HTTPMock.network_error(:econnrefused)
```

## Testing Different Scenarios

### Testing Success Cases

```elixir
test "returns authentication status with default mock" do
  # Mock the auth_status HTTP call with default response
  AuthStub.stub_auth_status()
  
  # Call the function
  assert {:ok, status} = Auth.auth_status()
  
  # Verify response
  assert status.authenticated
end
```

### Testing Error Handling

```elixir
test "handles error response" do
  # Mock an error response
  error_response = %{"error" => "Unable to retrieve authentication status", "code" => 1234}
  AuthStub.stub_auth_status(fn -> HTTPMock.error(error_response, 400) end)
  
  # Call the function
  assert {:error, error} = Auth.auth_status()
  assert error.status == 400
end
```

### Testing Network Errors

```elixir
test "handles network error" do
  # Mock a network error
  AuthStub.stub_auth_status(fn -> HTTPMock.network_error(:timeout) end)
  
  # Call the function
  assert {:error, :timeout} = Auth.auth_status()
end
```

## Testing Complex Workflows

You can set up multiple mocks to test complex workflows:

```elixir
test "chaining multiple auth operations" do
  # Set up multiple stubs for a workflow test
  AuthStub.stub_auth_status()
  AuthStub.stub_validate()
  AuthStub.stub_tickle()
  AuthStub.stub_logout()
  
  # Check auth status
  assert {:ok, status} = Auth.auth_status()
  assert status.authenticated
  
  # Validate session
  assert {:ok, validation} = Auth.validate()
  assert validation.success
  
  # Tickle session
  assert {:ok, tickle_result} = Auth.tickle()
  assert tickle_result.success
  
  # Logout
  assert {:ok, logout_result} = Auth.logout()
  assert logout_result.success
end
```

## Creating Custom Stub Functions

If you need to mock an endpoint that doesn't have a stub function yet, you can create one:

```elixir
# In your test module
alias IbkrApi.Support.HTTPSandbox

def setup_custom_endpoint_mock(response_fn \\ nil) do
  default_response = fn -> HTTPMock.success(%{"data" => "default"}) end
  response = response_fn || default_response
  
  HTTPSandbox.set_get_responses([
    {~r|/v1/api/custom/endpoint|, response}
  ])
end
```

## Advanced: URL Pattern Matching

Stub functions use regular expressions to match URLs, which allows for flexible mocking:

```elixir
# Match exact URL
HTTPSandbox.set_get_responses([{"/v1/api/exact/path", response_fn}])

# Match URL with parameter
HTTPSandbox.set_get_responses([{~r|/v1/api/items/\d+|, response_fn}])

# Match URL with query parameters
HTTPSandbox.set_get_responses([{~r|/v1/api/search\?query=.*|, response_fn}])
```

## Implementing New Stub Modules

If you need to create a new stub module for another API category, follow this pattern:

```elixir
defmodule IbkrApi.Support.HTTPStubs.NewStub do
  @moduledoc """
  HTTP stubs for the New API endpoints.
  """
  
  alias IbkrApi.Support.HTTPSandbox
  alias IbkrApi.Support.HTTPMock
  
  @default_response %{
    "result" => "success",
    "data" => %{}
  }
  
  def stub_new_endpoint(response_fn \\ nil) do
    default_response = fn -> HTTPMock.success(@default_response) end
    response = response_fn || default_response
    
    HTTPSandbox.set_get_responses([
      {~r|/v1/api/new/endpoint|, response}
    ])
  end
end
```

## Test Example

Here's a complete example of a test file using HTTP mocks:

```elixir
defmodule IbkrApi.ClientPortal.AuthTest do
  use ExUnit.Case
  
  alias IbkrApi.ClientPortal.Auth
  alias IbkrApi.Support.HTTPMock
  alias IbkrApi.Support.HTTPStubs.AuthStub

  describe "auth_status/0" do
    test "returns authentication status with default mock" do
      AuthStub.stub_auth_status()
      
      assert {:ok, status} = Auth.auth_status()
      assert status.authenticated
    end
    
    test "returns custom authentication status" do
      custom_status = %{
        "authenticated" => false,
        "competing" => true,
        "message" => "Competing session"
      }
      
      AuthStub.stub_auth_status(fn -> HTTPMock.success(custom_status) end)
      
      assert {:ok, status} = Auth.auth_status()
      assert status.authenticated == false
    end
  end
end
```

## Working with Struct Responses

API functions return structured Elixir data using structs, not raw maps. Test assertions should use struct field access notation (`.field`) instead of map access notation (`["field"]`).

### ❌ Incorrect (Using Map Keys):

```elixir
assert {:ok, status} = Auth.check_auth_status()
assert status["authenticated"]
assert status["serverInfo"]["serverName"] != nil
```

### ✅ Correct (Using Struct Fields):

```elixir
assert {:ok, status} = Auth.check_auth_status()
assert %Auth.CheckAuthStatusResponse{} = status  # Verify the struct type
assert status.authenticated
assert status.server_info.server_name != nil
```

## Troubleshooting

### Common Issues

1. **Incorrect HTTP Method**: Ensure you're using the correct HTTP method (GET, POST, PUT, DELETE) in your stubs:

   ```elixir
   # For GET endpoints
   HTTPSandbox.set_get_responses([{pattern, response_fn}])
   
   # For POST endpoints
   HTTPSandbox.set_post_responses([{pattern, response_fn}])
   ```

2. **Mismatched Return Values**: Ensure your test assertions match the actual function return signatures:

   ```elixir
   # If the function returns {:ok, struct}
   assert {:ok, result} = Module.function()
   
   # If the function returns {:ok, struct, response}
   assert {:ok, result, response} = Module.function()
   ```

4. **Pattern Not Matching**: If your stub isn't being used, check the URL pattern:

   ```elixir
   # Debug by inspecting the request URL
   IbkrApi.Support.HTTPSandbox.set_get_responses([
     {~r|/path/to/endpoint|, fn url ->
       HTTPMock.success(%{})
     end}
   ])
   ```

## Summary

- Use `HTTPSandbox` to store and retrieve mock HTTP responses
- Use stub modules like `AuthStub` for convenience functions
- Create default or custom responses with `HTTPMock` helpers
- Mock different response types: success, error, and network errors
- Test complex workflows by setting up multiple endpoint mocks
- Assert on struct fields (`.field`) not map keys (`["key"]`)
- Always validate struct types with pattern matching
