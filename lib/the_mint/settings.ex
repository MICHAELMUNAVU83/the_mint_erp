defmodule TheMint.Settings do
  @moduledoc """
  Key/value settings for the sales split (used for reporting).

    * `subaccount`          – optional code/reference of the account receiving split_percent.
    * `subaccount_name`     – label shown for that share in the UI.
    * `split_percent`       – x, the % of each sale attributed to that account.
  """

  alias TheMint.Repo
  alias TheMint.Settings.Setting

  @defaults %{
    "subaccount" => "",
    "subaccount_name" => "",
    "split_percent" => "50"
  }

  def keys, do: Map.keys(@defaults)

  def all do
    stored = Repo.all(Setting) |> Map.new(&{&1.key, &1.value || ""})
    Map.merge(@defaults, Map.take(stored, keys()))
  end

  def get(key), do: Map.fetch!(all(), key)

  def put_all(%{} = attrs) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    rows =
      for {k, v} <- Map.take(attrs, keys()),
          do: %{key: k, value: String.trim(v || ""), inserted_at: now, updated_at: now}

    Repo.insert_all(Setting, rows,
      on_conflict: {:replace, [:value, :updated_at]},
      conflict_target: :key
    )

    :ok
  end

  def split_percent do
    case Decimal.parse(get("split_percent")) do
      {d, _} -> d
      :error -> Decimal.new(100)
    end
  end
end
