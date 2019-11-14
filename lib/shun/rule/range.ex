defmodule Shun.Rule.Range do
  @moduledoc false
  @type t :: %__MODULE__{}

  defstruct type: nil, from: nil, to: nil, action: nil

  def build(type, from, to, action) do
    %__MODULE__{type: type, from: from, to: to, action: action}
  end
end
