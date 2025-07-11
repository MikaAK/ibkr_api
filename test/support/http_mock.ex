defmodule IbkrApi.Support.HTTPMock do
  @moduledoc """
  Helper functions for creating mock HTTP responses.
  
  This module provides functions for creating standard response formats
  for success responses, error responses, and network errors.
  """
  
  alias IbkrApi.SharedUtils.HTTP.Response

  @doc """
  Creates a successful HTTP response.
  
  ## Parameters
  - `body`: The response body (map or list)
  - `status`: HTTP status code (default: 200)
  - `headers`: Response headers (default: [])
  
  ## Examples
      
      HTTPMock.success(%{"id" => 1, "name" => "Item"})
      # Returns: {:ok, {%{"id" => 1, "name" => "Item"}, %Response{status: 200}}}
  """
  def success(body, status \\ 200, headers \\ []) do
    {:ok, {body, %Response{status: status, headers: headers, body: body}}}
  end

  @doc """
  Creates an error HTTP response.
  
  ## Parameters
  - `error_body`: The error response body (map)
  - `status`: HTTP status code (default: 400)
  - `headers`: Response headers (default: [])
  
  ## Examples
      
      HTTPMock.error(%{"error" => "Invalid request"}, 400)
      # Returns: {:error, %Response{status: 400, body: %{"error" => "Invalid request"}}}
  """
  def error(error_body, status \\ 400, headers \\ []) do
    {:error, %Response{
      status: status,
      body: error_body,
      headers: headers
    }}
  end
  
  @doc """
  Creates a network error response.
  
  ## Parameters
  - `reason`: The error reason (:timeout, :closed, etc.)
  
  ## Examples
      
      HTTPMock.network_error(:timeout)
      # Returns: {:error, :timeout}
  """
  def network_error(reason) do
    {:error, reason}
  end
end