defmodule TheMintWeb.SalesLive do
  use TheMintWeb, :live_view

  import TheMintWeb.Helpers, only: [fmt: 1]
  alias TheMint.Accounts.User
  alias TheMint.Sales
  alias TheMint.Sales.Sale

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(page_title: "Sales", expanded: nil) |> load(Date.utc_today())}
  end

  defp load(socket, date) do
    assign(socket,
      date: date,
      sales: Sales.list_sales(date: date, status: "paid"),
      summary: Sales.summary_for_date(date)
    )
  end

  @impl true
  def handle_event("date", %{"date" => d}, socket) do
    case Date.from_iso8601(d) do
      {:ok, date} -> {:noreply, load(socket, date)}
      _ -> {:noreply, socket}
    end
  end

  def handle_event("shift", %{"days" => n}, socket) do
    {:noreply, load(socket, Date.add(socket.assigns.date, String.to_integer(n)))}
  end

  def handle_event("toggle", %{"id" => id}, socket) do
    id = String.to_integer(id)
    {:noreply, assign(socket, expanded: if(socket.assigns.expanded == id, do: nil, else: id))}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    if User.admin?(socket.assigns.current_user) do
      id |> Sales.get_sale!() |> Sales.delete_sale()

      {:noreply,
       socket
       |> put_flash(:info, "Sale deleted and stock restored.")
       |> assign(expanded: nil)
       |> load(socket.assigns.date)}
    else
      {:noreply, put_flash(socket, :error, "Only admins can delete sales.")}
    end
  end

  defp day_label(date) do
    case Date.diff(Date.utc_today(), date) do
      0 -> "Today"
      1 -> "Yesterday"
      _ -> Calendar.strftime(date, "%a %d %b %Y")
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Sales
      <:subtitle>
        {day_label(@date)} · {@summary.count} sales · {fmt(@summary.revenue)}
      </:subtitle>
      <:actions>
        <div class="flex items-center gap-1">
          <button
            phx-click="shift"
            phx-value-days="-1"
            class="btn-secondary !px-2"
            aria-label="Previous day"
          >
            <.icon name="hero-chevron-left-mini" class="h-4 w-4" />
          </button>
          <form phx-change="date">
            <input type="date" name="date" value={@date} class="field !w-auto py-1.5" />
          </form>
          <button
            phx-click="shift"
            phx-value-days="1"
            disabled={@date == Date.utc_today()}
            class="btn-secondary !px-2 disabled:opacity-30"
            aria-label="Next day"
          >
            <.icon name="hero-chevron-right-mini" class="h-4 w-4" />
          </button>
        </div>
      </:actions>
    </.header>

    <div class="card mt-6 overflow-hidden">
      <p :if={@sales == []} class="py-12 text-center text-sm text-zinc-500">No sales on this day.</p>
      <div :for={s <- @sales} class="border-b border-zinc-100 last:border-0">
        <div class="flex items-center gap-3 px-5 py-3 hover:bg-zinc-50 transition">
          <button
            phx-click="toggle"
            phx-value-id={s.id}
            class="flex-1 flex items-center gap-4 text-left min-w-0"
          >
            <span class="w-12 text-sm text-zinc-400 tabular-nums">
              {Calendar.strftime(s.inserted_at, "%H:%M")}
            </span>
            <div class="flex-1 min-w-0">
              <p class="text-sm truncate">
                {s.items |> Enum.map(& &1.product_name) |> Enum.join(", ")}
              </p>
              <p class="text-xs text-zinc-400">
                #{s.id} · {Sale.method_label(s.payment_method)}<span :if={s.user}> · {s.user.name || s.user.email}</span>
              </p>
            </div>
            <span class="w-24 text-right text-sm font-medium tabular-nums">
              {fmt(s.total_amount)}
            </span>
          </button>
          <a
            href={~p"/sales/#{s.id}/receipt"}
            target="_blank"
            class="btn-secondary !px-3 inline-flex items-center gap-1.5 text-xs shrink-0"
            title="Print receipt"
          >
            <.icon name="hero-printer-mini" class="h-4 w-4" />
            <span class="hidden sm:inline">Print receipt</span>
          </a>
          <button
            :if={User.admin?(@current_user)}
            phx-click="delete"
            phx-value-id={s.id}
            data-confirm="Delete this sale? Its stock quantities will be restored."
            class="btn-secondary !px-3 text-xs shrink-0 text-red-600 hover:text-red-700"
            title="Delete sale"
          >
            <.icon name="hero-trash-mini" class="h-4 w-4" />
            <span class="hidden sm:inline">Delete</span>
          </button>
        </div>
        <div :if={@expanded == s.id} class="bg-zinc-50 px-5 py-4 text-sm">
          <div :for={i <- s.items} class="flex justify-between py-0.5">
            <span>{i.quantity} × {i.product_name}</span>
            <span class="tabular-nums">{fmt(i.subtotal)}</span>
          </div>
          <div class="mt-3 pt-3 border-t border-zinc-200 flex flex-wrap gap-x-6 gap-y-1 text-xs text-zinc-500">
            <p :if={s.payment_method == "cash" && s.amount_paid}>
              Cash received: <span class="text-zinc-900">{fmt(s.amount_paid)}</span>
              · Change:
              <span class="text-zinc-900">{fmt(Decimal.sub(s.amount_paid, s.total_amount))}</span>
            </p>
            <p :if={s.payment_reference}>Ref: {s.payment_reference}</p>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
