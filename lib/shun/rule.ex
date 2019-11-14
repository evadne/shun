defmodule Shun.Rule do
  @moduledoc """
  Represents what should be done based on the target pattern, which can represent an URI, IPv4,
  or IPv6 address. It can also be given a String literal, which represents either an IPv4 or IPv6
  address, or a range of addresses using CIDR notation.

  Since the Rule module only emits results based on target patterns (i.e. Elixir AST), it is best
  used from macros, such as those found within `Shun.Builder`, which can implement macros.
  """

  alias Shun.Provider

  @typedoc """
  Represents a Rule that is built and can be used at compile-time.

  Rules are understood by `Shun.Builder`.
  """
  @opaque t :: __MODULE__.Range.t() | __MODULE__.Pattern.t()

  @typedoc """
  Represents a handler function, to be used with `handle/2`.
  """
  @type handle_fun :: Provider.dynamic_uri_fun() | Provider.dynamic_address_fun()

  @spec accept(__MODULE__.Target.t()) :: t()
  @spec reject(__MODULE__.Target.t()) :: t()
  @spec handle(__MODULE__.Target.t(), handle_fun) :: t()

  defmodule MalformedError do
    @moduledoc """
    Represents a compile-time error when the pattern used to build a Rule is not valid.
    """

    defexception message: nil

    @impl true
    def exception(value) do
      %__MODULE__{message: "invalid pattern: #{inspect(value)}"}
    end
  end

  @doc """
  Generates an Accept rule for the given Target.

  Expects a target conforming to `t:Shun.Rule.Target.t/0`.
  """
  def accept(pattern) do
    build_rule(pattern, :accept)
  end

  @doc """
  Generates a Reject rule for the given Target.

  Expects a target conforming to `t:Shun.Rule.Target.t/0`.
  """
  def reject(pattern) do
    build_rule(pattern, :reject)
  end

  @doc """
  Generates a Dynamic rule for the given Target.

  Expects a target conforming to `t:Shun.Rule.Target.t/0`.

  The second argument must refer to a function, which accepts either an URI or an Address.

  ## Example

  You can use `handle/2` to implement a Rule which will call your function at runtime if the value
  was matched.

      defmodule MyApp.Shun do
        use Shun.Builder
        handle %URI{}, &custom_handle_uri/1

        def custom_handle_uri(uri) do
          cond do
            MyApp.Whitelist.allow_host?(uri.host) -> :accept
            true -> :reject
          end
        end
      end

  You can also use guards with `handle/2`:

      defmodule MyApp.Shun do
        use Shun.Builder
        handle %URI{host: host} when host == "example.com", &custom_handle_uri/1
        
        …
      end
  """
  def handle(pattern, handler) do
    build_rule(pattern, {:dynamic, handler})
  end

  defp build_rule(pattern, action) do
    case __MODULE__.Target.classify(pattern) do
      {:pattern, type} -> __MODULE__.Pattern.build(type, pattern, true, action)
      {:pattern, type, pattern} -> __MODULE__.Pattern.build(type, pattern, true, action)
      {:pattern, type, pattern, guard} -> __MODULE__.Pattern.build(type, pattern, guard, action)
      {:range, type, from, to} -> __MODULE__.Range.build(type, from, to, action)
      :error -> raise __MODULE__.MalformedError, value: pattern
    end
  end

  @doc false
  def has_pattern_fallback?(rules, type) do
    Enum.any?(rules, &is_pattern_fallback?(&1, type))
  end

  defp is_pattern_fallback?(rule, :uri) do
    case rule do
      %{type: :uri, pattern: {:%, _, [_, {:%{}, _, []}]}, guard: true} -> true
      _ -> false
    end
  end

  defp is_pattern_fallback?(rule, type) when type in ~w(ipv4 ipv6)a do
    with %{type: ^type, pattern: {:{}, _, elements}, guard: true} <- rule do
      Enum.all?(elements, fn
        {:_, _, _} -> true
        _ -> false
      end)
    else
      _ -> false
    end
  end
end
