defmodule Shun.Verifier do
  @moduledoc """
  Allows verification of an URI, IPv4 address, or IPv6 address using a Provider.
  """

  @typedoc """
  Represents the Provider module, which implements the `Shun.Provider` behaviour.
  """
  @type provider :: module()

  @typedoc """
  Represents the value to be validated, which is either an URI struct, a String, or an IP address
  represented as a 4-arity or 8-arity tuple.
  """
  @type value :: Shun.name() | Shun.address() | Shun.uri()

  @typedoc """
  Allows customisation of how verification is handled.

  At this time the only change allowed is related to resolution of hostnames in URIs. The default
  resolver is `Shun.Resolver.InetRes` which wraps `:inet_res.lookup/4`, but any other module that
  implements the behaviour `Shun.Resolver` can be used.
  """
  @type option :: {:resolver, module()} | {:resolver_timeout, timeout()}

  @typedoc """
  Represents the result of URI / IPv4 / IPv6 verification.

  In most cases, a pattern-match against `{:ok, _}` is adequate. In case of URIs that have had
  their host names resolved for further verification, the underlying IPs will be returned in a
  list.
  """
  @type result :: {:ok, Shun.uri() | nonempty_list(Shun.address())} | {:error, term()}

  @spec perform(provider, value) :: result
  @spec perform(provider, value, [option]) :: result

  import Shun.Address, only: [is_v4: 1, is_v6: 1]

  @doc """
  Performs verification of the value using the Provider module provided.

  In case of Strings being used, it will first be parsed as an URI and validated as URI.
  """
  def perform(provider, value, options \\ [])

  def perform(provider, address, options) when is_v4(address) do
    verify_ip(provider, address, options)
  end

  def perform(provider, address, options) when is_v6(address) do
    verify_ip(provider, address, options)
  end

  def perform(provider, name, options) when is_binary(name) do
    verify_uri(provider, URI.parse(name), options)
  end

  def perform(provider, %URI{} = uri, options) do
    verify_uri(provider, uri, options)
  end

  defp verify_uri(provider, uri, options) do
    provider.verify_uri(uri)
    |> verify_result(provider, uri, options)
  end

  defp verify_ip(provider, address, options) do
    provider.verify_ip(address)
    |> verify_result(provider, address, options)
  end

  defp verify_result(:accept, _, value, _) do
    {:ok, value}
  end

  defp verify_result(:reject, _, _, _) do
    {:error, :rejected}
  end

  defp verify_result({:dynamic, fun}, provider, value, options) do
    verify_result(fun.(value), provider, value, options)
  end

  defp verify_result({:verify_ip, address}, provider, _, options) when is_tuple(address) do
    verify_ip(provider, address, options)
  end

  defp verify_result(:resolve, provider, %URI{host: host}, options) do
    case :inet.parse_address(to_charlist(host)) do
      {:ok, address} -> verify_ip(provider, address, options)
      {:error, :einval} -> verify_resolved_ips(provider, host, options)
    end
  end

  defp verify_resolved_ips(provider, host, options) do
    resolver = get_option(options, :resolver)
    resolver_timeout = get_option(options, :resolver_timeout)

    case resolver.resolve(host, resolver_timeout) do
      {:ok, addresses} -> verify_ips(provider, addresses, options)
      :error -> {:error, :nxdomain}
    end
  end

  defp verify_ips(provider, addresses, options) do
    case Enum.uniq(Enum.map(addresses, &verify_ip(provider, &1, options))) do
      [:accept] -> {:ok, addresses}
      _ -> {:error, :rejected}
    end
  end

  defp get_option(options, key), do: Keyword.get_lazy(options, key, fn -> get_default(key) end)
  defp get_default(:resolver), do: Shun.Resolver.InetRes
  defp get_default(:resolver_timeout), do: 1000
end
