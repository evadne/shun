defmodule Shun.Preset.IPv4.PrivateTest do
  use ExUnit.Case, async: true

  defmodule AcceptVerifier do
    use Shun.Builder
    accept Shun.Preset.IPv4.Private
    reject {_, _, _, _}
  end

  defmodule RejectVerifier do
    use Shun.Builder
    reject Shun.Preset.IPv4.Private
    accept {_, _, _, _}
  end

  defmodule AliasRejectVerifier do
    alias Shun.Preset.IPv4
    use Shun.Builder
    reject IPv4.Private
    accept {_, _, _, _}
  end

  test "handles 192.168.1.1" do
    assert :accept = AcceptVerifier.verify_ip({192, 168, 1, 1})
    assert :reject = RejectVerifier.verify_ip({192, 168, 1, 1})
    assert :reject = AliasRejectVerifier.verify_ip({192, 168, 1, 1})
  end
end
