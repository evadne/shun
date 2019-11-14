defmodule Shun.Preset do
  @moduledoc """
  Specifies how additional reusable rules are provided.

  Modules that implement this behaviour can be used with `Shun.Builder.accept/1`, 
  `Shun.Builder.reject/1` or  `Shun.Builder.handle/2`. If modules implement a default handler
  function then they can be used with `Shun.Builder.handle/1` as well.
  """

  @doc """
  Returns a list of Rules (`t:Shun.Rule.t/0`) for use in Provider modules at compile-time.

  Rules can be built by using convenience functions in `Shun.Rule`.

  If you need to implement dynamic rules that query external resources, you should use
  `Shun.Builder.handle/2` and pass the function reference.
  """
  @callback rules(:accept) :: [Shun.Rule.t()]
  @callback rules(:reject) :: [Shun.Rule.t()]
  @callback rules(:handle) :: [Shun.Rule.t()]
  @callback rules(:handle, Shun.Rule.handle_fun()) :: [Shun.Rule.t()]

  defmodule DefaultHandlerError do
    @moduledoc """
    Represents a compile-time error when the Preset module has not provided a default handler,
    yet is referred to with `Shun.Builder.handle/1`.
    """

    defexception message: nil

    @impl true
    def exception(module) do
      %__MODULE__{message: "#{module} does not provide a default handler"}
    end
  end

  defmacro __using__(options) do
    quote do
      @behaviour Shun.Preset
      @targets Keyword.get(unquote(options), :targets, [])

      @impl Shun.Preset
      def rules(:accept), do: Enum.map(@targets, &Shun.Rule.accept(&1))

      @impl Shun.Preset
      def rules(:reject), do: Enum.map(@targets, &Shun.Rule.reject(&1))

      @impl Shun.Preset
      def rules(:handle), do: raise(DefaultHandlerError, module: __MODULE__)

      @impl Shun.Preset
      def rules(:handle, handler), do: Enum.map(@targets, &Shun.Rule.handle(&1, handler))

      defoverridable rules: 1, rules: 2
    end
  end
end
