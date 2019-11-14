defmodule Shun.AddressTest do
  use ExUnit.Case, async: true

  addresses_v4 = [
    "192.168.1.1"
  ]

  addresses_v6 = [
    "::1"
  ]

  ranges_v4 = [
    "127.0.0.0/8"
  ]

  ranges_v6 = [
    "fe80::/10"
  ]

  for address <- addresses_v4 do
    test "parses #{address}" do
      assert {:ok, {:address, :ipv4, _}} = Shun.Address.parse(unquote(address))
    end
  end

  for address <- addresses_v6 do
    test "parses #{address}" do
      assert {:ok, {:address, :ipv6, _}} = Shun.Address.parse(unquote(address))
    end
  end

  for range <- ranges_v4 do
    test "parses #{range}" do
      assert {:ok, {:range, :ipv4, _, _}} = Shun.Address.parse(unquote(range))
    end
  end

  for range <- ranges_v6 do
    test "parses #{range}" do
      assert {:ok, {:range, :ipv6, _, _}} = Shun.Address.parse(unquote(range))
    end
  end
end
