# Shun

The Shun library provides URI, IPv4 and IPv6 address verification primitives for Elixir applications. It is useful for Web applications that act on behalf of the customer, e.g. resource pipelines which operate on user-provided URIs.

## Capabilities

The Shun library provides a way to easily add domain / address verification to your application. It operates based on a set of Rules that are compiled into your custom module, but you are also able to inject function references where needed, to affect the decisions dynamically.

Within the DSL, each Rule must have a Target. Additionaly, guards and handlers are optionally available.

-  There are three types of Rules: Accept, Reject and Handle. The first two kinds are self-explanatory; the third kind allows you to specify a function reference, so your application can dynamically decide what to do with a Target.

-  There are also three types of Targets: `URI` structs, `:inet` tuples (4-arity for IPv4 or 8-arity for IPv8), or [CIDR Notations][1].

-  For Rules using `URI` structs or tuples, pattern-matching via use of guards is available.

-  For all kinds of Targets, the Handle Rule type allows associating a remote function reference, which allows your Application to dynamically decide what to do with a particular URI or IP Address.

[1]: https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing

## Installation

To install Shun, add the following line in your application’s dependencies:

```elixir
defp deps do
  [
    {:shun, "~> 1.0.2"}
  ]
end
```

## Usage

The usual way to use `Shun.Builder` is by installing it in a custom module.

```elixir
defmodule MyApp.Shun do
  use Shun.Builder
  handle Shun.Preset.IPv6.Embedded
  reject Shun.Preset.AWS.InstanceMetadata
end
```

Additional Rules can be added using a simple DSL (provided by `Shun.Rule`):

```elixir
defmodule MyApp.Shun do
  use Shun.Builder
  handle Shun.Preset.IPv6.Embedded
  reject Shun.Preset.AWS.InstanceMetadata
  reject "10.0.0.0/8"
  reject %URI{scheme: scheme} when scheme != "https"
end
```

Afterwards, you can call `Shun.verify/2`, for example:

```elixir
    Shun.verify(MyApp.Shun, "http://google.com")
```

## Presets

The following presets are bundled with Shun:

- `Shun.Preset.IPv4.LinkLocal`
- `Shun.Preset.IPv4.Loopback`
- `Shun.Preset.IPv4.Private`
- `Shun.Preset.IPv6.Embedded`
- `Shun.Preset.IPv6.LinkLocal`
- `Shun.Preset.IPv6.Loopback`
- `Shun.Preset.AWS.InstanceMetadata`

These Presets provide reject rules that can be plugged into your own Shun provider.

You can use presets with the `accept`, `reject` or `handle` macros, for example:

```elixir
reject Shun.Preset.IPv4.LinkLocal # rejects link-local ipv4 addresses
reject Shun.Preset.AWS.InstanceMetadata # rejects 169.254.169.254
handle Shun.Preset.IPv6.Embedded # handles underlying IPv4
reject Shun.Preset.IPv6.Embedded # rejects all embedded IPv4
```

## Scenarios

To accept URLs as long as they do not resolve to undesired IPs:

```elixir
defmodule MyApp.Shun do
  use Shun.Builder
  # reject <preset>
  accept {_, _, _, _}
  accept {_, _, _, _, _, _, _, _}
  # Note that a default action for URIs is not provided - this forces all
  # URIs to be resolved, so IP rules in presets are exercised
end
```

To only accept a few specific URIs:

```elixir
defmodule MyApp.Shun do
  use Shun.Builder
  accept %URI{host: "example.com"}
  accept %URI{host: "special.example.com"}
  reject %URI{} 
  reject {_, _, _, _}
  reject {_, _, _, _, _, _, _, _}
end
```

To use a function to decide what to do with the URI:

```elixir
defmodule MyApp.Shun do
  use Shun.Builder
  reject %URI{scheme: scheme} when scheme != "https"
  handle %URI{}, &handle_uri/1

  defp handle_uri(uri) do
    cond do
      uri.host == "dynamic.example.com" -> :reject
      true -> :accept
    end
  end
end
```

To only allow URIs from a specific AWS S3 bucket (in virtual hosted-style):

```elixir
defmodule MyApp.Shun do
  use Shun.Builder
  reject %URI{scheme: scheme} when scheme != "https"
  handle %URI{}, &handle_uri/1

  defp handle_uri(%{host: host}) do
    bucket_name = System.get_env("AWS_BUCKET_NAME")
    region_name = System.get_env("AWS_REGION")

    names = [
      "#{bucket_name}.s3-accelerate.dualstack.amazonaws.com",
      "#{bucket_name}.s3-accelerate.amazonaws.com",
      "#{bucket_name}.s3.dualstack.#{region_name}.amazonaws.com",
      "#{bucket-name}.s3.#{region_name}.amazonaws.com",
      "#{bucket-name}.s3.amazonaws.com"
    ]

    cond do
      Enum.member?(names, host) -> :accept
      true -> :reject
    end
  end
end
```

## Notes

1.  Please see documentation in `Shun.Builder` regarding the order of rules and default actions. The default actions are as follows:

    - IPs are rejected
    - URIs that have IPs as host are processed as if they were IPs
    - Other URIs are resolved and are only accepted if all underlying IPs are accepted

    If a catch-all rule is specifically provided, then the default action for that target type will not be generated.

2.  Any Provider module that implements the `Shun.Provider` behaviour can be used.

3.  The DSL as implemented by `Shun.Rule` emits Rules on a per-entry basis. However, it is most likely that you will use `Shun.Builder` so Rules are compiled to function heads ahead of time. `Shun.Builder` does not reorder Rules, so they are evaluated in the original order.

4.  If your application follows redirections, it would be wise to re-validate the URI or IP address on each redirection with Shun.

## Acknowledgements

During design and prototype development of this library, the Author has drawn inspiration from the following implementations, and therefore thanks all contributors for their generosity:

- [c-rack/cidr-elixir](https://github.com/c-rack/cidr-elixir)
- [cobenian/inet_cidr](https://github.com/Cobenian/inet_cidr)

The author wishes to additionally thank the following individuals for their input during the implemention process:

- [Alvise Susmel](https://github.com/alvises)
- [Derek Kraan](https://github.com/derekkraan)
- [Bryan Hunt](https://github.com/mergefailure)
g