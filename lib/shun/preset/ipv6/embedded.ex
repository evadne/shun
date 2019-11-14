defmodule Shun.Preset.IPv6.Embedded do
  @moduledoc """
  Provides IPv6 related rules which verify the embedded IPv4 addresses correctly. Instead of
  verifying the IPv6 addresses as-is, the embedded IPv4 address will be extracted and verified as
  if it has been used from the beginning.

  Rules within this Preset are based on:

  - [RFC4291](https://tools.ietf.org/html/rfc4291): `::ffff:0:0/96`.
  - [RFC6052](https://tools.ietf.org/html/rfc6052): `64:ff9b::/96`.
  """

  @behaviour Shun.Preset
  @ranges ~w(::ffff:0:0/96 64:ff9b::/96)

  @impl Shun.Preset
  def rules do
    for range <- @ranges do
      Shun.Rule.handle(range, &__MODULE__.handle_boxed/1)
    end
  end

  @doc """
  Convenience function to obtain mapped IPv4 address from an IPv6 address.
  """
  def handle_boxed({_, _, _, _, _, _, _, _} = address) do
    {:verify_ip, :inet.ipv4_mapped_ipv6_address(address)}
  end
end
