# Shun

The Shun library provides URI, IPv4 and IPv6 address verification primitives for Elixir applications. It is useful for Web applications that act on behalf of the customer, e.g. resource pipelines which operate on exogenous URIs.

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

    defp deps do
      [
        {:shun, "~> 0.1.1"}
      ]
    end

## Usage

The usual way to use Shun.Builder is by installing it in a custom module.

    defmodule MyApp.Shun do
      use Shun.Builder
      preset Shun.Preset.IPv6.Embedded
      preset Shun.Preset.AWS
    end

Additional Rules can be added using a simple DSL (provided by `Shun.Rule`):

    defmodule MyApp.Shun do
      use Shun.Builder
      preset Shun.Preset.IPv6.Embedded
      preset Shun.Preset.AWS
      reject "10.0.0.0/8"
      reject %URI{schema: schema} when schema != "https"
    end

Afterwards, you can call `verify/1`, for example:

    MyApp.Shun.verify("http://google.com")

## Notes

1.  Any Provider module that implements the `Shun.Provider` behaviour can be used.

2.  The DSL as implemented by `Shun.Rule` emits Rules on a per-entry basis. However, it is most likely that you will use `Shun.Builder` so Rules are compiled to function heads ahead of time. `Shun.Builder` does not reorder Rules, so they are evaluated in the original order.

## Acknowledgements

During design and prototype development of this library, the Author has drawn inspiration from the following implementations, and therefore thanks all contributors for their generosity:

- [c-rack/cidr-elixir](https://github.com/c-rack/cidr-elixir)
- [cobenian/inet_cidr](https://github.com/Cobenian/inet_cidr)
