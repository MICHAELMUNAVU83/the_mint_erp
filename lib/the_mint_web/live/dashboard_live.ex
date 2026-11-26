defmodule TheMintWeb.DashboardLive do
  use TheMintWeb, :live_view

  import TheMintWeb.Helpers, only: [fmt: 1]
  alias TheMint.Sales
  alias TheMint.Sales.Sale

  @ranges [{"today", "Today"}, {"7", "Last 7 days"}, {"30", "Last 30 days"}]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(page_title: "Dashboard", ranges: @ranges) |> load("7")}
  end

  defp load(socket, range) do
    to = Date.utc_today()

    from =
      case range do
        "today" -> to
        n -> Date.add(to, -(String.to_integer(n) - 1))
      end

    summary = Sales.summary(from, to)

    assign(socket,
      range: range,
      summary: summary,
      profit: Decimal.sub(summary.revenue, summary.cost),
      by_method: Sales.revenue_by_method(from, to),
      daily: Sales.daily_totals(from, to),
      top: Sales.top_products(from, to)
    )
  end

  @impl true
  def handle_event("range", %{"range" => r}, socket) when r in ~w(today 7 30),
    do: {:noreply, load(socket, r)}

  defp avg(%{count: 0}), do: Decimal.new(0)
  defp avg(%{count: c, revenue: r}), do: Decimal.div(r, c)

  defp pct(_, 0), do: 0

  defp pct(part, total) do
    part |> Decimal.mult(100) |> Decimal.div(total) |> Decimal.round(0) |> Decimal.to_integer()
  end

  @impl true
  def render(assigns) do
    max_day =
      assigns.daily |> Enum.map(fn {_, d} -> d.revenue end) |> Enum.max(Decimal, fn -> 0 end)

    assigns = assign(assigns, max_day: max_day)

    ~H"""
    <.header>
      Dashboard
      <:actions>
        <div class="flex gap-1">
          <button
            :for={{key, label} <- @ranges}
            phx-click="range"
            phx-value-range={key}
            class={["chip", @range == key && "chip-active"]}
          >
            {label}
          </button>
        </div>
      </:actions>
    </.header>

    <div class="card mt-6 grid grid-cols-2 md:grid-cols-4 divide-x divide-zinc-100">
      <.stat label="Revenue" value={fmt(@summary.revenue)} hint={"#{@summary.count} sales"} />
      <.stat label="Profit" value={fmt(@profit)} hint="Selling − buying" />
      <.stat label="Average sale" value={fmt(avg(@summary))} />
      <.stat
        label="Margin"
        value={"#{pct(@profit, if(Decimal.eq?(@summary.revenue, 0), do: 0, else: @summary.revenue))}%"}
        hint="Profit ÷ revenue"
      />
    </div>

    <div class="mt-4 grid lg:grid-cols-3 gap-4">
      <div class="card p-5 lg:col-span-2">
        <p class="text-sm font-medium">Revenue by day</p>
        <div class="mt-4 flex items-end gap-1 h-40">
          <div
            :for={{d, t} <- @daily}
            class="flex-1 flex flex-col items-center justify-end h-full group"
            title={"#{Calendar.strftime(d, "%a %d %b")}: #{fmt(t.revenue)} (#{t.count} sales)"}
          >
            <div
              class="w-full max-w-10 rounded-t bg-brand-ink group-hover:bg-brand-red transition"
              style={"height: #{if Decimal.gt?(Decimal.new(to_string(@max_day)), 0), do: pct(t.revenue, @max_day), else: 0}%; min-height: 2px"}
            >
            </div>
          </div>
        </div>
        <div class="mt-1 flex gap-1 text-[10px] text-zinc-400">
          <span :for={{d, _} <- @daily} class="flex-1 text-center truncate">
            {if length(@daily) > 10, do: Calendar.strftime(d, "%d"), else: Calendar.strftime(d, "%a")}
          </span>
        </div>
      </div>

      <div class="card p-5">
        <p class="text-sm font-medium">Payment methods</p>
        <div :for={m <- Enum.uniq(Sale.payment_methods() ++ Map.keys(@by_method))} class="mt-4">
          <% row = @by_method[m] || %{count: 0, revenue: Decimal.new(0)} %>
          <div class="flex justify-between text-sm">
            <span>{Sale.method_label(m)} <span class="text-zinc-400">· {row.count}</span></span>
            <span class="font-medium tabular-nums">{fmt(row.revenue)}</span>
          </div>
          <div class="mt-1.5 h-2 rounded-full bg-zinc-100 overflow-hidden">
            <div
              class="h-full bg-brand-ink"
              style={"width: #{if Decimal.eq?(@summary.revenue, 0), do: 0, else: pct(row.revenue, @summary.revenue)}%"}
            >
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="card mt-4 overflow-hidden">
      <div class="grid grid-cols-12 gap-4 px-5 py-2.5 text-xs text-zinc-500 border-b border-zinc-100">
        <span class="col-span-6">Top products</span>
        <span class="col-span-2 text-right">Qty</span>
        <span class="col-span-2 text-right">Revenue</span>
        <span class="col-span-2 text-right">Profit</span>
      </div>
      <div
        :for={p <- @top}
        class="grid grid-cols-12 gap-4 px-5 py-2.5 text-sm border-b border-zinc-100 last:border-0"
      >
        <span class="col-span-6 truncate">{p.name}</span>
        <span class="col-span-2 text-right tabular-nums">{p.quantity}</span>
        <span class="col-span-2 text-right tabular-nums">{fmt(p.revenue)}</span>
        <span class="col-span-2 text-right tabular-nums text-emerald-600">{fmt(p.profit)}</span>
      </div>
      <p :if={@top == []} class="px-5 py-10 text-center text-sm text-zinc-500">
        No sales in this period.
      </p>
    </div>
    """
  end

  attr :label, :string, required: true
  attr :value, :any, required: true
  attr :hint, :string, default: nil

  defp stat(assigns) do
    ~H"""
    <div class="p-5">
      <p class="text-xs text-zinc-500">{@label}</p>
      <p class="mt-1 text-xl font-semibold tracking-tight tabular-nums">{@value}</p>
      <p :if={@hint} class="text-xs text-zinc-400 mt-0.5">{@hint}</p>
    </div>
    """
  end
end
