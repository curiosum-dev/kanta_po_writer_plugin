defmodule Kanta.POWriter.Plugin.DashboardLive do
  @moduledoc """
  Phoenix LiveComponent for Kanta dashboard
  """

  use Phoenix.LiveView, container: {:div, style: "grid-column: 1 / -1;"}

  alias Kanta.POWriter.Extractor
  alias Kanta.Translations

  require Logger

  @impl true
  def render(assigns) do
    ~H"""
     <div class="bg-white dark:bg-stone-900 overflow-hidden shadow rounded-lg">
      <div class="bg-white dark:bg-stone-900 px-4 py-5 border-b border-slate-200 sm:px-6">
        <h3 class="text-lg leading-6 font-medium text-primary-dark dark:text-accent-light">
          PO Writer
        </h3>
      </div>
      <div class="px-4 py-5 sm:p-6">
        <form phx-submit="extract" class="flex flex-col space-y-4">
          <select name="locale" phx-change="set-default-state">
            <option :for={locale <- @locales} value={locale.iso639_code}><%= locale.name %></option>
          </select>
          <select name="domain" phx-change="set-default-state">
            <option :for={domain <- @domains} value={domain.name}><%= domain.name %></option>
          </select>
          <button class="
          bg-white dark:bg-base-dark transition-all hover:bg-slate-100 dark:hover:bg-stone-800 border-slate-300 dark:border-accent-dark 
          shadow-md text-primary-dark dark:text-accent-dark group flex items-center px-2 py-2 text-sm font-semibold rounded-md
          " 
          :if={@status == :default} disabled={@status == :extracting}>
             <span :if={@status != :extracting}>Extract</span>
             <span :if={@status == :extracting} class="text-gray-500 font-bold">Extracting...</span>
          </button>
        </form>
      </div>
      <div class="bg-white dark:bg-stone-900 px-4 py-5 border-b border-slate-200 sm:px-6" :if={@extracted != []}>
        <h3 class="text-lg leading-6 font-medium text-primary-dark dark:text-accent-light">
          Extracted
        </h3>
      </div>
      <div class="px-4 py-5 sm:p-6" :if={@extracted != []}>
        <table class="min-w-full w-full divide-y divide-slate-200">
         <thead class="bg-slate-50 dark:bg-stone-900">
                  <tr>
                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-content-light uppercase tracking-wider">
                      Locale
                    </th>
                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-content-light uppercase tracking-wider">
                      Domain
                    </th>
                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-content-light uppercase tracking-wider">
                      Replace
                    </th>
                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-content-light uppercase tracking-wider">
                      Download
                    </th>
                  </tr>
                </thead> 
          <tbody class="bg-white dark:bg-stone-800 divide-y divide-slate-200 dark:divide-accent-dark">
          <tr :for={export <- @extracted}>
                      <td class="px-6 py-4">
                        <div class="text-md font-medium tracking-wide text-primary-dark dark:text-accent-dark"><%= export.locale.name %></div>
                      </td>
                      <td class="px-6 py-4">
                        <div class="text-md font-medium tracking-wide text-primary-dark dark:text-accent-dark"><%= export.domain.name %></div>
                      </td>
                      <td class="px-6 py-4">
                        <div class="text-md font-medium tracking-wide text-primary-dark dark:text-accent-dark">
                          <button phx-click="replace" phx-value-locale-id={export.locale.id} phx-value-domain-id={export.domain.id} class="text-md font-medium tracking-wide text-primary-dark dark:text-accent-dark font-bold uppercase underline">Replace</button>
                        </div>
                      </td>
                      <td class="px-6 py-4">
                        <div class="text-md font-medium tracking-wide text-primary-dark dark:text-accent-dark font-bold uppercase underline"><a href={export.output_url} target="_blank">Download</a></div>
                      </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _mapping, socket) do
    %{entries: domains} = Translations.list_domains()
    %{entries: locales} = Translations.list_locales()

    socket =
      socket
      |> assign(:status, :default)
      # TODO: deal with pagination
      |> assign(:domains, domains)
      |> assign(:locales, locales)
      |> assign(:extracted, [])

    {:ok, socket}
  end

  @impl true
  def handle_event("extract", %{"domain" => domain, "locale" => locale}, socket) do
    domain = Enum.find(socket.assigns.domains, &(&1.name == domain))
    locale = Enum.find(socket.assigns.locales, &(&1.iso639_code == locale))

    path = Extractor.po_file_path(domain.name, locale.iso639_code)
    output_path = "priv/static/kanta_po_writer/#{locale.iso639_code}/#{domain.name}.po"
    output_url = "/kanta_po_writer/#{locale.iso639_code}/#{domain.name}.po"

    Task.async(fn ->
      path
      |> Extractor.parse_po_file()
      |> Extractor.translate_messages(domain.id, locale.iso639_code)
      |> Extractor.write_messages(output_path)
      |> case do
        {:ok, _} -> {:extracted, {:ok, %{output_url: output_url, domain: domain, locale: locale}}}
        other -> {:extracted, other}
      end
    end)

    socket = assign(socket, :status, :extracting)

    {:noreply, socket}
  end

  def handle_event("set-default-state", _params, socket) do
    socket = assign(socket, :status, :default)
    {:noreply, socket}
  end

  def handle_event("replace", %{"domain-id" => domain_id, "locale-id" => locale_id}, socket) do
    domain = Enum.find(socket.assigns.domains, &(to_string(&1.id) == domain_id))
    locale = Enum.find(socket.assigns.locales, &(to_string(&1.id) == locale_id))

    Extractor.replace_with_extracted!(domain, locale)
    socket = put_flash(socket, :info, "Replaced '#{domain.name}.po' for locale '#{locale.name}'")

    {:noreply, socket}
  end

  @impl true
  def handle_info({ref, {:extracted, {:ok, result}}}, socket) when is_reference(ref) do
    extracted = Enum.uniq_by([result | socket.assigns.extracted], fn %{output_url: output_url} -> output_url end)

    socket =
      socket
      |> assign(:status, :default)
      |> assign(:extracted, extracted)

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
