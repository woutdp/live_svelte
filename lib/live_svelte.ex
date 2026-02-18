defmodule LiveSvelte do
  @external_resource "README.md"
  @moduledoc @external_resource
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  use Phoenix.Component
  import Phoenix.HTML
  import LiveSvelte.LiveJson

  alias Phoenix.LiveView
  alias LiveSvelte.Slots
  alias LiveSvelte.SSR

  # Override Phoenix's slot validation to accept arbitrary slot names.
  # This allows users to pass any named slot to Svelte components without
  # getting "undefined slot" warnings during compilation.
  @before_compile LiveSvelte.DynamicSlots

  attr :props, :map,
    default: %{},
    doc: "Props to pass to the Svelte component",
    examples: [%{foo: "bar"}, %{foo: "bar", baz: 1}, %{list: [], baz: 1, qux: %{a: 1, b: 2}}]

  attr :name, :string,
    required: true,
    doc: "Name of the Svelte component",
    examples: ["YourComponent", "directory/Example"]

  attr :id, :string,
    default: nil,
    doc:
      "Optional stable DOM id override. Auto-generated from the component name and props by " <>
        "default. Only needed when auto-detection is insufficient (e.g. two loops with the same component name)."

  attr :key, :any,
    default: nil,
    doc:
      "Identity key for stable DOM IDs in loops. When set, the DOM id becomes `name-key`. " <>
        "When not set, LiveSvelte auto-detects identity from props (id, key, index, idx keys)."

  attr :class, :string,
    default: nil,
    doc: "Class to apply to the Svelte component",
    examples: ["my-class", "my-class another-class"]

  attr :ssr, :boolean,
    default: true,
    doc: "Whether to render the component via NodeJS on the server",
    examples: [true, false]

  attr :socket, :map,
    default: nil,
    doc: "LiveView socket, only needed when ssr: true"

  attr :live_json_props, :map,
    default: %{},
    doc: "LiveJson props to pass to the Svelte component",
    examples: [%{my_big_data_set: %{some_data: 1}}]

  slot :inner_block, doc: "Inner block of the Svelte component"

  slot(:loading,
    doc: "LiveView rendered markup to show while the component is loading client-side"
  )

  @doc """
  Renders a Svelte component on the server.
  """
  def svelte(assigns) do
    init = assigns.__changed__ == nil
    dead = assigns.socket == nil or not LiveView.connected?(assigns.socket)
    ssr_active = Application.get_env(:live_svelte, :ssr, true)

    svelte_id = assigns.id || key_based_id(assigns.name, assigns.key, assigns.props, assigns.__changed__)

    if init and ssr_active and assigns.ssr and assigns.loading != [] do
      IO.warn(
        "The <:loading /> slot is incompatible with server-side rendering (ssr). Either remove the <:loading /> slot or set ssr={false}",
        Macro.Env.stacktrace(__ENV__)
      )
    end

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
      |> assign(:svelte_id, svelte_id)

    ~H"""
    <.live_json live_json_props={@live_json_props} svelte_id={@svelte_id}>
      <script>
        <%= raw(@ssr_render["head"]) %>
      </script>
    <div
      id={@svelte_id}
      data-name={@name}
      data-props={json(@props)}
      data-ssr={@ssr_render != nil}
      data-live-json={
        if @init, do: json(@live_json_props), else: @live_json_props |> Map.keys() |> json()
      }
      data-slots={@slots |> Slots.base_encode_64() |> json}
      phx-hook="SvelteHook"
      phx-update="ignore"
      class={@class}
    >
      <div id={"#{@svelte_id}-target"} data-svelte-target>
        <%= raw(@ssr_render["head"]) %>
        <style>
          <%= raw(@ssr_render["css"]["code"]) %>
        </style>
        <%= raw(@ssr_render["html"]) %>
        <%= render_slot(@loading) %>
      </div>
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
    json_library = Application.get_env(:live_svelte, :json_library, LiveSvelte.JSON)
    json_library.encode!(props)
  end

  # --- Deterministic ID generation ------------------------------------------------
  #
  # Priority: explicit `key` attr > auto-detected identity from props > counter fallback.
  #
  # The counter fallback is only safe for components that are NOT inside a
  # comprehension where LiveView may skip rendering unchanged items.

  defp key_based_id(name, key, _props, _changed) when not is_nil(key) do
    "#{name}-#{key}"
  end

  defp key_based_id(name, nil, props, changed) do
    case extract_identity(props) do
      nil ->
        maybe_reset_id_counters_for_update(changed)
        counter_id(name)
      identity ->
        "#{name}-#{identity}"
    end
  end

  @identity_keys [:id, "id", :key, "key", :index, "index", :idx, "idx"]

  defp extract_identity(props) when is_map(props) do
    Enum.find_value(@identity_keys, fn k -> Map.get(props, k) end)
  end

  defp extract_identity(_), do: nil

  # Detect new render cycles by tracking the total number of counter-based
  # component calls. When the total reaches the expected count from the
  # previous render, we know a new render has started and must reset counters
  # so ordinal positions produce the same DOM ids. This keeps LiveView from
  # replacing nodes and preserves Svelte component instances (and their local state).
  defp maybe_reset_id_counters_for_update(nil), do: :ok

  defp maybe_reset_id_counters_for_update(_changed) do
    total = Process.get(:live_svelte_total_counter, 0)
    expected = Process.get(:live_svelte_expected_total, :not_set)

    should_reset =
      case expected do
        :not_set -> total > 0
        n -> total >= n
      end

    if should_reset do
      Process.put(:live_svelte_expected_total, total)

      for name <- Process.get(:live_svelte_counter_names, []) do
        Process.put({:live_svelte_counter, name}, 0)
      end

      Process.put(:live_svelte_total_counter, 0)
    end

    :ok
  end

  # Simple counter for standalone (non-loop) components that lack identity props.
  defp counter_id(name) do
    Process.put(:live_svelte_counter_names, Enum.uniq([name | Process.get(:live_svelte_counter_names, [])]))
    Process.put(:live_svelte_total_counter, Process.get(:live_svelte_total_counter, 0) + 1)
    key = {:live_svelte_counter, name}
    count = Process.get(key, 0)
    Process.put(key, count + 1)
    if count == 0, do: name, else: "#{name}-#{count}"
  end

  @reserved_prop_keys [:__changed__, :__given__, :svelte_opts, :ssr, :class, :socket]

  @doc false
  def get_props(assigns) do
    prop_keys =
      case Map.get(assigns, :__changed__) do
        nil -> Map.keys(assigns)
        changed when is_map(changed) -> Map.keys(changed)
      end

    assigns
    |> Map.filter(fn
      {k, _v} when k in @reserved_prop_keys -> false
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
