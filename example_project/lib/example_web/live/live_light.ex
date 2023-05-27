defmodule ExampleWeb.LiveLights do
  use ExampleWeb, :live_view
  require Logger

  def mount(_params, _session, socket) do
    Logger.info(socket)
    {:ok, assign(socket, %{brightness: 10, previous: nil})}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-screen-xl mx-auto p-4 flex flex-col gap-4">
      <h1 class="text-center text-2xl font-light my-4">Light Bulb Controller</h1>
      <.svelte name="LightStatusBar" props={%{brightness: @brightness}} />
      <.svelte name="LightControllers" props={%{isOn: isOn?(@brightness)}} />
    </div>
    """
  end

  def handle_event("up", _, socket) do
    brightness = socket.assigns.brightness
    Logger.info(brightness)

    case brightness do
      100 ->
        {:noreply, socket}

      _ ->
        new_brightness = brightness + 10
        {:noreply, assign(socket, %{brightness: new_brightness, previous: brightness})}
    end
  end

  def handle_event("down", _, socket) do
    brightness = socket.assigns.brightness
    Logger.info(brightness)

    case brightness do
      0 ->
        {:noreply, socket}

      _ ->
        new_brightness = brightness - 10
        {:noreply, assign(socket, %{brightness: new_brightness, previous: brightness})}
    end
  end

  def handle_event("on", _, socket) do
    previous = socket.assigns.previous
    brightness = socket.assigns.brightness
    {:noreply, assign(socket, %{brightness: previous, previous: brightness})}
  end

  def handle_event("off", _, socket) do
    previous = socket.assigns.brightness
    {:noreply, assign(socket, %{brightness: 0, previous: previous})}
  end

  defp isOn?(brightness) do
    brightness > 0
  end
end
