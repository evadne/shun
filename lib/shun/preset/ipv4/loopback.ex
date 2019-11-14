defmodule Shun.Preset.IPv4.Loopback do
  @moduledoc """
  Provides IPv4 related rules that reject loopback blocks.

  Rules within this Preset use the following ranges:

  - `127.0.0.0/8`
  """

  use Shun.Preset, targets: ~w(127.0.0.0/8)
end
