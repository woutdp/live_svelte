defmodule ExampleWeb.Router do
  use ExampleWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {ExampleWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ExampleWeb do
    pipe_through :browser

    get "/", PageController, :home
    # same order as in app.html.heex:
    get "/hello-world", PageController, :hello_world
    get "/lodash", PageController, :lodash
    live "/live-struct", LiveStruct
    live "/live-simple-counter", LiveSimpleCounter
    live "/live-lights", LiveLights
    live "/live-sigil", LiveSigil
    get "/plus-minus-svelte", PageController, :plus_minus_svelte
    live "/live-plus-minus", LivePlusMinus
    live "/live-plus-minus-hybrid", LivePlusMinusHybrid
    live "/live-static-color", LiveStaticColor
    live "/live-log-list", LiveLogList
    live "/live-breaking-news", LiveBreakingNews
    live "/live-chat", LiveChat
    live "/live-json", LiveJson
    live "/live-slots-simple", LiveSlotsSimple
    live "/live-slots-dynamic", LiveSlotsDynamic
    live "/live-client-side-loading", LiveClientSideLoading
    # Ecto Examples
    live "/live-notes-otp", LiveNotesOtp
    # not referenced in app.html.heex:
    live "/live-composition", LiveComposition
  end

  # Other scopes may use custom stacks.
  # scope "/api", ExampleWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:example, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ExampleWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
