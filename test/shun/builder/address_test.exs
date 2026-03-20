defmodule Shun.Builder.AddressTest do
  use ExUnit.Case, async: true

  defmodule FakeResolver do
    @behaviour Shun.Resolver

    @impl Shun.Resolver
    def resolve("safe.test", _timeout), do: {:ok, [{93, 184, 216, 34}]}

    def resolve("private.test", _timeout), do: {:ok, [{192, 168, 1, 1}]}

    def resolve(_host, _timeout), do: :error
  end

  defmodule AddressVerifier do
    use Shun.Builder
    reject Shun.Preset.AWS.InstanceMetadata
    reject Shun.Preset.IPv4.Private
    reject Shun.Preset.IPv4.LinkLocal
    reject Shun.Preset.IPv4.Loopback
    handle Shun.Preset.IPv6.Embedded
    reject Shun.Preset.IPv6.LinkLocal
    reject Shun.Preset.IPv6.Loopback
    accept %URI{host: "localhost"}
    accept {_, _, _, _}
    accept {_, _, _, _, _, _, _, _}
  end

  describe "verify_uri/1" do
    test "rejects 169.254.169.254" do
      assert :reject = AddressVerifier.verify_uri(URI.parse("https://169.254.169.254"))
    end

    test "marks 169.168.1.1 as needing resolution" do
      assert :resolve = AddressVerifier.verify_uri(URI.parse("https://169.168.1.1"))
    end
  end

  describe "verify_ip/1" do
    test "rejects 169.254.169.254" do
      assert :reject = AddressVerifier.verify_ip({169, 254, 169, 254})
    end

    test "rejects 192.168.1.1" do
      assert :reject = AddressVerifier.verify_ip({192, 168, 1, 1})
    end

    test "rejects 127.0.0.1" do
      {:ok, address} = :inet.parse_address(~c"127.0.0.1")
      assert :reject = AddressVerifier.verify_ip(address)
    end

    test "rejects ::ffff:127.0.0.1 as boxed value, despite blanket IPv6 acceptance" do
      {:ok, address} = :inet.parse_address(~c"::ffff:127.0.0.1")
      assert {:dynamic, fun} = AddressVerifier.verify_ip(address)
      assert {:verify_ip, address} = fun.(address)
      assert :reject = AddressVerifier.verify_ip(address)
    end
  end

  describe "Shun.verify/2" do
    test "rejects 169.254.169.254" do
      assert {:error, :rejected} = Shun.verify(AddressVerifier, "https://169.254.169.254")
    end

    test "rejects 192.168.1.1" do
      assert {:error, :rejected} = Shun.verify(AddressVerifier, "https://192.168.1.1")
    end
  end

  describe "Shun.verify/3 with a custom resolver" do
    test "accepts hostnames that resolve to public addresses" do
      assert {:ok, [{93, 184, 216, 34}]} =
               Shun.verify(AddressVerifier, "https://safe.test", resolver: FakeResolver)
    end

    test "rejects hostnames that resolve to private addresses" do
      assert {:error, :rejected} =
               Shun.verify(AddressVerifier, "https://private.test", resolver: FakeResolver)
    end
  end
end
