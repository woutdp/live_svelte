defmodule LiveSvelte.Sigil do
  @moduledoc false

  import Phoenix.Component

  @doc false
  def get_props(assigns) do
    prop_keys =
      assigns
      |> Map.get(:__changed__)
      |> Map.keys()

    assigns
    |> Enum.filter(fn {k, _v} -> k in prop_keys end)
    |> Enum.into(%{})
  end

  @doc false
  defmacro sigil_V({:<<>>, _meta, [string]}, []) do
    path = "./assets/svelte/_build/#{__CALLER__.module}.svelte"
    with :ok <- File.mkdir_p(Path.dirname(path)) do
      File.write!(path, string)
    end

    quote do
      ~H"""
      <LiveSvelte.render name={"_build/#{__MODULE__}"} props={get_props(assigns)} />
      """
    end
  end
end
