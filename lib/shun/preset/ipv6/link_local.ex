defmodule Shun.Preset.IPv6.LinkLocal do
  @moduledoc """
  Provides IPv6 related rules that reject link-local blocks.

  Rules within this Preset use the following ranges:

  - `fe80::/10`
  """

  use Shun.Preset, targets: ~w(fe80::/10)
end
