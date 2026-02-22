defmodule LiveSvelte.Test do
  @moduledoc """
  Helpers for testing LiveSvelte components and views.

  Use `get_svelte/1` or `get_svelte/2` to introspect rendered Svelte component
  roots (name, id, props, handlers, slots, ssr) from a LiveView or HTML string.
  Requires the `lazy_html` dependency in test (add `{:lazy_html, ">= 0.1.0", only: :test}` to mix.exs).

  ## Examples

      # From a LiveView, get first Svelte component
      {:ok, view, _html} = live(conn, "/")
      svelte = LiveSvelte.Test.get_svelte(view)

      # Get by component name
      svelte = LiveSvelte.Test.get_svelte(view, name: "MyComponent")

      # Get by DOM id
      svelte = LiveSvelte.Test.get_svelte(view, id: "MyComponent-1")

      # From HTML string
      svelte = LiveSvelte.Test.get_svelte(html, name: "Counter")
  """
  @compile {:no_warn_undefined, LazyHTML}

  @doc """
  Extracts Svelte component information from a LiveView or HTML string.

  When multiple Svelte components are present, use the second argument with
  `:name` or `:id` to select one.

  Returns a map with:
    * `:name` - Component name (from `data-name`)
    * `:id` - DOM id of the root element
    * `:props` - Decoded props (from `data-props` JSON)
    * `:handlers` - Event handlers (from `data-handlers` if present; currently %{} in LiveSvelte)
    * `:slots` - Map of slot name -> decoded HTML string (from `data-slots` base64 values)
    * `:ssr` - Whether SSR was used (from `data-ssr`)

  ## Options
    * `:name` - Find component by name (`data-name`)
    * `:id` - Find component by id attribute

  ## Examples

      get_svelte(view)
      get_svelte(view, name: "Counter")
      get_svelte(html, id: "Counter-1")
  """
  def get_svelte(html_or_view, opts \\ [])

  def get_svelte(view, opts) when is_struct(view, Phoenix.LiveViewTest.View) do
    view |> Phoenix.LiveViewTest.render() |> get_svelte(opts)
  end

  def get_svelte(html, opts) when is_binary(html) do
    if Code.ensure_loaded?(LazyHTML) do
      lazy_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("[phx-hook='SvelteHook']")

      tree = find_component!(lazy_html, opts)

      %{
        name: attr_from_tree(tree, "data-name"),
        id: attr_from_tree(tree, "id"),
        props: decode_props(attr_from_tree(tree, "data-props")),
        handlers: decode_handlers(attr_from_tree(tree, "data-handlers")),
        slots: decode_slots(attr_from_tree(tree, "data-slots")),
        ssr: parse_ssr(attr_from_tree(tree, "data-ssr"))
      }
    else
      raise "LazyHTML is not installed. Add {:lazy_html, \">= 0.1.0\", only: :test} to your dependencies to use LiveSvelte.Test"
    end
  end

  defp decode_props(nil), do: %{}
  defp decode_props(""), do: %{}
  defp decode_props(str), do: Jason.decode!(str)

  defp decode_handlers(nil), do: %{}
  defp decode_handlers(""), do: %{}
  defp decode_handlers(_str), do: %{}  # LiveSvelte does not emit data-handlers yet

  defp decode_slots(nil), do: %{}
  defp decode_slots(""), do: %{}
  defp decode_slots(str) do
    str
    |> Jason.decode!()
    |> Map.new(fn {key, value} -> {key, Base.decode64!(value)} end)
  end

  defp parse_ssr(nil), do: false
  defp parse_ssr("true"), do: true
  defp parse_ssr("false"), do: false
  defp parse_ssr(_), do: false

  defp find_component!(components, opts) do
    components_tree = LazyHTML.to_tree(components)

    available =
      components_tree
      |> Enum.map(&"#{attr_from_tree(&1, "data-name")}##{attr_from_tree(&1, "id")}")
      |> Enum.join(", ")

    matched =
      Enum.reduce(opts, components_tree, fn
        {:id, id}, result ->
          filtered = Enum.filter(result, &(attr_from_tree(&1, "id") == id))
          if filtered == [] do
            raise "No Svelte component found with id=\"#{id}\". Available: #{available}"
          end
          filtered

        {:name, name}, result ->
          filtered = Enum.filter(result, &(attr_from_tree(&1, "data-name") == name))
          if filtered == [] do
            raise "No Svelte component found with name=\"#{name}\". Available: #{available}"
          end
          filtered

        {key, _}, _ ->
          raise ArgumentError, "invalid keyword option for get_svelte/2: #{key}"
      end)

    case matched do
      [svelte | _] -> svelte
      [] -> raise "No Svelte components found in the rendered HTML"
    end
  end

  defp attr_from_tree({_tag, attrs, _children}, name) do
    case Enum.find(attrs, fn {k, _v} -> k == name end) do
      {^name, value} -> value
      nil -> nil
    end
  end
end
