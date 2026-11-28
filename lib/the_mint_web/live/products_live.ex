defmodule TheMintWeb.ProductsLive do
  use TheMintWeb, :live_view

  import TheMintWeb.Helpers, only: [fmt: 1]
  alias TheMint.Products
  alias TheMint.Products.Product

  @impl true
  def mount(_params, _session, socket) do
    admin = TheMint.Accounts.User.admin?(socket.assigns.current_user)

    {:ok,
     assign(socket, page_title: "Products", search: "", filter: "all", admin: admin) |> load()}
  end

  defp load(socket),
    do: assign(socket, products: Products.list_products(search: socket.assigns.search))

  @low_stock 5

  defp filtered(products, "low"), do: Enum.filter(products, &(&1.stock_quantity <= @low_stock))
  defp filtered(products, "hidden"), do: Enum.reject(products, & &1.is_active)
  defp filtered(products, _), do: products

  @impl true
  def handle_params(_params, _url, %{assigns: %{admin: false, live_action: action}} = socket)
      when action in [:new, :edit] do
    {:noreply,
     socket
     |> put_flash(:error, "Only admins can add or edit products.")
     |> push_patch(to: ~p"/products")}
  end

  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _), do: assign_form(socket, %Product{})

  defp apply_action(socket, :edit, %{"id" => id}),
    do: assign_form(socket, Products.get_product!(id))

  defp apply_action(socket, :index, _), do: assign(socket, product: nil, form: nil)

  defp assign_form(socket, product) do
    assign(socket, product: product, form: to_form(Products.change_product(product)))
  end

  @impl true
  def handle_event("search", %{"search" => term}, socket) do
    {:noreply, socket |> assign(search: term) |> load()}
  end

  def handle_event("filter", %{"filter" => f}, socket), do: {:noreply, assign(socket, filter: f)}

  def handle_event(event, _params, %{assigns: %{admin: false}} = socket)
      when event in ["validate", "save", "delete"] do
    {:noreply, put_flash(socket, :error, "Only admins can change products.")}
  end

  def handle_event("validate", %{"product" => params}, socket) do
    cs = Products.change_product(socket.assigns.product, params) |> Map.put(:action, :validate)
    {:noreply, assign(socket, form: to_form(cs))}
  end

  def handle_event("save", %{"product" => params}, socket) do
    result =
      case socket.assigns.product do
        %Product{id: nil} -> Products.create_product(params)
        p -> Products.update_product(p, params)
      end

    case result do
      {:ok, _} ->
        {:noreply,
         socket |> put_flash(:info, "Product saved") |> load() |> push_patch(to: ~p"/products")}

      {:error, cs} ->
        {:noreply, assign(socket, form: to_form(cs))}
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    case Products.get_product!(id) |> Products.delete_product() do
      {:ok, _} ->
        {:noreply,
         socket |> put_flash(:info, "Product deleted") |> load() |> push_patch(to: ~p"/products")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not delete product")}
    end
  end

  @impl true
  def render(assigns) do
    assigns =
      assign(assigns,
        rows: filtered(assigns.products, assigns.filter),
        low_count: length(filtered(assigns.products, "low"))
      )

    ~H"""
    <.header>
      Products
      <:subtitle>
        {length(@products)} products<span :if={@admin}> · tap one to edit</span>
      </:subtitle>
      <:actions :if={@admin}>
        <.link patch={~p"/products/new"} class="btn-primary">
          <.icon name="hero-plus-mini" class="h-4 w-4" /> Add product
        </.link>
      </:actions>
    </.header>

    <div class="mt-6 flex flex-col sm:flex-row sm:items-center gap-3">
      <form phx-change="search" phx-submit="search" class="relative sm:w-72">
        <.icon
          name="hero-magnifying-glass-mini"
          class="absolute left-3 top-2.5 h-4 w-4 text-zinc-400"
        />
        <input
          type="text"
          name="search"
          value={@search}
          placeholder="Search"
          phx-debounce="200"
          class="field pl-9"
        />
      </form>
      <div class="flex gap-1">
        <button
          :for={
            {key, label} <- [
              {"all", "All"},
              {"low", "Low stock (#{@low_count})"},
              {"hidden", "Hidden"}
            ]
          }
          phx-click="filter"
          phx-value-filter={key}
          class={["chip", @filter == key && "chip-active"]}
        >
          {label}
        </button>
      </div>
    </div>

    <div class="card mt-4 overflow-hidden">
      <div class="hidden sm:grid grid-cols-12 gap-4 px-5 py-2.5 text-xs text-zinc-500 border-b border-zinc-100">
        <span class="col-span-6">Product</span>
        <span class="col-span-2 text-right">Cost</span>
        <span class="col-span-2 text-right">Price</span>
        <span class="col-span-2 text-right">Stock</span>
      </div>
      <div
        :for={p <- @rows}
        phx-click={@admin && JS.patch(~p"/products/#{p}/edit")}
        class={[
          "grid grid-cols-12 gap-4 items-center px-5 py-3 border-b border-zinc-100 last:border-0",
          @admin && "cursor-pointer hover:bg-zinc-50 transition"
        ]}
      >
        <div class="col-span-8 sm:col-span-6 min-w-0">
          <p class={["font-medium truncate", !p.is_active && "text-zinc-400"]}>{p.name}</p>
          <p class="text-xs text-zinc-400">
            {p.sku || "No SKU"}<span :if={!p.is_active}> · hidden</span>
          </p>
        </div>
        <span class="hidden sm:block col-span-2 text-right text-sm text-zinc-500">
          {fmt(p.buying_price)}
        </span>
        <div class="col-span-4 sm:col-span-2 text-right">
          <p class="text-sm font-medium">{fmt(p.price)}</p>
          <p class="text-xs text-emerald-600">+{fmt(Decimal.sub(p.price, p.buying_price))}</p>
        </div>
        <div class="hidden sm:flex col-span-2 justify-end"><.stock qty={p.stock_quantity} /></div>
      </div>
      <p :if={@rows == []} class="px-5 py-12 text-center text-sm text-zinc-500">No products here.</p>
    </div>

    <.modal :if={@form} id="product-modal" show on_cancel={JS.patch(~p"/products")}>
      <h2 class="text-xl brand-title">{if @product.id, do: "Edit product", else: "New product"}</h2>
      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:name]} label="Name" />
        <.input field={@form[:category]} label="Category" />
        <.input field={@form[:sku]} label="SKU / barcode" placeholder="Optional" />
        <div class="grid grid-cols-2 gap-3">
          <.input field={@form[:buying_price]} type="number" step="0.01" label="Buying price" />
          <.input field={@form[:price]} type="number" step="0.01" label="Selling price" />
        </div>
        <.input field={@form[:stock_quantity]} type="number" label="In stock" />
        <.input field={@form[:is_active]} type="checkbox" label="Show on the sale screen" />
        <:actions>
          <button
            :if={@product.id}
            type="button"
            phx-click="delete"
            phx-value-id={@product.id}
            data-confirm="Delete this product?"
            class="mr-auto text-sm text-rose-600 hover:underline"
          >
            Delete
          </button>
          <.link patch={~p"/products"} class="btn-secondary">Cancel</.link>
          <.button phx-disable-with="Saving…">Save</.button>
        </:actions>
      </.simple_form>
    </.modal>
    """
  end

  attr :qty, :integer, required: true

  defp stock(assigns) do
    ~H"""
    <span class={[
      "rounded-full px-2 py-0.5 text-xs font-medium",
      cond do
        @qty == 0 -> "bg-rose-50 text-rose-600"
        @qty <= 5 -> "bg-amber-50 text-amber-700"
        true -> "bg-zinc-100 text-zinc-600"
      end
    ]}>
      {if @qty == 0, do: "Out", else: @qty}
    </span>
    """
  end
end
