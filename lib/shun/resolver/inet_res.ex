defmodule Shun.Resolver.InetRes do
  @moduledoc """
  Implements `Shun.Resolver` using `:inet_res.lookup/4`.
  """

  def resolve(name, timeout \\ 1000) do
    name = to_charlist(name)
    addresses_ipv4 = resolve_ipv4(name, timeout)
    addresses_ipv6 = resolve_ipv6(name, timeout)
    resolve_wrap(addresses_ipv4, addresses_ipv6)
  end

  defp resolve_ipv4(name, timeout) do
    for {_, _, _, _} = address <- resolve_lookup(name, :a, timeout) do
      address
    end
  end

  defp resolve_ipv6(name, timeout) do
    for {_, _, _, _, _, _, _, _} = address <- resolve_lookup(name, :aaaa, timeout) do
      address
    end
  end

  defp resolve_lookup(name, type, timeout) do
    :inet_res.lookup(name, :in, type, timeout: timeout)
  end

  defp resolve_wrap([], []), do: :error
  defp resolve_wrap(v4, v6), do: {:ok, v4 ++ v6}
end
