defmodule TheMintWeb.UsersLive do
  use TheMintWeb, :live_view

  alias TheMint.Accounts
  alias TheMint.Accounts.User

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(page_title: "Users", issued: nil) |> load()}
  end

  defp load(socket), do: assign(socket, users: Accounts.list_users())

  @impl true
  def handle_params(params, _url, socket),
    do: {:noreply, apply_action(socket, socket.assigns.live_action, params)}

  defp apply_action(socket, :new, _) do
    pw = generate_password()

    assign(socket,
      user: %User{},
      form: to_form(Accounts.change_user(%User{}, %{"password" => pw, "role" => "cashier"}))
    )
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    user = Accounts.get_user!(id)
    assign(socket, user: user, form: to_form(Accounts.change_user_for_edit(user)))
  end

  defp apply_action(socket, :index, _), do: assign(socket, user: nil, form: nil)

  @impl true
  def handle_event("validate", %{"user" => params}, socket) do
    {:noreply,
     assign(socket, form: to_form(Map.put(changeset(socket, params), :action, :validate)))}
  end

  def handle_event("generate", _, socket) do
    params = Map.put(socket.assigns.form.params || %{}, "password", generate_password())
    {:noreply, assign(socket, form: to_form(changeset(socket, params)))}
  end

  def handle_event("save", %{"user" => params}, socket) do
    %{user: user, current_user: me} = socket.assigns

    result =
      cond do
        user.id == me.id and (params["role"] != "admin" or params["is_active"] == "false") ->
          {:error, :self}

        is_nil(user.id) ->
          Accounts.create_user(params)

        true ->
          Accounts.update_user(user, params)
      end

    case result do
      {:ok, saved} ->
        pw = params["password"]
        issued = if pw not in [nil, ""], do: %{user: saved, password: pw}

        {:noreply,
         socket
         |> assign(issued: issued)
         |> put_flash(:info, "User saved")
         |> load()
         |> push_patch(to: ~p"/users")}

      {:error, :self} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "You can't remove your own admin access or deactivate yourself"
         )}

      {:error, cs} ->
        {:noreply, assign(socket, form: to_form(cs))}
    end
  end

  def handle_event("dismiss", _, socket), do: {:noreply, assign(socket, issued: nil)}

  defp changeset(%{assigns: %{user: %User{id: nil} = u}}, params),
    do: Accounts.change_user(u, params)

  defp changeset(%{assigns: %{user: u}}, params), do: Accounts.change_user_for_edit(u, params)

  # Easy to read out loud / type: no 0/O, 1/l/I.
  @alphabet ~c"abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789"
  defp generate_password do
    for _ <- 1..10, into: "", do: <<Enum.random(@alphabet)>>
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Users
      <:subtitle>{length(@users)} accounts · tap one to edit or reset the password</:subtitle>
      <:actions>
        <.link patch={~p"/users/new"} class="btn-primary">
          <.icon name="hero-plus-mini" class="h-4 w-4" /> Add user
        </.link>
      </:actions>
    </.header>

    <div :if={@issued} class="mt-6 card p-5 border-2 !border-brand-ink bg-brand-yellow/20">
      <div class="flex items-start gap-4">
        <div class="flex-1">
          <p class="font-medium">Login details for {@issued.user.name || @issued.user.email}</p>
          <p class="text-xs text-zinc-500 mt-0.5">
            Share these now — the password is stored encrypted and can't be shown again. You can always reset it.
          </p>
          <div class="mt-3 grid sm:grid-cols-2 gap-2 text-sm font-mono">
            <p>Email: <b>{@issued.user.email}</b></p>
            <p>Password: <b id="issued-pw">{@issued.password}</b></p>
          </div>
        </div>
        <div class="flex flex-col gap-2">
          <button
            type="button"
            class="btn-secondary text-xs"
            onclick={"navigator.clipboard.writeText('Email: #{@issued.user.email}\\nPassword: ' + document.getElementById('issued-pw').innerText); this.innerText='Copied'"}
          >
            Copy
          </button>
          <button phx-click="dismiss" class="text-xs text-zinc-500 hover:text-zinc-900">Done</button>
        </div>
      </div>
    </div>

    <div class="card mt-6 overflow-hidden">
      <.link
        :for={u <- @users}
        patch={~p"/users/#{u.id}/edit"}
        class="flex items-center gap-4 px-5 py-3 border-b border-zinc-100 last:border-0 hover:bg-zinc-50 transition"
      >
        <div class="h-9 w-9 rounded-full bg-zinc-100 flex items-center justify-center text-sm font-semibold">
          {String.first(u.name || u.email) |> String.upcase()}
        </div>
        <div class="flex-1 min-w-0">
          <p class={["font-medium truncate", !u.is_active && "text-zinc-400"]}>
            {u.name || u.email}<span :if={u.id == @current_user.id} class="text-xs text-zinc-400"> (you)</span>
          </p>
          <p class="text-xs text-zinc-400 truncate">{u.email}</p>
        </div>
        <span :if={!u.is_active} class="text-xs rounded-full px-2 py-0.5 bg-rose-50 text-rose-600">
          Disabled
        </span>
        <span class={[
          "text-xs rounded-full px-2 py-0.5 font-medium",
          (u.role == "admin" && "bg-brand-ink text-brand-yellow") || "bg-zinc-100 text-zinc-600"
        ]}>
          {User.role_label(u.role)}
        </span>
      </.link>
    </div>

    <.modal :if={@form} id="user-modal" show on_cancel={JS.patch(~p"/users")}>
      <h2 class="text-xl brand-title">{if @user.id, do: "Edit user", else: "New user"}</h2>
      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:name]} label="Name" />
        <.input field={@form[:email]} type="email" label="Email (used to log in)" />
        <div>
          <div class="flex items-end gap-2">
            <div class="flex-1">
              <.input
                field={@form[:password]}
                type="text"
                autocomplete="off"
                label={
                  if @user.id, do: "New password (leave blank to keep current)", else: "Password"
                }
              />
            </div>
            <button type="button" phx-click="generate" class="btn-secondary mb-0.5 text-xs">
              Generate
            </button>
          </div>
          <p class="text-xs text-zinc-400 mt-1">Shown after saving so you can share it.</p>
        </div>
        <.input
          field={@form[:role]}
          type="select"
          label="Role"
          options={[
            {"Cashier – sales only", "cashier"},
            {"Shot Girl – sales only", "shot_girl"},
            {"Sales Rep (Waitress) – sales only", "sales_rep"},
            {"Admin – users & settings", "admin"}
          ]}
        />
        <.input field={@form[:is_active]} type="checkbox" label="Can log in" />
        <:actions>
          <.link patch={~p"/users"} class="btn-secondary">Cancel</.link>
          <.button phx-disable-with="Saving…">Save</.button>
        </:actions>
      </.simple_form>
    </.modal>
    """
  end
end
