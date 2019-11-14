defmodule Shun.Rule.MalformedError do
  @moduledoc """
  Represents a compile-time error when the pattern used to build a Rule is not valid.
  """

  defexception message: nil

  @impl true
  def exception(value) do
    %__MODULE__{message: "invalid pattern: #{inspect(value)}"}
  end
end
