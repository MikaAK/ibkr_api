defmodule IbkrApi.Support.HTTPSandbox do
  @moduledoc """
  HTTP sandbox for mocking HTTP requests in tests.
  
  Stores response functions in a Registry under the PID of the test process.
  In test, the IbkrApi.SharedUtils.HTTP module will check this sandbox before
  making actual HTTP requests.
  """
  
  @sleep 10
  @state "state"
  @registry :http_sandbox
  @keys :unique

  @type action :: :get | :post | :put | :delete
  @type url :: String.t()
  @type body :: map() | String.t()
  @type headers :: keyword() | list()
  @type options :: keyword()

  @doc """
  Start the HTTP sandbox registry.
  Should be called from test_helper.exs
  """
  @spec start_link :: {:error, any} | {:ok, pid}
  def start_link do
    Registry.start_link(keys: @keys, name: @registry)
  end
  
  @doc """
  Clears all stored response functions from the registry.
  Should be called in the setup block of each test.
  
  ## Examples
      setup do
        HTTPSandbox.clear()
        :ok
      end
  """
  @spec clear :: :ok
  def clear do
    case Registry.lookup(@registry, @state) do
      [{_pid, _funcs}] ->
        Registry.update_value(@registry, @state, fn _ -> %{} end)
      [] ->
        Registry.register(@registry, @state, %{})
    end
    
    Process.sleep(@sleep)
    :ok
  end
  
  @doc """
  Checks if the HTTP sandbox is disabled.
  Used by the HTTP client to determine whether to use mock responses.
  
  Always returns false in tests, meaning the sandbox is always enabled.
  """
  @spec sandbox_disabled? :: boolean
  def sandbox_disabled? do
    false
  end
  
  @doc """
  Retrieves the response for a HEAD request
  """
  @spec head_response(url, headers, options) :: any
  def head_response(url, headers, options) do
    func = find!(:head, url)

    case :erlang.fun_info(func)[:arity] do
      0 -> func.()
      3 -> func.(url, headers, options)
      _ -> raise_arity_error(func)
    end
  end

  @doc """
  Retrieves the response for a GET request
  """
  @spec get_response(url, headers, options) :: any
  def get_response(url, headers, options) do
    func = find!(:get, url)

    case :erlang.fun_info(func)[:arity] do
      0 -> func.()
      3 -> func.(url, headers, options)
      _ -> raise_arity_error(func)
    end
  end

  @doc """
  Retrieves the response for a POST request
  """
  @spec post_response(url, body, headers, options) :: any
  def post_response(url, body, headers, options) do
    func = find!(:post, url)

    case :erlang.fun_info(func)[:arity] do
      0 -> func.()
      1 -> func.(body)
      3 -> func.(url, headers, options)
      4 -> func.(url, body, headers, options)
      _ -> raise_arity_error(func)
    end
  end

  @doc """
  Retrieves the response for a PUT request
  """
  @spec put_response(url, body, headers, options) :: any
  def put_response(url, body, headers, options) do
    func = find!(:put, url)

    case :erlang.fun_info(func)[:arity] do
      0 -> func.()
      1 -> func.(body)
      3 -> func.(url, headers, options)
      4 -> func.(url, body, headers, options)
      _ -> raise_arity_error(func)
    end
  end

  @doc """
  Retrieves the response for a DELETE request
  """
  @spec delete_response(url, headers, options) :: any
  def delete_response(url, headers, options) do
    func = find!(:delete, url)

    case :erlang.fun_info(func)[:arity] do
      0 -> func.()
      3 -> func.(url, headers, options)
      _ -> raise_arity_error(func)
    end
  end

  @doc """
  Sets sandbox responses for GET requests.
  
  ## Examples
      
      HTTPSandbox.set_get_responses([
        {"https://localhost:5000/v1/api/iserver/auth/status", fn -> 
          {:ok, %{
            "authenticated" => true,
            "competing" => false,
            "connected" => true,
            "message" => ""
          }, %IbkrApi.SharedUtils.HTTP.Response{status: 200}} 
        end}
      ])
  """
  @spec set_get_responses([{String.t(), fun}]) :: :ok
  def set_get_responses(tuples) do
    tuples
    |> Map.new(fn {url, func} -> {{:get, url}, func} end)
    |> register_responses()
  end

  @doc """
  Sets sandbox responses for POST requests.
  
  ## Examples
      
      HTTPSandbox.set_post_responses([
        {"https://localhost:5000/v1/api/iserver/account", fn -> 
          {:ok, %{"acctId" => "U12345678"}, %IbkrApi.SharedUtils.HTTP.Response{status: 200}} 
        end}
      ])
  """
  @spec set_post_responses([{String.t(), fun}]) :: :ok
  def set_post_responses(tuples) do
    tuples
    |> Map.new(fn {url, func} -> {{:post, url}, func} end)
    |> register_responses()
  end

  @doc """
  Sets sandbox responses for PUT requests.
  
  ## Examples
      
      HTTPSandbox.set_put_responses([
        {"https://localhost:5000/v1/api/iserver/account/orders", fn -> 
          {:ok, %{"id" => "12345"}, %IbkrApi.SharedUtils.HTTP.Response{status: 200}} 
        end}
      ])
  """
  @spec set_put_responses([{String.t(), fun}]) :: :ok
  def set_put_responses(tuples) do
    tuples
    |> Map.new(fn {url, func} -> {{:put, url}, func} end)
    |> register_responses()
  end

  @doc """
  Sets sandbox responses for DELETE requests.
  
  ## Examples
      
      HTTPSandbox.set_delete_responses([
        {"https://localhost:5000/v1/api/iserver/account/order/12345", fn -> 
          {:ok, %{"id" => "12345"}, %IbkrApi.SharedUtils.HTTP.Response{status: 200}} 
        end}
      ])
  """
  @spec set_delete_responses([{String.t(), fun}]) :: :ok
  def set_delete_responses(tuples) do
    tuples
    |> Map.new(fn {url, func} -> {{:delete, url}, func} end)
    |> register_responses()
  end
  
  @doc """
  Sets sandbox responses for HEAD requests.
  
  ## Examples
      
      HTTPSandbox.set_head_responses([
        {"https://localhost:5000/v1/api/iserver/auth/status", fn -> 
          {:ok, %{}, %IbkrApi.SharedUtils.HTTP.Response{status: 200}} 
        end}
      ])
  """
  @spec set_head_responses([{String.t(), fun}]) :: :ok
  def set_head_responses(tuples) do
    tuples
    |> Map.new(fn {url, func} -> {{:head, url}, func} end)
    |> register_responses()
  end

  @doc """
  Finds the appropriate response function for the given action and URL.
  Returns the function or raises an error.
  """
  @spec find!(action, url) :: fun
  def find!(action, url) do
    case Registry.lookup(@registry, @state) do
      [{_pid, funcs}] ->
        find_response!(funcs, action, url)

      [] ->
        raise """
        No HTTP sandbox responses registered for #{inspect(self())}
        Action: #{inspect(action)}
        URL: #{inspect(url)}

        ======= Use: =======
        #{format_example(action, url)}
        === in your test ===
        """
    end
  end

  # Register responses in the registry
  defp register_responses(responses) do
    case Registry.lookup(@registry, @state) do
      [{_pid, _existing}] ->
        Registry.update_value(@registry, @state, &Map.merge(&1, responses))
      [] ->
        Registry.register(@registry, @state, responses)
    end

    Process.sleep(@sleep)
    :ok
  end

  # Find the appropriate response function
  defp find_response!(funcs, action, url) do
    key = {action, url}

    case Map.get(funcs, key) do
      nil ->
        # Try regex matching
        regex_match = Enum.find(funcs, fn {{act, pattern}, _} -> 
          act == action && is_struct(pattern, Regex) && Regex.match?(pattern, url)
        end)
        
        case regex_match do
          {{_, _}, func} when is_function(func) -> func
          nil -> raise_function_not_found(action, url, funcs)
        end
        
      func when is_function(func) ->
        func
    end
  end

  # Helper for raising arity errors
  defp raise_arity_error(func) do
    raise """
    This function's signature is not supported.
    #{inspect(func)}
    Please provide a function with appropriate arity for the HTTP method.
    """
  end

  # Helper for raising function not found errors
  defp raise_function_not_found(action, url, funcs) do
    functions_text = 
      Enum.map_join(funcs, "\n", fn {k, v} -> "#{inspect(k)}    =>    #{inspect(v)}" end)
    
    raise """
    Function not found for {#{inspect(action)}, #{inspect(url)}} in #{inspect(self())}
    
    Found:
    #{functions_text}
    
    ======= Use: =======
    #{format_example(action, url)}
    === in your test ===
    """
  end

  # Helper for generating example usage
  defp format_example(action, url) do
    """
    alias IbkrApi.Support.HTTPSandbox
    
    setup do
      HTTPSandbox.set_#{action}_responses([
        {#{inspect(url)}, fn -> 
          {:ok, response_data, %IbkrApi.SharedUtils.HTTP.Response{status: 200}}
        end}
        # or for regex matching:
        {~r|https://localhost:5000/v1/api|, fn -> response end}
      ])
    end
    """
  end
end