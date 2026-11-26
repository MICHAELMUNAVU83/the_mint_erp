defmodule TheMint.Split do
  @moduledoc """
  Works out how a sale's money is divided.

    share account = sale total × split%   (stored in cost_account_*)
    main account  = sale total − share   (stored in profit_account_*)

  Change `amounts/2` if the formula should differ.
  """

  alias TheMint.Settings

  def amounts(total, split_percent) do
    cost_share = total |> Decimal.mult(split_percent) |> Decimal.div(100) |> Decimal.round(2)
    cost_share = cost_share |> Decimal.min(total) |> Decimal.max(0)
    %{cost: cost_share, profit: Decimal.sub(total, cost_share)}
  end

  @doc "Builds the split snapshot stored on a sale from current settings."
  def for_sale(total) do
    settings = Settings.all()
    pct = Settings.split_percent()
    %{cost: cost, profit: profit} = amounts(total, pct)

    %{
      split_percent: pct,
      cost_account_code: blank_to_nil(settings["subaccount"]),
      cost_account_amount: cost,
      profit_account_code: nil,
      profit_account_amount: profit
    }
  end

  defp blank_to_nil(""), do: nil
  defp blank_to_nil(v), do: v
end
