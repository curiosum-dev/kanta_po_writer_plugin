defmodule Kanta.POWriter.Plugin.DashboardComponent do
  @moduledoc """
  Phoenix LiveComponent for Kanta dashboard
  """

  use Phoenix.LiveComponent

  alias Kanta.POWriter.Extractor
  alias Kanta.Translations

  require Logger

  def render(assigns) do
    ~H"""
      <div class="col-span-2">
        <div class="bg-white dark:bg-stone-900 overflow-hidden shadow rounded-lg">
          <div class="flex flex-col items-center justify-center px-4 py-5 sm:p-6">
            <div class="text-3xl font-bold text-primary dark:text-accent-light">PO file extraction</div>
            <form phx-submit="extract" phx-target={@myself}>
              <select name="locale">
                <option :for={locale <- @locales} value={locale.iso639_code}><%= locale.name %></option>
              </select>
              <select name="domain">
                <option :for={domain <- @domains} value={domain.name}><%= domain.name %></option>
              </select>
              <button class="bg-white">Extract</button>
            </form>
          </div>
        </div>
      </div>
    """
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      # TODO: deal with pagination
      |> assign(:domains, Translations.list_domains().entries)
      |> assign(:locales, Translations.list_locales().entries)

    {:ok, socket}
  end

  def handle_event("extract", %{"domain" => domain, "locale" => locale}, socket) do
    domain_id =
      (socket.assigns.domains |> Enum.filter(fn d -> d.name == domain end) |> List.first()).id

    path = Extractor.po_file_path(domain, locale)

    path
    |> Extractor.parse_po_file()
    |> Extractor.translate_messages(domain_id, locale)
    |> Extractor.write_messages(path)

    {:noreply, socket}
  end
end
