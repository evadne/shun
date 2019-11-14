defmodule Shun.Builder.AddressTest do
  use ExUnit.Case

  defmodule AddressVerifier do
    use Shun.Builder

    preset Shun.Preset.AWS
    preset Shun.Preset.IPv6.Embedded

    accept %URI{host: "localhost"}
    reject "192.168.1.1"
    reject {169, x, _, _} when x == 254
    accept {_, _, _, _}

    reject {_, _, _, _, _, _, _, _}
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

    test "accepts 127.0.0.1" do
      {:ok, address} = :inet.parse_address('127.0.0.1')
      assert :accept = AddressVerifier.verify_ip(address)
    end

    test "accepts ::ffff:127.0.0.1 as boxed value, despite blanket IPv6 rejection" do
      {:ok, address} = :inet.parse_address('::ffff:127.0.0.1')
      assert {:dynamic, fun} = AddressVerifier.verify_ip(address)
      assert {:verify_ip, address} = fun.(address)
      assert :accept = AddressVerifier.verify_ip(address)
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
end
