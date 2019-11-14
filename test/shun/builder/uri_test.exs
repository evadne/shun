defmodule Shun.Builder.URITest do
  use ExUnit.Case, async: true

  defmodule URIVerifier do
    use Shun.Builder

    reject %URI{scheme: scheme} when scheme != "https"
    accept %URI{host: host} when host == "example.com"
    reject %URI{path: "/reject" <> _}
    reject %URI{host: host} when host == "reject.example.com"
    handle %URI{}, &custom_handle_uri/1

    def custom_handle_uri(uri) do
      cond do
        uri.host == "dynamic.example.com" -> :reject
        true -> :accept
      end
    end
  end

  describe "verify_uri/1" do
    test "rejects http://example.com" do
      assert :reject = URIVerifier.verify_uri(URI.parse("http://example.com"))
    end

    test "accepts https://example.com" do
      assert :accept = URIVerifier.verify_uri(URI.parse("https://example.com"))
    end

    test "rejects reject.example.com" do
      assert :reject = URIVerifier.verify_uri(URI.parse("https://reject.example.com"))
    end

    test "returns function for dynamic.example.com" do
      uri = URI.parse("https://dynamic.example.com")
      assert {:dynamic, fun} = URIVerifier.verify_uri(uri)
      assert :reject = fun.(uri)
    end

    test "returns function for hyper.example.com" do
      uri = URI.parse("https://hyper.example.com")
      assert {:dynamic, fun} = URIVerifier.verify_uri(uri)
      assert :accept = fun.(uri)
    end
  end

  describe "verify/1" do
    test "accepts example.com" do
      assert {:ok, %URI{host: "example.com"}} = Shun.verify(URIVerifier, "https://example.com")
    end

    test "rejects reject.example.com" do
      assert {:error, :rejected} = Shun.verify(URIVerifier, "https://reject.example.com")
    end

    test "rejects dynamic.example.com" do
      result = Shun.verify(URIVerifier, "https://dynamic.example.com")
      assert {:error, :rejected} = result
    end

    test "accepts hyper.example.com" do
      result = Shun.verify(URIVerifier, "https://hyper.example.com")
      assert {:ok, _address} = result
    end

    test "accepts 127.0.0.1" do
      result = Shun.verify(URIVerifier, "https://127.0.0.1")
      assert {:ok, _address} = result
    end
  end
end
