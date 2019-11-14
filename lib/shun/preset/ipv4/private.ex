defmodule Shun.Preset.IPv4.Private do
  @moduledoc """
  Provides IPv4 related rules that reject private blocks.

  Rules within this Preset use the following ranges:

  - `10.0.0.0/8`
  - `172.16.0.0/12`
  - `192.168.0.0/16`
  """

  use Shun.Preset, targets: ~w(10.0.0.0/8 172.16.0.0/12 192.168.0.0/16)
end
