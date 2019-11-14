defmodule Shun.Rule.Target do
  @moduledoc """
  Encapsulates target classification logic used by `Shun.Rule` to interpret target patterns.

  All Rules are built with Targets, which are usually quoted patterns when the relevant generator
  functions are being used from macros, such as ones in `Shun.Builder`. These can represent URIs,
  IPv4 or IPv6 addresses, CIDR blocks, or single IP addresses.

  Unquoted 4-arity / 8-arity tuples, String literals, and URI structs are also valid. This is to
  aid creation of Preset modules, which implement `Shun.Preset` and must return valid lists of
  `t:Shun.Rule.t/0`.

  The following forms of Targets, for example, are valid:

  - `{192, 168, 1, 1}`, which represents an IPv4 Address at `192.168.1.1`.
  - `{10, _, _, _}`, which represents an IPv4 Address at `10.x.x.x`.
  - `{_, _, _, _}`, which represents any IPv4 Address.

  IPv6 addresses, represented as 8-arity tuples, are also valid:

  - `{0, 0, 0, 0, 0, 0, 0, 1}`, which represents an IPv6 loopback address.
  - `{0x8bad, 0xf00d, _, _, _, _, _, _}`, which represents another IPv6 address.
  - `{_, _, _, _, _, _, _, _}`, which represents any IPv6 address.

  Patterns that match `URI` structs can also be used as Targets:

  - `%URI{scheme: "https"}`
  - `%URI{scheme: "https", host: "example.com", path: "/admin"}`
  - `%URI{scheme: "https", host: "example.com", path: "/books/" <> _}`

  Lastly, Strings that represent IP Addresses or CIDR blocks can be used as Targets:

  - `192.168.1.1`
  - `192.168.100.14/24`
  - `2002::1234:abcd:ffff:c0a8:101/64`

  Strings that are URLs are not accepted; for these purposes you should build URI patterns. This
  is to ensure that whenever a string literal is used, it represents an IPv4 or IPv6 address, or
  IPv4 / IPv6 CIDR literal.

  Alternatively, for example when building a new Preset, you can pass an URI struct as a Target,
  which will be compiled down to a pattern that matches the non-nil keys of that URI struct.

  Specifically:

      iex(1)> lhs = Shun.Rule.reject(%URI{host: "169.254.169.254"}).pattern
      {:%, [], [{:__aliases__, [alias: false], [:URI]}, {:%{}, [], [host: "169.254.169.254"]}]}
      
      iex(2)> rhs = quote do: %URI{host: "169.254.169.254"}
      {:%, [], [{:__aliases__, [alias: false], [:URI]}, {:%{}, [], [host: "169.254.169.254"]}]}
      
      iex(3)> lhs == rhs
      true

  ### Guards

  When the Rule is given a Target in the form of an Elixir pattern, [guards][1] can be used.

  For Rules based on URIs, this is a great way to enforce hosts or schemes; for Rules based on
  IPv4 or IPv6 patterns, this is an alternative to specifying CIDR ranges.

  The following Target forms with guard clauses, for example, are valid:

  - `{a, _, _, _} when a == 10`
  - `{a, b, _, _} when a < b`
  - `{a, b, _, _} when (a * (b + c)) > 10`
  - `{a, _, _, _, _, _, _, _} when a >= 0xfe80 and a <= 0xfebf`
  - `%URI{host: "example.com", path: "/books/" <> _} when scheme != "ftp"`

  [1]: https://hexdocs.pm/elixir/guards.html
  """

  import Shun.Address

  @typedoc "Represents a Target which can be used with one of the functions that builds a Rule."
  @type t :: String.t() | URI.t() | Macro.t()

  @typedoc "Represents an AST fragment to be reintegrated as match pattern."
  @type pattern :: Macro.t()

  @typedoc "Represents an AST fragment to be reintegrated as guard."
  @type guard :: Macro.t()

  @type result ::
          {:pattern, type :: :ipv4 | :ipv6 | :uri}
          | {:pattern, type :: :ipv4 | :ipv6 | :uri, pattern}
          | {:pattern, type :: :ipv4 | :ipv6 | :uri, pattern, guard}
          | {:range, :ipv4, from :: Shun.Address.value_ipv4(), to :: Shun.Address.value_ipv4()}
          | {:range, :ipv6, from :: Shun.Address.value_ipv6(), to :: Shun.Address.value_ipv6()}

  def classify({:{}, _, [_, _, _, _]}) do
    {:pattern, :ipv4}
  end

  def classify({:{}, _, [_, _, _, _, _, _, _, _]}) do
    {:pattern, :ipv6}
  end

  def classify({:%, _, [{:__aliases__, _, [:URI]}, _]}) do
    {:pattern, :uri}
  end

  def classify({:when, _, [pattern, guard]}) do
    {:pattern, type} = classify(pattern)
    {:pattern, type, pattern, guard}
  end

  def classify(value) when is_v4(value) do
    {:pattern, :ipv4, Macro.escape(value)}
  end

  def classify(value) when is_v6(value) do
    {:pattern, :ipv6, Macro.escape(value)}
  end

  def classify(%URI{} = value) do
    bindings = value |> Map.from_struct() |> Enum.reject(&is_nil(elem(&1, 1)))
    pattern = {:%, [], [{:__aliases__, [], [:URI]}, {:%{}, [], bindings}]}
    {:pattern, :uri, pattern}
  end

  def classify(value) when is_binary(value) do
    case parse(value) do
      {:ok, {:address, type, address}} -> {:pattern, type, Macro.escape(address)}
      {:ok, {:range, type, from, to}} -> {:range, type, from, to}
      :error -> :error
    end
  end

  def classify(_) do
    :error
  end
end
