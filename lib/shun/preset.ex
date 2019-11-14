defmodule Shun.Preset do
  @moduledoc """
  Specifies how additional reusable rules are provided.

  Modules that implement this behaviour can be used with `Shun.Builder.preset/1`.
  """

  @doc """
  Returns a list of Rules (`t:Shun.Rule.t/0`) for use in Provider modules at compile-time.

  Rules can be built by using convenience functions in `Shun.Rule`.

  If you need to implement dynamic rules that query external resources, you should use
  `Shun.Builder.handle/2` and pass the function reference.
  """
  @callback rules() :: [Shun.Rule.t()]
end
