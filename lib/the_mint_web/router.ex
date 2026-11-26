defmodule TheMintWeb.Router do
  use TheMintWeb, :router

  import TheMintWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TheMintWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  scope "/", TheMintWeb do
    pipe_through :browser

    get "/login", SessionController, :new
    post "/login", SessionController, :create
    delete "/logout", SessionController, :delete
  end

  scope "/", TheMintWeb do
    pipe_through [:browser, :require_user]

    get "/sales/:id/receipt", ReceiptController, :show

    live_session :authenticated, on_mount: [{TheMintWeb.UserAuth, :require_user}] do
      live "/", PosLive, :index
      live "/products", ProductsLive, :index
      live "/products/new", ProductsLive, :new
      live "/products/:id/edit", ProductsLive, :edit
      live "/sales", SalesLive, :index
    end
  end

  scope "/", TheMintWeb do
    pipe_through [:browser, :require_user, :require_admin]

    live_session :admin,
      on_mount: [{TheMintWeb.UserAuth, :require_user}, {TheMintWeb.UserAuth, :require_admin}] do
      live "/dashboard", DashboardLive, :index
      live "/users", UsersLive, :index
      live "/users/new", UsersLive, :new
      live "/users/:id/edit", UsersLive, :edit
      live "/settings", SettingsLive, :index
      live "/guide", GuideLive, :index
    end
  end

  if Application.compile_env(:the_mint, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: TheMintWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
