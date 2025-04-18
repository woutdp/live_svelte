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
    get "/simple", PageController, :svelte_1
    get "/plus-minus-svelte", PageController, :svelte_2
    get "/lodash", PageController, :svelte_3
    live "/plus-minus-liveview", LiveExample1
    live "/counter", LiveExample2
    live "/plus-minus-hybrid", LiveExample3
    live "/log-list", LiveExample4
    live "/breaking-news", LiveExample5
    live "/chat", LiveExample6
    live "/lights", LiveLights
    live "/struct", LiveStruct
    live "/sigil", LiveSigil
    live "/live-json", LiveJson
    live "/slots-simple", LiveSlotsSimple
    live "/slots-dynamic", LiveSlotsDynamic
    live "/composition", LiveComposition
    live "/client-side-loading", LiveClientSideLoading
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
