defmodule Shun.Builder.RangeTest do
  use ExUnit.Case, async: true

  defmodule RangeVerifier do
    use Shun.Builder
    reject Shun.Preset.AWS.InstanceMetadata
    handle Shun.Preset.IPv6.Embedded
    reject "169.254.0.0/16"
    reject "169.254.169.254/32"
    reject "::/128"
    reject "fe80::/64"
    accept {_, _, _, _}
  end

  describe "verify_ip/1" do
    test "rejects 169.254.169.254" do
      assert :reject = RangeVerifier.verify_ip({169, 254, 169, 254})
    end

    test "accepts 192.168.1.1" do
      assert :accept = RangeVerifier.verify_ip({192, 168, 1, 1})
    end

    test "identifies ::ffff:127.0.0.1 as boxed value" do
      {:ok, address} = :inet.parse_address('::ffff:127.0.0.1')
      assert {:dynamic, fun} = RangeVerifier.verify_ip(address)
      assert {:verify_ip, address} = fun.(address)
      assert :accept = RangeVerifier.verify_ip(address)
    end
  end
end
