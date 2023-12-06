defmodule Kanta.POWriter.Plugin.DashboardLive do
  @moduledoc """
  Phoenix LiveComponent for Kanta dashboard
  """

  use Phoenix.LiveView

  alias Kanta.POWriter.Extractor
  alias Kanta.Translations

  require Logger

  @impl true
  def render(assigns) do
    ~H"""
      <div class="col-span-2">

        <div class="bg-white dark:bg-stone-900 overflow-hidden shadow rounded-lg">
          <div class="flex flex-col items-center justify-center px-4 py-5 sm:p-6">
            <div class="text-3xl font-bold text-primary dark:text-accent-light">PO file extraction</div>
            <form phx-submit="extract">
              <select name="locale">
                <option :for={locale <- @locales} value={locale.iso639_code}><%= locale.name %></option>
              </select>
              <select name="domain">
                <option :for={domain <- @domains} value={domain.name}><%= domain.name %></option>
              </select>
              <button class="bg-white" :if={@status == :default}>Extract</button>
              <button class="bg-white" disabled :if={@status == :extracting}>Extracting...</button>
              <a class="bg-white" href={@output_url} target="_blank" :if={@status == :extracted}>Download</a>
            </form>
          </div>
        </div>
      </div>
    """
  end

  @impl true
  def mount(_params, _mapping, socket) do
    socket =
      socket
      |> assign(:status, :default)
      |> assign(:output_url, nil)
      # TODO: deal with pagination
      |> assign(:domains, Translations.list_domains().entries)
      |> assign(:locales, Translations.list_locales().entries)

    {:ok, socket}
  end

  @impl true
  def handle_event("extract", %{"domain" => domain, "locale" => locale}, socket) do
    domain_id =
      (socket.assigns.domains |> Enum.filter(fn d -> d.name == domain end) |> List.first()).id

    path = Extractor.po_file_path(domain, locale)
    output_path = "priv/static/kanta_po_writer/#{locale}/#{domain}.po"
    output_url = "/kanta_po_writer/#{locale}/#{domain}.po"

    Task.async(fn ->
      path
      |> Extractor.parse_po_file()
      |> Extractor.translate_messages(domain_id, locale)
      |> Extractor.write_messages(output_path)
      |> case do
        {:ok, _} -> {:extracted, {:ok, output_url}}
        other -> {:extracted, other}
      end
    end)

    socket = assign(socket, :status, :extracting)

    {:noreply, socket}
  end

  @impl true
  def handle_info({ref, {:extracted, {:ok, output_url}}}, socket) when is_reference(ref) and is_binary(output_url) do
    socket =
      socket
      |> assign(:status, :extracted)
      |> assign(:output_url, output_url)

    {:noreply, socket}
  end

  def handle_info({ref, {:extracted, invalid_result}}, socket) when is_reference(ref) do
    Logger.error(inspect(invalid_result))
    {:noreply, put_flash(socket, :error, "Extracting failed!")}
  end

  def handle_info({:DOWN, ref, :process, pid, :normal}, socket) when is_reference(ref) and is_pid(pid) do
    {:noreply, socket}
  end
end
