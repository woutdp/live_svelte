defmodule ExampleWeb.LiveForm do
  @moduledoc """
  LiveView demo for `useLiveForm()` composable.
  Demonstrates server-side validation with Ecto changesets and form reset on success.
  """
  use ExampleWeb, :live_view

  # ---------------------------------------------------------------------------
  # Inline embedded schema (no database required)
  # ---------------------------------------------------------------------------

  defmodule Schema do
    @moduledoc false
    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do
      field(:name, :string)
      field(:email, :string)
    end

    def changeset(schema \\ %__MODULE__{}, attrs) do
      schema
      |> cast(attrs, [:name, :email])
      |> validate_required([:name, :email])
      |> validate_format(:email, ~r/@/, message: "must contain @")
      |> validate_length(:name, min: 2, message: "must be at least 2 characters")
    end
  end

  defp empty_form do
    Ecto.Changeset.cast(%Schema{name: "", email: ""}, %{}, [:name, :email])
    |> to_form(as: "form_data")
  end

  # ---------------------------------------------------------------------------
  # LiveView callbacks
  # ---------------------------------------------------------------------------

  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: empty_form())}
  end

  def handle_event("validate", params, socket) do
    attrs = params["form_data"] || %{}

    form =
      Schema.changeset(%Schema{}, attrs)
      |> to_form(as: "form_data", action: :validate)

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("submit", params, socket) do
    attrs = params["form_data"] || %{}
    changeset = Schema.changeset(%Schema{}, attrs)

    if changeset.valid? do
      name = attrs["name"] || ""
      email = attrs["email"] || ""
      msg = "Info submitted: #{name} (#{email})"
      # Successful submit — show success toast, tell the client to reset, return a clean form.
      {:reply, %{reset: true},
       socket
       |> put_flash(:info, msg)
       |> assign(form: empty_form())}
    else
      form = changeset |> to_form(as: "form_data", action: :validate)
      {:reply, %{}, assign(socket, form: form)}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col justify-center items-center gap-6 p-6">
      <h2 class="text-center text-2xl font-light my-4">Form (useLiveForm)</h2>
      <p class="text-sm text-base-content/50 text-center max-w-md">
        Server-side Ecto changeset validation with debounced change events and automatic form reset on success.
      </p>
      <.svelte name="FormDemo" props={%{form: @form}} socket={@socket} />
    </div>
    """
  end
end
