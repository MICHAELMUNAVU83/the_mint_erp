defmodule TheMint.Settings.Setting do
  use Ecto.Schema

  schema "settings" do
    field :key, :string
    field :value, :string

    timestamps()
  end
end
