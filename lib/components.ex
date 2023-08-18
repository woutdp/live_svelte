defmodule LiveSvelte.Components do
  @moduledoc """
  Macros to improve the developer experience of crossing the Liveview/Svelte boundary.
  """

  @doc """
  Generates functions local to your current module that can be used to render Svelte components.
  """
  defmacro __using__(_opts) do
    get_svelte_components()
    |> Enum.map(&name_to_function/1)
  end

  @doc """
  TODO: This could perhaps be optimized to only read the files once per compilation.
  """
  def get_svelte_components do
    "./assets/svelte/*.svelte"
    |> Path.wildcard()
    |> Enum.map(fn path -> Path.basename(path, ".svelte") end)
  end

  defp name_to_function(name) do
    quote do
      def unquote(:"#{name}")(assigns) do
        props = Map.drop(assigns, [:__changed__, :__given__, :ssr, :class, :socket])

        var!(assigns) =
          assigns
          |> Map.put(:__component_name, unquote(name))
          |> Map.put_new(:ssr, true)
          |> Map.put_new(:class, nil)
          |> Map.put_new(:socket, nil)
          |> assign(:props, props)

        ~H"""
        <LiveSvelte.svelte
          name={@__component_name}
          class={@class}
          socket={@socket}
          ssr={@ssr}
          props={@props}
        />
        """
      end
    end
  end
end
