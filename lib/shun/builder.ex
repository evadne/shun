defmodule Shun.Builder do
  @moduledoc """
  Provides a way to programmatically create modules that implement the `Shun.Provider` behaviour.

  The Builder is supposed to be used in your own module, by calling `use Shun.Builder`. This in
  turn calls the `__using__` macro and prepares the module for use with the DSL as defined by
  `Shun.Rule`.

  The `accept/1`, `reject/1` and `handle/2` macros generate the relevant `Shun.Rule` structs, and
  enqueues them for compilation. On the other hand, Rules already defined in a Preset (any module
  which implements the `Shun.Preset` behaviour) can be incorporated with `preset/1`.

  Rules are built and accumulated in the `:rules` module attribute.

  ## Compilation

  Based on the Rules given prior to compilation, the Builder emits implementations for
  `handle_url/1`, `handle_ipv4/2` and `handle_ipv6/2`, the latter two called by an emitted
  implementation of `handle_ip/1`.

  Functions are generated in the following order:

  - `handle_ip/1` for IPv4, routing to `handle_ipv4/2`.
  - `handle_ip/1` for IPv6, routing to `handle_ipv6/2`.
  - For each Rule, an implementation of `handle_url/1`, `handle_ipv4/2`, or `handle_ipv6/2`.
  - (Optional) Fallback implementation of `handle_url/1`.
  - (Optional) Fallback implementation of `handle_ipv4/1`.
  - (Optional) Fallback implementation of `handle_ipv6/1`.

  The Builder also emits fallback clauses for all three types with the following defaults, in case
  you have not specified the corresponding patterns:

  - URIs are resolved, and their IP addresses are verified (via `:resolve`).
  - IP addresses that are not IPv4 or IPv6 are rejected (via `:reject`).
  - IPv4 addresses are rejected (via `:reject`).
  - IPv6 addresses are rejected (via `:reject`).

  You can override this behavior by ensuring that the patterns completely cover each Target type.
  For example, to implement a Provider that rejects all unknown URIs instead of resolving them
  (and rejecting their IP addresses by default), implement a fallback clause for URIs:

      defmodule MyApp.Shun do
        use Shun.Builder
        accept %URI{host: host} when host == "example.com"
        reject %URI{}
      end

  You can also use the fallback clause with a function reference (see `handle/2`) to implement
  custom fallback logic:

      defmodule MyApp.Shun do
        use Shun.Builder
        accept %URI{host: host} when host == "example.com"
        handle %URI{}, &handle_uri/1
        
        def handle_uri(uri) do
          cond do
            uri.host == "test.example.com" -> :accept
            true -> :reject
          end
        end
      end

  For example, to implement a Provider that accepts all unknown IP addresses, implement fallback
  clauses for both IPv4 and IPv6 addresses:

      defmodule MyApp.Shun do
        use Shun.Builder
        …
        accept {_, _, _, _}
        accept {_, _, _, _, _, _, _, _}
      end
  """
  alias Shun.Rule

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
      @before_compile unquote(__MODULE__)
      @behaviour Shun.Provider
      @reversed_rules []
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    env.module
    |> Module.get_attribute(:reversed_rules)
    |> Enum.reverse()
    |> build()
  end

  @spec accept(module() | Rule.Target.t()) :: Macro.t()
  @spec reject(module() | Rule.Target.t()) :: Macro.t()
  @spec handle(module()) :: Macro.t()
  @spec handle(module() | Rule.Target.t(), Rule.handle_fun()) :: Macro.t()

  @doc """
  Adds an Accept rule generated with `Shun.Rule.accept/1`, or Accept rules generated by the
  preset module provided.
  """
  defmacro accept(target) do
    target |> Macro.expand_once(__CALLER__) |> put_target_rules(:accept)
  end

  @doc """
  Adds an Reject rule generated with `Shun.Rule.accept/1`, or Reject rules generated by the
  preset module provided.
  """
  defmacro reject(target) do
    target |> Macro.expand_once(__CALLER__) |> put_target_rules(:reject)
  end

  @doc """
  Adds Dynamic rules generated by the preset module provided, with its default handler function
  used to handle the matched entries.
  """
  defmacro handle(target) do
    target |> Macro.expand_once(__CALLER__) |> put_target_rules(:handle)
  end

  @doc """
  Adds a Dynamic rule generated with `Shun.Rule.handle/2`, or Dynamic rules generated by the
  preset module provided.
  """
  defmacro handle(target, handler) do
    target |> Macro.expand_once(__CALLER__) |> put_target_rules(:handle, [handler])
  end

  defp put_target_rules(target, action, arguments \\ []) do
    with true <- is_atom(target) && Code.ensure_loaded?(target) do
      for rule <- apply(target, :rules, [action] ++ arguments) do
        put_quoted_rule(rule)
      end
    else
      _ -> put_quoted_rule(apply(Rule, action, [target] ++ arguments))
    end
  end

  defp put_quoted_rule(rule) do
    quote bind_quoted: [rule: Macro.escape(rule)] do
      @reversed_rules [rule | @reversed_rules]
    end
  end

  defp build(rules, fallbacks \\ [uri: :resolve, ipv4: :reject, ipv6: :reject]) do
    [build_header(rules), build_rules(rules), build_fallbacks(rules, fallbacks)]
  end

  defp build_header(_rules) do
    import Shun.Address, only: [is_v4: 1, is_v6: 1, to_value: 1]

    quote do
      @impl Shun.Provider
      def verify_ip(address) when is_v4(address), do: verify_ipv4(address, to_value(address))

      @impl Shun.Provider
      def verify_ip(address) when is_v6(address), do: verify_ipv6(address, to_value(address))

      @impl Shun.Provider
      def verify_ip(_), do: :reject
    end
  end

  defp build_rules(rules) do
    for rule <- rules do
      build_rule(rule)
    end
  end

  defp build_fallbacks(rules, fallback) do
    for {type, action} <- fallback, not Rule.has_pattern_fallback?(rules, type) do
      build_fallback(type, action)
    end
  end

  defp build_fallback(:uri, action) do
    quote do
      @impl Shun.Provider
      def unquote(build_name(:uri))(_) do
        unquote(action)
      end
    end
  end

  defp build_fallback(type, action) when type in ~w(ipv4 ipv6)a do
    quote do
      def unquote(build_name(type))(_, _) do
        unquote(action)
      end
    end
  end

  defp build_rule(%Rule.Pattern{type: :uri} = rule) do
    quote do
      @impl Shun.Provider
      def unquote(build_name(rule.type))(unquote(rule.pattern)) when unquote(rule.guard) do
        unquote(rule.action)
      end
    end
  end

  defp build_rule(%Rule.Pattern{type: type} = rule) when type in ~w(ipv4 ipv6)a do
    quote do
      def unquote(build_name(rule.type))(unquote(rule.pattern), _) when unquote(rule.guard) do
        unquote(rule.action)
      end
    end
  end

  defp build_rule(%Rule.Range{type: type} = rule) when type in ~w(ipv4 ipv6)a do
    quote do
      def unquote(build_name(type))(_, x) when x in unquote(Macro.escape(rule.from..rule.to)) do
        unquote(rule.action)
      end
    end
  end

  defp build_name(:uri), do: :verify_uri
  defp build_name(:ipv4), do: :verify_ipv4
  defp build_name(:ipv6), do: :verify_ipv6
end
