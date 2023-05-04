defmodule LiveSvelte do
  use Phoenix.Component
  import Phoenix.HTML

  alias LiveSvelte.Slots
  alias LiveSvelte.SSR

  attr(
    :props,
    :map,
    default: %{},
    doc: "Props to pass to the Svelte component",
    examples: [%{foo: "bar"}, %{foo: "bar", baz: 1}, %{list: [], baz: 1, qux: %{a: 1, b: 2}}]
  )

  attr(
    :name,
    :string,
    required: true,
    doc: "Name of the Svelte component",
    examples: ["YourComponent", "directory/Example"]
  )

  attr(
    :class,
    :string,
    default: nil,
    doc: "Class to apply to the Svelte component",
    examples: ["my-class", "my-class another-class"]
  )

  attr(
    :ssr,
    :boolean,
    default: true,
    doc: "Whether to render the component on the server",
    examples: [true, false]
  )

  slot(:inner_block, doc: "Inner block of the Svelte component")

  @doc """
  Renders a Svelte component on the server.
  """
  def render(assigns) do
    init = Map.get(assigns, :__changed__, nil) == nil

    slots =
      assigns
      |> Slots.rendered_slot_map()
      |> Slots.js_process()

    ssr_code =
      if init and Map.get(assigns, :ssr) do
        try do
          SSR.render(assigns.name, Map.get(assigns, :props, %{}), slots)
        rescue
          SSR.NodeNotConfigured -> nil
        end
      end

    assigns =
      assigns
      |> assign(:init, init)
      |> assign(:slots, slots)
      |> assign(:ssr_render, ssr_code)

    ~H"""
    <script><%= raw(@ssr_render["head"]) %></script>
    <div
      id={id(@name)}
      data-name={@name}
      data-props={json(@props)}
      data-slots={Slots.base_encode_64(@slots) |> json}
      phx-update="ignore"
      phx-hook="SvelteHook"
      class={@class}
    >
      <style><%= raw(@ssr_render["css"]["code"]) %></style>
      <%= raw(@ssr_render["html"]) %>
    </div>
    """
  end

  defp json(props) do
    props
    |> Jason.encode()
    |> case do
      {:ok, encoded} -> encoded
      {:error, _} -> ""
    end
  end

  defp id(name), do: "#{name}-#{System.unique_integer([:positive])}"

  @doc false
  def get_props(assigns) do
    prop_keys =
      assigns
      |> Map.get(:__changed__)
      |> Map.keys()

    assigns
    |> Map.filter(fn
      {:svelte_opts, _v} -> false
      {k, _v} -> k in prop_keys
    end)
  end

  @doc false
  def get_ssr(assigns) do
    case get_in(assigns, [:svelte_opts, :ssr]) do
      nil -> true
      ssr -> ssr
    end
  end

  @doc false
  defmacro sigil_V({:<<>>, _meta, [string]}, []) do
    path = "./assets/svelte/_build/#{__CALLER__.module}.svelte"

    with :ok <- File.mkdir_p(Path.dirname(path)) do
      File.write!(path, string)
    end

    quote do
      ~H"""
      <LiveSvelte.render
        name={"_build/#{__MODULE__}"}
        props={get_props(assigns)}
        ssr={get_ssr(assigns)}
        class={get_in(assigns, [:svelte_opts, :class])}
      />
      """
    end
  end
end
