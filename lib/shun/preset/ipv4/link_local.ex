defmodule Shun.Preset.IPv4.LinkLocal do
  @moduledoc """
  Provides IPv4 related rules that reject link-local blocks.

  Rules within this Preset use the following ranges:

  - `169.254.0.0/16`
  """

  use Shun.Preset, targets: ~w(169.254.0.0/16)
end
