defmodule LiveSvelte do
  use Phoenix.Component
  import Phoenix.HTML
  import LiveSvelte.LiveJson

  alias Phoenix.LiveView
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

  attr(
    :socket,
    :map,
    default: nil,
    doc: "LiveView socket, should be provided when rendering inside LiveView"
  )

  attr(
    :live_json_props,
    :map,
    default: %{},
    doc: "LiveJson props to pass to the Svelte component",
    examples: [
      %{my_big_data_set: %{some_data: 1}}
    ]
  )

  slot(:inner_block, doc: "Inner block of the Svelte component")

  @doc """
  Renders a Svelte component on the server.
  """
  def svelte(assigns) do
    init = assigns.__changed__ == nil
    dead = assigns.socket == nil or not LiveView.connected?(assigns.socket)
    ssr_active = Application.get_env(:live_svelte, :ssr, true)

    slots =
      assigns
      |> Slots.rendered_slot_map()
      |> Slots.js_process()

    ssr_code =
      if init and dead and ssr_active and assigns.ssr do
        try do
          props =
            Map.merge(
              Map.get(assigns, :props, %{}),
              Map.get(assigns, :live_json_props, %{})
            )

          SSR.render(assigns.name, props, slots)
        rescue
          SSR.NotConfigured -> nil
        end
      end

    assigns =
      assigns
      |> assign(:init, init)
      |> assign(:slots, slots)
      |> assign(:ssr_render, ssr_code)

    ~H"""
    <.live_json live_json_props={@live_json_props}>
      <script><%= raw(@ssr_render["head"]) %></script>
      <div
        id={id(@name)}
        data-name={@name}
        data-props={json(@props)}
        data-ssr={@ssr_render != nil}
        data-live-json={if @init, do: json(@live_json_props), else: @live_json_props |> Map.keys() |> json()}
        data-slots={@slots |> Slots.base_encode_64() |> json}
        phx-update="ignore"
        phx-hook="SvelteHook"
        class={@class}
      >
        <%= raw(@ssr_render["head"]) %>
        <%= raw(@ssr_render["html"]) %>
      </div>
    </.live_json>
    """
  end

  def render(assigns) do
    IO.warn(
      "`LiveSvelte.render/1` is deprecated; call `LiveSvelte.svelte/1` instead.",
      Macro.Env.stacktrace(__ENV__)
    )

    svelte(assigns)
  end

  defp json(props) do
    Jason.encode!(props)
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
  def get_socket(assigns) do
    case get_in(assigns, [:svelte_opts, :socket]) || assigns[:socket] do
      %LiveView.Socket{} = socket -> socket
      _ -> nil
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
      <LiveSvelte.svelte
        name={"_build/#{__MODULE__}"}
        props={get_props(assigns)}
        socket={get_socket(assigns)}
        ssr={get_in(assigns, [:svelte_opts, :ssr]) != false}
        class={get_in(assigns, [:svelte_opts, :class])}
      />
      """
    end
  end
end
