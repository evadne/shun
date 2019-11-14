defmodule Shun.Preset.IPv6.EmbeddedTest do
  use ExUnit.Case, async: true

  defmodule AcceptRejectVerifier do
    use Shun.Builder
    accept Shun.Preset.IPv6.Embedded
    reject {_, _, _, _}
  end

  defmodule RejectAcceptVerifier do
    use Shun.Builder
    reject Shun.Preset.IPv6.Embedded
    accept {_, _, _, _}
  end

  defmodule HandleAcceptVerifier do
    use Shun.Builder
    handle Shun.Preset.IPv6.Embedded
    accept {_, _, _, _}
  end

  defmodule HandleDefaultRejectVerifier do
    use Shun.Builder
    handle Shun.Preset.IPv6.Embedded
    reject {_, _, _, _}
  end

  defmodule HandleCustomAcceptVerifier do
    use Shun.Builder
    handle Shun.Preset.IPv6.Embedded, &handle_embedded/1
    accept {_, _, _, _}

    defp handle_embedded(_) do
      :reject
    end
  end

  test "handles 127.0.0.1" do
    address_v4 = {127, 0, 0, 1}
    address_v6 = :inet.ipv4_mapped_ipv6_address(address_v4)

    assert :accept = AcceptRejectVerifier.verify_ip(address_v6)
    assert {:ok, _} = Shun.verify(AcceptRejectVerifier, address_v6)
    assert {:error, :rejected} = Shun.verify(AcceptRejectVerifier, address_v4)

    assert :reject = RejectAcceptVerifier.verify_ip(address_v6)
    assert {:error, :rejected} = Shun.verify(RejectAcceptVerifier, address_v6)
    assert {:ok, _} = Shun.verify(RejectAcceptVerifier, address_v4)

    assert {:dynamic, handler} = HandleDefaultRejectVerifier.verify_ip(address_v6)
    assert {:verify_ip, ^address_v4} = handler.(address_v6)
    assert :reject = HandleDefaultRejectVerifier.verify_ip(address_v4)
    assert {:error, :rejected} = Shun.verify(HandleDefaultRejectVerifier, address_v6)
    assert {:error, :rejected} = Shun.verify(HandleDefaultRejectVerifier, address_v4)

    assert {:dynamic, handler} = HandleCustomAcceptVerifier.verify_ip(address_v6)
    assert :reject = handler.(address_v6)
    assert :accept = HandleCustomAcceptVerifier.verify_ip(address_v4)
    assert {:error, :rejected} = Shun.verify(HandleCustomAcceptVerifier, address_v6)
    assert {:ok, _} = Shun.verify(HandleCustomAcceptVerifier, address_v4)
  end
end
