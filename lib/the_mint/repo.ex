defmodule TheMint.Repo do
  use Ecto.Repo,
    otp_app: :the_mint,
    adapter: Ecto.Adapters.Postgres
end
