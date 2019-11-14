defmodule Shun.Preset.AWS.InstanceMetadataTest do
  use ExUnit.Case, async: true

  # https://www.shellntel.com/blog/2019/8/27/aws-metadata-endpoint-how-to-not-get-pwned-like-capital-one

  @names [
    "http://[::ffff:169.254.169.254]",
    "http://[0:0:0:0:0:ffff:169.254.169.254]",
    "http://425.510.425.510",
    "http://2852039166",
    "http://7147006462",
    "http://0xA9.0xFE.0xA9.0xFE",
    "http://0xA9FEA9FE",
    "http://0x41414141A9FEA9FE",
    "http://0251.0376.0251.0376",
    "http://0251.00376.000251.0000376",
    "http://169.254.169.254.xip.io",
    "http://A.8.8.8.8.1time.169.254.169.254.1time.repeat.rebind.network"
  ]

  defmodule AddressVerifier do
    use Shun.Builder
    reject Shun.Preset.AWS.InstanceMetadata
    handle Shun.Preset.IPv6.Embedded
    accept {_, _, _, _}
    accept {_, _, _, _, _, _, _, _}
  end

  for name <- @names do
    test "resolves #{name}" do
      assert :resolve = AddressVerifier.verify_uri(URI.parse(unquote(name)))
    end

    test "rejects resolved #{name} when used via Shun" do
      assert {:error, _} = Shun.verify(AddressVerifier, unquote(name))
    end
  end
end
