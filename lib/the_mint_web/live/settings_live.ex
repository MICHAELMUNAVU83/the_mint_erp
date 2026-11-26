defmodule TheMintWeb.SettingsLive do
  use TheMintWeb, :live_view

  import TheMintWeb.Helpers, only: [fmt: 1]
  alias TheMint.{Settings, Split}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Settings",
       settings: Settings.all(),
       preview: %{"selling" => "150"}
     )}
  end

  @impl true
  def handle_event("change", %{"settings" => s} = params, socket) do
    {:noreply,
     assign(socket,
       settings: Map.merge(socket.assigns.settings, s),
       preview: Map.merge(socket.assigns.preview, params["preview"] || %{})
     )}
  end

  def handle_event("save", %{"settings" => s}, socket) do
    case Decimal.parse(s["split_percent"] || "") do
      {d, ""} ->
        if Decimal.lt?(d, 0) or Decimal.gt?(d, 100) do
          {:noreply, put_flash(socket, :error, "Split % must be a number between 0 and 100")}
        else
          :ok = Settings.put_all(s)

          {:noreply,
           socket |> assign(settings: Settings.all()) |> put_flash(:info, "Settings saved")}
        end

      _ ->
        {:noreply, put_flash(socket, :error, "Split % must be a number between 0 and 100")}
    end
  end

  defp preview(settings, %{"selling" => s}) do
    with {sell, _} <- Decimal.parse(s), {pct, _} <- Decimal.parse(settings["split_percent"]) do
      Split.amounts(sell, pct) |> Map.put(:total, sell)
    else
      _ -> nil
    end
  end

  defp share_label(%{"subaccount_name" => n}) when n != "", do: n
  defp share_label(_), do: "Share account"

  @impl true
  def render(assigns) do
    assigns = assign(assigns, result: preview(assigns.settings, assigns.preview))

    ~H"""
    <.header>
      Sales split
      <:subtitle>
        Every sale is attributed x % to the <b>share account</b>
        and the rest to the <b>main account</b>. This is for reporting only — payments are recorded manually.
      </:subtitle>
    </.header>

    <div class="mt-6 max-w-2xl">
      <form phx-change="change" phx-submit="save" class="card p-6 space-y-5">
        <.input
          name="settings[subaccount_name]"
          value={@settings["subaccount_name"]}
          label="Share account name (shown on Sales)"
        />
        <.input
          name="settings[subaccount]"
          value={@settings["subaccount"]}
          label="Share account reference (optional)"
        />
        <.input
          type="number"
          step="0.01"
          min="0"
          max="100"
          name="settings[split_percent]"
          value={@settings["split_percent"]}
          label="Share of each sale (x %)"
        />

        <div class="rounded-lg bg-zinc-50 p-4">
          <p class="text-sm font-medium">Preview</p>
          <.input
            name="preview[selling]"
            value={@preview["selling"]}
            label="Selling"
            type="number"
            step="0.01"
          />
          <div :if={@result} class="mt-4 text-sm space-y-1.5">
            <p>{share_label(@settings)}: <b>{fmt(@result.cost)}</b></p>
            <p>Main account: <b>{fmt(@result.profit)}</b></p>
          </div>
        </div>

        <div class="flex justify-end">
          <.button phx-disable-with="Saving…">Save settings</.button>
        </div>
      </form>
    </div>
    """
  end
end
