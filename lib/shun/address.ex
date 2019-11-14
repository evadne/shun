defmodule Shun.Address do
  @moduledoc """
  Provides convenience functions to deal with IPv4 and IPv6 addresses.
  """

  @type value_ipv4 :: 0..unquote(round(:math.pow(2, 32)) - 1)
  @type value_ipv6 :: 0..unquote(round(:math.pow(2, 128)) - 1)

  @type result_ipv4 :: result_ipv4_address | result_ipv4_range
  @type result_ipv4_address :: {:address, :ipv4, :inet.ip4_address()}
  @type result_ipv4_range :: {:range, :ipv4, value_ipv4, value_ipv4}

  @type result_ipv6 :: result_ipv6_address | result_ipv6_range
  @type result_ipv6_address :: {:address, :ipv6, :inet.ip6_address()}
  @type result_ipv6_range :: {:range, :ipv6, value_ipv6, value_ipv6}

  @spec parse(String.t()) :: {:ok, result_ipv4 | result_ipv6} | :error

  use Bitwise
  defguard is_v4(value) when is_tuple(value) and tuple_size(value) == 4
  defguard is_v6(value) when is_tuple(value) and tuple_size(value) == 8

  def parse(value) do
    case String.split(value, "/") do
      [address_string] -> parse_address(address_string)
      [address_string, mask_string] -> parse_address_range(address_string, mask_string)
      _ -> :error
    end
  end

  defp parse_address(address_string) do
    case :inet.parse_address(to_charlist(address_string)) do
      {:ok, address} when is_v4(address) -> {:ok, {:address, :ipv4, address}}
      {:ok, address} when is_v6(address) -> {:ok, {:address, :ipv6, address}}
      {:error, _} -> :error
    end
  end

  defp parse_mask(mask_string) do
    case Integer.parse(mask_string, 10) do
      {mask, ""} -> {:ok, mask}
      _ -> :error
    end
  end

  defp parse_address_range(address_string, mask_string) do
    with {:ok, {_, _, address}} <- parse_address(address_string),
         {:ok, mask} = parse_mask(mask_string),
         {:ok, range} <- build_address_range(address, mask) do
      {:ok, range}
    else
      _ -> :error
    end
  end

  defp build_address_range(address, mask) when is_v4(address) and mask in 0..32 do
    {value_start, value_end} = build_range(to_value(address), 32 - mask)
    {:ok, {:range, :ipv4, value_start, value_end}}
  end

  defp build_address_range(address, mask) when is_v6(address) and mask in 0..128 do
    {value_start, value_end} = build_range(to_value(address), 128 - mask)
    {:ok, {:range, :ipv6, value_start, value_end}}
  end

  defp build_address_range(_, _) do
    :error
  end

  defp build_range(value, stride) do
    value_start = value >>> stride <<< stride
    value_end = value_start ||| (1 <<< stride) - 1
    {value_start, value_end}
  end

  def to_value(address) when is_v4(address) do
    <<value::size(32)-big>> = to_binary(address)
    value
  end

  def to_value(address) when is_v6(address) do
    <<value::size(128)-big>> = to_binary(address)
    value
  end

  defp to_binary({a, b, c, d}) do
    <<
      a::size(8)-big,
      b::size(8)-big,
      c::size(8)-big,
      d::size(8)-big
    >>
  end

  defp to_binary({a, b, c, d, e, f, g, h}) do
    <<
      a::size(16)-big,
      b::size(16)-big,
      c::size(16)-big,
      d::size(16)-big,
      e::size(16)-big,
      f::size(16)-big,
      g::size(16)-big,
      h::size(16)-big
    >>
  end
end
