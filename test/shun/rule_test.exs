defmodule Shun.RuleTest do
  use ExUnit.Case, async: true
  alias Shun.Rule

  defmacrop assert_pattern(pattern) do
    quote do
      assert Rule.accept(unquote(Macro.escape(pattern)))
      assert Rule.reject(unquote(Macro.escape(pattern)))
    end
  end

  defmacrop refute_pattern(pattern) do
    quote do
      assert_raise Rule.MalformedError, fn ->
        Rule.accept(unquote(Macro.escape(pattern)))
      end
    end
  end

  doctest Rule

  describe "URIs" do
    test "generates rule with catch-all URI" do
      assert_pattern(%URI{})
    end

    test "generates rule with pattern" do
      assert_pattern(%URI{scheme: "https"})
    end

    test "generates rule with pattern and guard" do
      assert_pattern(%URI{scheme: "https"} when scheme != "ftp")
    end
  end

  describe "IPv4 Addresses" do
    test "generates rule with empty tuple" do
      assert_pattern({_, _, _, _})
    end

    test "generates rule with tuple and guard" do
      assert_pattern({a, b, _, _} when a < b)
    end

    test "generates rule with address string" do
      assert_pattern("127.1")
      assert_pattern("127.0.0.1")
      assert_pattern("192.168.1")
      assert_pattern("192.168.1.1")
    end

    test "generates rule with CIDR" do
      assert_pattern("192.168.100.14/24")
    end

    test "raises on malformed address string" do
      refute_pattern("256.x")
    end

    test "raises on malformed CIDR" do
      refute_pattern("192.168.100.14/64")
    end
  end

  describe "IPv6 Addresses" do
    test "generates rule with empty tuple" do
      assert_pattern({_, _, _, _, _, _, _, _})
    end

    test "generates rule with tuple and guard" do
      assert_pattern({a, b, _, _, _, _, _, _} when a < b)
    end
  end

  describe "other malformed values" do
    test "raises on malformed tuple" do
      refute_pattern({_, _, _, _, _, _, _})
    end

    test "raises on empty string" do
      refute_pattern("")
    end
  end
end
