defmodule Shun.Provider do
  @moduledoc """
  Specifies how the incoming URI or IP Address should be validated.

  This Behaviour is automatically implemented by modules using `Shun.Builder` (directly, or via
  `use Shun.Builder`).
  """

  @type dynamic_uri :: {:dynamic, dynamic_uri_fun}
  @type dynamic_uri_fun :: (Shun.uri() -> result_uri)

  @type dynamic_address :: {:dynamic, dynamic_address_fun}
  @type dynamic_address_fun :: (Shun.address() -> result_address)

  @type result_uri :: :accept | :reject | :resolve | dynamic_uri | {:verify_ip, Shun.address()}
  @type result_address :: :accept | :reject | dynamic_address | {:verify_ip, Shun.address()}

  @doc """
  Provides decision on the parsed URI.

  For each incoming URI, the following values are accepted:

  1.  `:accept`: the URI is is accepted for use. No further verification is required. Verification
      will halt with typed result `{:ok, Shun.uri()}`.

  2.  `:reject`: the URI is not accepted. No further verification is required. Verification will
      halt with typed result `{:error, :rejected}`.

  3.  `:resolve`: the URI may be accepted if its underlying A and AAAA records pass validation.

  4.  `{:dynamic, dynamic_fun}`: the URI is to be handed to the function which will return a
      further result. It is used mostly for scenarios where the whitelist / blacklist is
      maintained and updated dynamically.

  5.  `{:verify_ip, address}`: the value resolves to an IP Address which needs to be verified
      again.
  """
  @callback verify_uri(uri :: Shun.uri()) :: result_uri

  @doc """
  Provides decision on the IPv4 or IPv6 address.

  For each incoming IP Address, or for URIs that have previously been marked as `:resolve` and
  since have been resolved to IP addresses, the following values are accepted:

  1.  `:accept`: the IP Address is is accepted for use. No further verification is required.
      Verification will halt with typed result `{:ok, nonempty_list(Shun.address())}`.

  2.  `:reject`: the IP Address is not accepted. No further verification is required.
      Verification will halt with typed result `{:error, :rejected}`.

  3.  `{:dynamic, dynamic_fun}`: the IP Address is to be handed to the function which will return
      a further result. It is used mostly for scenarios where the whitelist / blacklist is
      maintained and updated dynamically.

  4.  `{:verify_ip, address}`: the value resolves to an IP Address which needs to be verified
      again. This can happen when the IP Address has been identified as an IPv6 address wrapping
      an IPv4 address (as per `Shun.Preset.IPv6.Embedded`), so the underlying IPv4 address must
      be verified next.
  """
  @callback verify_ip(address :: Shun.address()) :: result_address
end
