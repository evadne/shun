defmodule Shun.Rule.Pattern do
  @moduledoc false
  @type t :: %__MODULE__{}

  defstruct type: nil, pattern: nil, guard: true, action: nil

  def build(type, pattern, guard, action) do
    %__MODULE__{type: type, pattern: pattern, guard: guard, action: action}
  end
end
