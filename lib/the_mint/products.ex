defmodule TheMint.Products do
  @moduledoc "Products context."

  import Ecto.Query
  alias TheMint.Repo
  alias TheMint.Products.Product

  def list_products(opts \\ []) do
    from(p in Product, order_by: p.name)
    |> maybe_active(opts[:active_only])
    |> maybe_search(opts[:search])
    |> maybe_category(opts[:category])
    |> Repo.all()
  end

  def list_categories do
    from(p in Product,
      where: p.is_active,
      distinct: true,
      order_by: p.category,
      select: p.category
    )
    |> Repo.all()
  end

  defp maybe_active(q, true), do: where(q, [p], p.is_active)
  defp maybe_active(q, _), do: q

  defp maybe_search(q, term) when term in [nil, ""], do: q

  defp maybe_search(q, term) do
    t = "%#{term}%"
    where(q, [p], ilike(p.name, ^t) or ilike(p.sku, ^t))
  end

  defp maybe_category(q, category) when category in [nil, "", "all"], do: q
  defp maybe_category(q, category), do: where(q, [p], p.category == ^category)

  def get_product!(id), do: Repo.get!(Product, id)

  def create_product(attrs), do: %Product{} |> Product.changeset(attrs) |> Repo.insert()
  def update_product(%Product{} = p, attrs), do: p |> Product.changeset(attrs) |> Repo.update()
  def delete_product(%Product{} = p), do: Repo.delete(p)
  def change_product(%Product{} = p, attrs \\ %{}), do: Product.changeset(p, attrs)
end
