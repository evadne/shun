defmodule Shun.Preset.IPv6.Loopback do
  @moduledoc """
  Provides IPv6 related rules that reject loopback blocks.

  Rules within this Preset use the following ranges:

  - `::1`
  """

  use Shun.Preset, targets: ~w(::1)
end
