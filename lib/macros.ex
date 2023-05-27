defmodule LiveSvelte.Macros do
  @moduledoc """
  Macros to improve the developer experience of crossing the Liveview/Svelte boundary.
  """

  @doc """
  Generates functions local to your current module that can be used to render Svelte components.
  """
  defmacro __using__(_opts) do
    get_svelte_components()
    |> Enum.map(fn name ->
      quote do
        def unquote(:"#{name}")(assigns) do
          props =
            assigns
            |> Map.filter(fn
              {:svelte_opts, _v} -> false
              {k, _v} -> k not in [:__changed__]
              _ -> false
            end)

          var!(assigns) =
            assign(assigns,
              __component_name: unquote(name),
              props: props || %{}
            )

          ~H"""
          <LiveSvelte.svelte
            name={Map.get(var!(assigns), :__component_name)}
            class={Map.get(var!(assigns), :class)}
            ssr={false}
            props={Map.get(var!(assigns), :props, %{})}
          />
          """
        end
      end
    end)
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
end
