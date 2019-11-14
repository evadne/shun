defmodule Shun do
  @moduledoc """
  Top-level module holding the Shun library, which provides URI, IPv4 and IPv6 address
  verification primitives.

  ## Setup

  The usual way to use Shun is by installing it in a custom module.

      defmodule MyApp.Shun do
        use Shun.Builder
        handle Shun.Preset.IPv6.Embedded
        reject Shun.Preset.AWS.InstanceMetadata
      end

  Additional Rules can be added using a simple DSL (provided by `Shun.Rule` and `Shun.Builder`):

      defmodule MyApp.Shun do
        use Shun.Builder
        handle Shun.Preset.IPv6.Embedded
        reject Shun.Preset.AWS.InstanceMetadata
        reject "10.0.0.0/8"
        reject %URI{scheme: scheme} when scheme != "https"
      end

  See:

  - `Shun.Builder` for more information on usage;
  - `Shun.Rule` for information on the types of Rules you may use; and
  - `Shun.Rule.Target` on how you can express targets.

  ## Usage

  Once a module has been set up, you can use it with `Shun.verify/2` or `Shun.verify/3`.

  For example:

      Shun.verify(MyApp.Shun, "http://google.com")
  """

  @typedoc "Represents the Target prior to verification."
  @type name :: String.t()

  @typedoc "Represents an URI which points to the Target."
  @type uri :: URI.t()

  @typedoc "Represents an IP Address which can be IPv4 or IPv6."
  @type address :: :inet.ip_address()

  @doc """
  Performs verification on the value using the provider specifies.

  Implemented by `Shun.Verifier.perform/2`.
  """
  defdelegate verify(provider, value, options \\ []), to: Shun.Verifier, as: :perform
end
