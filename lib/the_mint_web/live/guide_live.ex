defmodule TheMintWeb.GuideLive do
  use TheMintWeb, :live_view

  @impl true
  def mount(_params, _session, socket), do: {:ok, assign(socket, page_title: "User Guide")}

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      User Guide
      <:subtitle>A quick reference for setting up and running The Mint ERP.</:subtitle>
    </.header>

    <div class="mt-6 grid gap-6 lg:grid-cols-[240px_minmax(0,1fr)]">
      <aside class="card h-fit p-4 lg:sticky lg:top-20">
        <p class="mb-3 text-xs font-semibold uppercase tracking-wide text-zinc-400">On this page</p>
        <nav class="flex flex-col text-sm">
          <a
            :for={{id, label} <- sections()}
            href={"##{id}"}
            class="rounded-lg px-3 py-2 hover:bg-zinc-100"
          >
            {label}
          </a>
        </nav>
      </aside>

      <div class="space-y-6">
        <.guide_section id="start" title="1. Start a new day">
          <ol class="list-decimal space-y-2 pl-5">
            <li>
              Open <.link navigate={~p"/products"} class="underline font-medium">Products</.link>.
            </li>
            <li>Select each product received and enter its opening quantity in <b>In stock</b>.</li>
            <li>Confirm its selling price, category and visibility, then save.</li>
            <li>Products with zero stock remain visible but cannot be added to a sale.</li>
          </ol>
        </.guide_section>

        <.guide_section id="staff" title="2. Create and manage staff">
          <p>
            Open <.link navigate={~p"/users"} class="underline font-medium">Users</.link>, then select <b>Add user</b>. Choose the role that matches the employee:
          </p>
          <ul class="mt-3 list-disc space-y-2 pl-5">
            <li><b>Cashier:</b> records counter sales.</li>
            <li><b>Shot Girl:</b> records her own shot sales.</li>
            <li><b>Sales Rep (Waitress):</b> records her own table sales.</li>
            <li>
              <b>Admin:</b> manages users and settings, views the dashboard, and can delete sales.
            </li>
          </ul>
          <p class="mt-3">
            Give every staff member a separate account. Sales are attached to the person who is logged in, making their activity identifiable.
          </p>
        </.guide_section>

        <.guide_section id="sales" title="3. Record a sale">
          <ol class="list-decimal space-y-2 pl-5">
            <li>
              Staff should sign in with their own account and open <.link
                navigate={~p"/"}
                class="underline font-medium"
              >New Sale</.link>.
            </li>
            <li>
              Use the category tabs—such as Beer, Cocktails, Shots or Mixers—to find products quickly.
            </li>
            <li>Tap products to add them, select the payment method and complete checkout.</li>
            <li>Print the receipt when needed. Stock reduces automatically after checkout.</li>
          </ol>
        </.guide_section>

        <.guide_section id="review" title="4. Review sales and staff activity">
          <p>
            Open <.link navigate={~p"/sales"} class="underline font-medium">Sales</.link>
            and choose a date. Every sale displays the staff member who recorded it. Expand a sale to inspect its items and payment details.
          </p>
          <p class="mt-3">
            Use <.link navigate={~p"/dashboard"} class="underline font-medium">Dashboard</.link>
            for revenue, profit, payment-method and best-selling-product summaries.
          </p>
        </.guide_section>

        <.guide_section id="corrections" title="5. Correct a mistaken sale">
          <p>
            Only an admin can delete a sale. In <.link
              navigate={~p"/sales"}
              class="underline font-medium"
            >Sales</.link>, locate the transaction and select <b>Delete</b>. Confirm carefully: the sale is removed and its product quantities are returned to stock.
          </p>
        </.guide_section>

        <.guide_section id="products" title="6. Products and stock">
          <ul class="list-disc space-y-2 pl-5">
            <li>Edit a product to change its name, category, price or stock quantity.</li>
            <li>Hide an unavailable product by turning off <b>Show on the sale screen</b>.</li>
            <li>The Low stock filter highlights products with five or fewer units.</li>
            <li>Buying price is currently optional for operations and may remain zero.</li>
          </ul>
        </.guide_section>

        <.guide_section id="security" title="7. Admin safety checklist">
          <ul class="list-disc space-y-2 pl-5">
            <li>Do not share the admin password with sales staff.</li>
            <li>Disable an employee's account when they leave.</li>
            <li>Check the selected date before reviewing or deleting a sale.</li>
            <li>
              Use <code class="rounded bg-zinc-100 px-1.5 py-0.5">mix ecto.reset</code>
              only when you intend to erase and recreate the database.
            </li>
          </ul>
        </.guide_section>
      </div>
    </div>
    """
  end

  defp sections do
    [
      {"start", "Start a new day"},
      {"staff", "Manage staff"},
      {"sales", "Record a sale"},
      {"review", "Review activity"},
      {"corrections", "Correct a sale"},
      {"products", "Products and stock"},
      {"security", "Safety checklist"}
    ]
  end

  attr :id, :string, required: true
  attr :title, :string, required: true
  slot :inner_block, required: true

  defp guide_section(assigns) do
    ~H"""
    <section id={@id} class="card scroll-mt-20 p-6">
      <h2 class="brand-title text-xl">{@title}</h2>
      <div class="mt-4 text-sm leading-6 text-zinc-700">{render_slot(@inner_block)}</div>
    </section>
    """
  end
end
