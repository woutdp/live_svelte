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
    "./assets/svelte/"
    |> Path.join("**/*.svelte")
    |> Path.wildcard()
    |> Enum.filter(&(not String.contains?(&1, "_build/")))
    |> Enum.map(fn path ->
      path
      |> Path.basename()
      |> String.replace(".svelte", "")
    end)
  end

  defp name_to_function(name) do
    quote do
      def unquote(:"#{name}")(assigns) do
        props =
          assigns
          |> Map.filter(fn
            {:svelte_opts, _v} -> false
            {k, _v} -> k not in [:__changed__, :__given__, :ssr]
            _ -> false
          end)

        var!(assigns) =
          assigns
          |> Map.put(:__component_name, unquote(name))
          |> Map.put_new(:ssr, true)
          |> Map.put_new(:class, nil)
          |> assign(:props, props)

        ~H"""
        <LiveSvelte.svelte
          name={@__component_name}
          class={@class}
          ssr={@ssr}
          props={@props}
        />
        """
      end
    end
  end
end
