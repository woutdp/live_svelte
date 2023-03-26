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
    assigns
    |> Enum.map(fn
      {:inner_block, value} -> {:default, value}
      key_value -> key_value
    end)
    |> Enum.into(%{})
  end

  @doc false
  def base_encode_64(assigns) do
    assigns
    |> Enum.map(fn {key, value} -> {key, Base.encode64(value)} end)
    |> Enum.into(%{})
  end

  @doc false
  defp filter_slots_from_assigns(assigns) do
    assigns
    |> Enum.filter(fn
      {_key, [%{__slot__: _}]} -> true
      _ -> false
    end)
    |> Enum.into(%{})
  end

  @doc false
  defp render_slots(assigns) do
    Enum.reduce(assigns, %{}, fn
      {key, value}, acc -> Map.put(acc, key, render(%{slot: value}))
    end)
  end

  @doc false
  defp render(assigns) do
    ~H"""
    <%= if assigns[:slot] do %>
      <%= render_slot(@slot) %>
    <% end %>
    """
    |> Phoenix.HTML.Safe.to_iodata()
    |> List.to_string()
    |> String.trim()
  end
end
