defmodule TheMint.Sales do
  @moduledoc "Sales context – recording sales and stock. Payments are recorded manually."

  import Ecto.Query
  alias Ecto.Multi
  alias TheMint.{Repo, Split}
  alias TheMint.Products.Product
  alias TheMint.Sales.{Sale, SaleItem}

  def list_sales(opts \\ []) do
    from(s in Sale, order_by: [desc: s.inserted_at], preload: [:items, :user])
    |> maybe_on_date(opts[:date])
    |> maybe_status(opts[:status])
    |> limit(^(opts[:limit] || 200))
    |> Repo.all()
  end

  defp maybe_status(q, nil), do: q
  defp maybe_status(q, status), do: where(q, [s], s.status == ^status)

  defp maybe_on_date(q, nil), do: q
  defp maybe_on_date(q, %Date{} = d), do: where(q, [s], fragment("?::date", s.inserted_at) == ^d)

  def get_sale!(id), do: Repo.get!(Sale, id)

  def get_sale_with_items!(id), do: Sale |> Repo.get!(id) |> Repo.preload([:items, :user])

  @doc "Deletes a sale and restores its item quantities to products that still exist."
  def delete_sale(%Sale{} = sale) do
    sale = Repo.preload(sale, :items)

    Multi.new()
    |> Multi.delete(:sale, sale)
    |> Multi.run(:stock, fn repo, _ ->
      Enum.each(sale.items, fn item ->
        if item.product_id do
          from(p in Product, where: p.id == ^item.product_id)
          |> repo.update_all(inc: [stock_quantity: item.quantity])
        end
      end)

      {:ok, nil}
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{sale: deleted}} -> {:ok, deleted}
      {:error, _step, reason, _} -> {:error, reason}
    end
  end

  @doc "Totals for paid sales on a day."
  def summary_for_date(%Date{} = d), do: summary(d, d)

  defp paid_between(from, to) do
    from(s in Sale,
      where:
        s.status == "paid" and fragment("?::date", s.inserted_at) >= ^from and
          fragment("?::date", s.inserted_at) <= ^to
    )
  end

  @doc "Totals for paid sales between two dates (inclusive)."
  def summary(%Date{} = from, %Date{} = to) do
    from(s in paid_between(from, to),
      select: %{
        count: count(s.id),
        revenue: coalesce(sum(s.total_amount), 0),
        cost: coalesce(sum(s.total_cost), 0)
      }
    )
    |> Repo.one()
  end

  @doc "Revenue per payment method, e.g. %{\"cash\" => 1200, \"mpesa\" => 800}."
  def revenue_by_method(from, to) do
    from(s in paid_between(from, to),
      group_by: s.payment_method,
      select: {s.payment_method, %{count: count(s.id), revenue: sum(s.total_amount)}}
    )
    |> Repo.all()
    |> Map.new()
  end

  @doc "Revenue and profit per day, oldest first, with empty days filled in."
  def daily_totals(from, to) do
    rows =
      from(s in paid_between(from, to),
        group_by: fragment("?::date", s.inserted_at),
        select:
          {fragment("?::date", s.inserted_at),
           %{revenue: sum(s.total_amount), cost: sum(s.total_cost), count: count(s.id)}}
      )
      |> Repo.all()
      |> Map.new()

    zero = %{revenue: Decimal.new(0), cost: Decimal.new(0), count: 0}
    for d <- Date.range(from, to), do: {d, Map.get(rows, d, zero)}
  end

  @doc "Best-selling products by revenue."
  def top_products(from, to, limit \\ 8) do
    from(i in SaleItem,
      join: s in subquery(paid_between(from, to)),
      on: s.id == i.sale_id,
      group_by: i.product_name,
      order_by: [desc: sum(i.subtotal)],
      limit: ^limit,
      select: %{
        name: i.product_name,
        quantity: sum(i.quantity),
        revenue: sum(i.subtotal),
        profit: sum(i.subtotal - i.unit_cost * i.quantity)
      }
    )
    |> Repo.all()
  end

  @doc """
  Records a sale. `lines` is a list of `{product_id, quantity}`.
  Locks the products, checks stock, decrements it and inserts the sale atomically.
  """
  def create_sale(lines, attrs) do
    ids = Enum.map(lines, &elem(&1, 0))
    method = attrs[:payment_method] || "cash"

    Multi.new()
    |> Multi.run(:products, fn repo, _ ->
      products =
        from(p in Product, where: p.id in ^ids, lock: "FOR UPDATE")
        |> repo.all()
        |> Map.new(&{&1.id, &1})

      Enum.reduce_while(lines, {:ok, products}, fn {id, qty}, acc ->
        case products[id] do
          nil ->
            {:halt, {:error, "A product in the cart no longer exists"}}

          %{stock_quantity: s, name: n} when s < qty ->
            {:halt, {:error, "Only #{s} left of #{n}"}}

          _ ->
            {:cont, acc}
        end
      end)
    end)
    |> Multi.run(:sale, fn repo, %{products: products} ->
      items =
        Enum.map(lines, fn {id, qty} ->
          p = products[id]

          %SaleItem{
            product_id: id,
            product_name: p.name,
            quantity: qty,
            unit_cost: p.buying_price,
            unit_price: p.price,
            subtotal: Decimal.mult(p.price, qty)
          }
        end)

      total = sum(items, & &1.subtotal)
      total_cost = sum(items, &Decimal.mult(&1.unit_cost, &1.quantity))
      split = Split.for_sale(total)

      repo.insert(%Sale{
        total_amount: total,
        total_cost: total_cost,
        amount_paid: if(method == "cash", do: attrs[:amount_paid], else: total),
        payment_method: method,
        status: "paid",
        payment_reference: blank_to_nil(attrs[:payment_reference]),
        user_id: attrs[:user_id],
        split_percent: split.split_percent,
        cost_account_code: split.cost_account_code,
        cost_account_amount: split.cost_account_amount,
        profit_account_code: split.profit_account_code,
        profit_account_amount: split.profit_account_amount,
        items: items
      })
    end)
    |> Multi.run(:stock, fn repo, _ ->
      Enum.each(lines, fn {id, qty} ->
        from(p in Product, where: p.id == ^id) |> repo.update_all(inc: [stock_quantity: -qty])
      end)

      {:ok, nil}
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{sale: sale}} -> {:ok, sale}
      {:error, _step, reason, _} -> {:error, reason}
    end
  end

  defp sum(items, fun), do: Enum.reduce(items, Decimal.new(0), &Decimal.add(fun.(&1), &2))

  defp blank_to_nil(v) when is_binary(v),
    do: if(String.trim(v) == "", do: nil, else: String.trim(v))

  defp blank_to_nil(v), do: v
end
