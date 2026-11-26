defmodule TheMintWeb.PosLive do
  use TheMintWeb, :live_view

  import TheMintWeb.Helpers, only: [fmt: 1]
  alias TheMint.{Products, Sales}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       page_title: "New Sale",
       search: "",
       category: "all",
       categories: Products.list_categories(),
       cart: %{},
       payment_method: "cash",
       amount_paid: "",
       last_sale: nil,
       done_sale: nil
     )
     |> load_products()}
  end

  defp load_products(socket) do
    assign(socket,
      products:
        Products.list_products(
          active_only: true,
          search: socket.assigns.search,
          category: socket.assigns.category
        )
    )
  end

  @impl true
  def handle_event("search", %{"search" => term}, socket) do
    {:noreply, socket |> assign(search: term) |> load_products()}
  end

  def handle_event("category", %{"category" => category}, socket) do
    {:noreply, socket |> assign(category: category) |> load_products()}
  end

  def handle_event("add", %{"id" => id}, socket) do
    id = String.to_integer(id)

    product =
      case socket.assigns.cart[id] do
        {_, product} -> product
        nil -> Enum.find(socket.assigns.products, &(&1.id == id))
      end

    {qty, _} = socket.assigns.cart[product.id] || {0, product}

    if qty + 1 > product.stock_quantity do
      {:noreply,
       put_flash(socket, :error, "Only #{product.stock_quantity} of #{product.name} in stock")}
    else
      {:noreply, update(socket, :cart, &Map.put(&1, product.id, {qty + 1, product}))}
    end
  end

  def handle_event("dec", %{"id" => id}, socket) do
    id = String.to_integer(id)

    cart =
      case socket.assigns.cart[id] do
        {1, _} -> Map.delete(socket.assigns.cart, id)
        {q, p} -> Map.put(socket.assigns.cart, id, {q - 1, p})
      end

    {:noreply, assign(socket, cart: cart)}
  end

  def handle_event("clear", _, socket), do: {:noreply, assign(socket, cart: %{}, amount_paid: "")}

  def handle_event("payment", %{"payment_method" => m, "amount_paid" => paid}, socket) do
    {:noreply,
     assign(socket,
       payment_method: m,
       amount_paid: paid
     )}
  end

  def handle_event("checkout", _, %{assigns: %{cart: cart}} = socket) when cart == %{} do
    {:noreply, put_flash(socket, :error, "Cart is empty")}
  end

  def handle_event("checkout", _, socket) do
    %{cart: cart, payment_method: method, amount_paid: paid, current_user: user} = socket.assigns
    lines = Enum.map(cart, fn {id, {qty, _}} -> {id, qty} end)
    total = cart_total(cart)

    paid =
      cond do
        method != "cash" ->
          total

        true ->
          case Decimal.parse(paid) do
            {d, _} -> d
            :error -> nil
          end
      end

    cond do
      is_nil(paid) ->
        {:noreply, put_flash(socket, :error, "Enter the cash received")}

      Decimal.lt?(paid, total) ->
        {:noreply, put_flash(socket, :error, "Amount paid is less than the total")}

      true ->
        case Sales.create_sale(lines, %{
               payment_method: method,
               amount_paid: paid,
               user_id: user.id
             }) do
          {:ok, sale} ->
            {:noreply,
             socket
             |> assign(
               cart: %{},
               amount_paid: "",
               last_sale: sale,
               done_sale: sale
             )
             |> load_products()}

          {:error, reason} ->
            {:noreply, socket |> put_flash(:error, error_text(reason)) |> load_products()}
        end
    end
  end

  def handle_event("new_sale", _, socket) do
    {:noreply, socket |> assign(done_sale: nil) |> clear_flash()}
  end

  defp error_text(reason) when is_binary(reason), do: reason
  defp error_text(_), do: "Could not record sale"

  defp cart_total(cart) do
    Enum.reduce(cart, Decimal.new(0), fn {_, {qty, p}}, acc ->
      Decimal.add(acc, Decimal.mult(p.price, qty))
    end)
  end

  @impl true
  def render(assigns) do
    assigns = assign(assigns, total: cart_total(assigns.cart))

    ~H"""
    <div class="grid grid-cols-1 lg:grid-cols-[minmax(0,1fr)_400px] gap-8">
      <section>
        <form phx-change="search" phx-submit="search" class="relative mb-4">
          <.icon
            name="hero-magnifying-glass-mini"
            class="absolute left-3 top-3 h-4 w-4 text-zinc-400"
          />
          <input
            type="text"
            name="search"
            value={@search}
            placeholder="Search products"
            phx-debounce="200"
            autofocus
            class="field pl-9 py-3 rounded-xl shadow-sm"
          />
        </form>

        <div class="mb-4 flex gap-2 overflow-x-auto pb-1">
          <button
            :for={{key, label} <- [{"all", "All"} | Enum.map(@categories, &{&1, &1})]}
            phx-click="category"
            phx-value-category={key}
            class={["chip whitespace-nowrap", @category == key && "chip-active"]}
          >
            {label}
          </button>
        </div>

        <div class="grid grid-cols-2 sm:grid-cols-3 xl:grid-cols-4 2xl:grid-cols-5 gap-4">
          <button
            :for={p <- @products}
            phx-click="add"
            phx-value-id={p.id}
            disabled={p.stock_quantity == 0}
            class={[
              "card relative text-left p-4 rounded-2xl hover:-translate-y-0.5 hover:shadow-md hover:border-zinc-300 active:scale-[0.98] transition disabled:opacity-40 disabled:cursor-not-allowed disabled:hover:translate-y-0 disabled:hover:shadow-none",
              @cart[p.id] && "!border-zinc-900 ring-1 ring-zinc-900 shadow-md"
            ]}
          >
            <span
              :if={@cart[p.id]}
              class="absolute -top-2 -right-2 h-6 min-w-6 px-1.5 rounded-full bg-brand-red text-white text-xs font-semibold flex items-center justify-center shadow"
            >
              {elem(@cart[p.id], 0)}
            </span>
            <div class={[
              "mb-3 h-10 w-10 rounded-xl flex items-center justify-center text-sm font-semibold",
              tile_color(p.name)
            ]}>
              {String.first(p.name)}
            </div>
            <p class="text-sm font-medium leading-snug line-clamp-2 min-h-[2.5rem]">{p.name}</p>
            <p class="mt-1 text-[11px] text-zinc-400">{p.category}</p>
            <div class="mt-3 flex items-end justify-between">
              <span class="font-semibold tracking-tight">{fmt(p.price)}</span>
              <span class={["text-xs", (p.stock_quantity <= 5 && "text-amber-600") || "text-zinc-400"]}>
                {if p.stock_quantity == 0, do: "Out", else: "#{p.stock_quantity} left"}
              </span>
            </div>
          </button>
        </div>
        <p :if={@products == []} class="text-sm text-zinc-500 py-12 text-center">
          No products found. <.link navigate={~p"/products/new"} class="underline">Add one</.link>
        </p>
      </section>

      <aside class="card p-6 rounded-2xl shadow-sm h-fit lg:sticky lg:top-20">
        <div class="flex items-center justify-between">
          <h2 class="text-xl brand-title">
            Current sale
            <span :if={@cart != %{}} class="ml-1 text-sm font-normal text-zinc-400">
              · {@cart |> Map.values() |> Enum.map(&elem(&1, 0)) |> Enum.sum()} items
            </span>
          </h2>
          <button
            :if={@cart != %{}}
            phx-click="clear"
            class="text-xs text-zinc-400 hover:text-zinc-900"
          >
            Clear
          </button>
        </div>

        <p :if={@cart == %{}} class="text-sm text-zinc-400 py-10 text-center">
          Tap a product to add it
        </p>

        <ul class="mt-4 space-y-3 max-h-[45vh] overflow-y-auto -mx-2 px-2">
          <li
            :for={{id, {qty, p}} <- Enum.sort_by(@cart, fn {_, {_, p}} -> p.name end)}
            class="flex items-center gap-3"
          >
            <div class="flex-1 min-w-0">
              <p class="text-sm truncate">{p.name}</p>
              <p class="text-xs text-zinc-400">{fmt(Decimal.mult(p.price, qty))}</p>
            </div>
            <div class="flex items-center rounded-lg border border-zinc-200">
              <button
                phx-click="dec"
                phx-value-id={id}
                class="px-2 py-1 text-zinc-500 hover:text-zinc-900"
              >
                <.icon name="hero-minus-mini" class="h-4 w-4" />
              </button>
              <span class="w-6 text-center text-sm font-medium">{qty}</span>
              <button
                phx-click="add"
                phx-value-id={id}
                class="px-2 py-1 text-zinc-500 hover:text-zinc-900"
              >
                <.icon name="hero-plus-mini" class="h-4 w-4" />
              </button>
            </div>
          </li>
        </ul>

        <div class="border-t border-zinc-100 mt-5 pt-4 flex items-baseline justify-between">
          <span class="text-sm text-zinc-500">Total</span>
          <span class="text-3xl font-semibold tracking-tight">{fmt(@total)}</span>
        </div>

        <form phx-change="payment" phx-submit="checkout" class="mt-4 space-y-3">
          <div class="grid grid-cols-2 gap-1 rounded-lg bg-zinc-100 p-1">
            <label
              :for={m <- TheMint.Sales.Sale.payment_methods()}
              class={[
                "text-center text-sm rounded-md py-1.5 cursor-pointer transition",
                (@payment_method == m && "bg-white shadow-sm font-medium") || "text-zinc-500"
              ]}
            >
              <input
                type="radio"
                name="payment_method"
                value={m}
                checked={@payment_method == m}
                class="hidden"
              />
              {TheMint.Sales.Sale.method_label(m)}
            </label>
          </div>
          <div :if={@payment_method == "cash"}>
            <input
              type="text"
              inputmode="decimal"
              name="amount_paid"
              value={@amount_paid}
              placeholder="Cash received"
              required
              class="field"
            />
            <p :if={change(@amount_paid, @total)} class="mt-2 flex justify-between text-sm">
              <span class="text-zinc-500">Change</span>
              <span class="font-medium">{fmt(change(@amount_paid, @total))}</span>
            </p>
          </div>
          <input :if={@payment_method != "cash"} type="hidden" name="amount_paid" value="" />
          <button
            type="submit"
            disabled={@cart == %{} or (@payment_method == "cash" and !change(@amount_paid, @total))}
            class="btn-primary w-full py-3.5 text-base rounded-xl"
          >
            Complete sale · {fmt(@total)}
          </button>
        </form>

        <p :if={@last_sale} class="mt-4 text-xs text-zinc-400 text-center">
          Last sale #{@last_sale.id} · {fmt(@last_sale.total_amount)} ·
          <a href={~p"/sales/#{@last_sale.id}/receipt"} target="_blank" class="underline">
            Print receipt
          </a>
        </p>
      </aside>
    </div>

    <div
      :if={@done_sale}
      class="fixed inset-0 z-50 bg-zinc-900/30 flex items-center justify-center p-4"
    >
      <div class="bg-white rounded-xl shadow-xl p-6 w-full max-w-md text-center">
        <div class="mx-auto h-12 w-12 rounded-full bg-brand-yellow text-brand-ink border-2 border-brand-ink flex items-center justify-center">
          <.icon name="hero-check" class="h-7 w-7" />
        </div>
        <h2 class="mt-4 text-2xl brand-title">Sale recorded</h2>
        <p class="text-sm text-zinc-500 mt-1">
          Sale #{@done_sale.id} · {fmt(@done_sale.total_amount)} · {TheMint.Sales.Sale.method_label(
            @done_sale.payment_method
          )}
        </p>
        <p :if={@done_sale.payment_method == "cash" && @done_sale.amount_paid} class="text-sm mt-2">
          Change: <b>{fmt(Decimal.sub(@done_sale.amount_paid, @done_sale.total_amount))}</b>
        </p>
        <div class="mt-5 flex gap-2">
          <a
            href={~p"/sales/#{@done_sale.id}/receipt"}
            target="_blank"
            class="btn-secondary flex-1 inline-flex items-center justify-center gap-1.5"
          >
            <.icon name="hero-printer-mini" class="h-4 w-4" /> Print receipt
          </a>
          <button phx-click="new_sale" class="btn-primary flex-1">New sale</button>
        </div>
      </div>
    </div>
    """
  end

  @tile_colors ~w(bg-amber-100 text-amber-700 bg-sky-100 text-sky-700 bg-emerald-100 text-emerald-700 bg-rose-100 text-rose-700 bg-violet-100 text-violet-700 bg-orange-100 text-orange-700)
               |> Enum.chunk_every(2)
               |> Enum.map(&Enum.join(&1, " "))

  defp tile_color(name), do: Enum.at(@tile_colors, :erlang.phash2(name, length(@tile_colors)))

  defp change(paid, total) do
    case Decimal.parse(paid) do
      {d, _} -> if Decimal.gte?(d, total), do: Decimal.sub(d, total)
      :error -> nil
    end
  end
end
