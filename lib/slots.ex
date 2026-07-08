defmodule LiveSvelte.Slots do
  @moduledoc false

  import Phoenix.Component

  @doc false
  def rendered_slot_map(assigns) do
    assigns
    |> filter_slots_from_assigns()
    |> render_slots()
  end

  @doc false
  def js_process(assigns) do
    Map.new(assigns, fn
      {:inner_block, value} -> {:default, value}
      key_value -> key_value
    end)
  end

  @doc false
  def base_encode_64(assigns) do
    Map.new(assigns, fn {key, value} -> {key, Base.encode64(value)} end)
  end

  @doc """
  Filters assigns to return only slot entries.
  Slots are identified by having a list value containing maps with `__slot__` key.
  """
  def filter_slots_from_assigns(assigns) do
    assigns
    |> Enum.filter(fn
      {_key, value} when is_list(value) ->
        Enum.any?(value, fn
          %{__slot__: _} -> true
          _ -> false
        end)

      _ ->
        false
    end)
    |> Map.new()
  end

  defp render_slots(assigns) do
    Map.new(assigns, fn {key, value} -> {key, render(%{slot: value})} end)
  end

  defp render(assigns) do
    ~H"""
    <%= if assigns[:slot] do %>
      {render_slot(@slot)}
    <% end %>
    """
    |> Phoenix.HTML.Safe.to_iodata()
    |> List.to_string()
    |> String.trim()
  end
end
