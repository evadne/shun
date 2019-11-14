defmodule Shun.Resolver do
  @moduledoc """
  Specifies how names are resolved to addresses.

  The resolved address is used by `Shun.Verifier` when the callback module has specified that the
  URI encountered should be resolved.
  """

  @doc "Resolves the given host name to one or more addresses."
  @callback resolve(Shun.name(), timeout()) :: {:ok, nonempty_list(Shun.address())} | :error
end
