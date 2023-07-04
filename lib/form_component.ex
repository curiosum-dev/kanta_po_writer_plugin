defmodule Kanta.POWriter.Plugin.FormComponent do
  @moduledoc """
  Phoenix LiveComponent for Kanta translation form
  """

  use Phoenix.LiveComponent

  alias Kanta.Translations
  alias Kanta.Translations.Message

  alias Kanta.Translations.Locale.Finders.ListLocalesWithTranslatedMessage

  alias Kanta.Translations.SingularTranslations.Finders.GetSingularTranslation
  alias Kanta.Translations.PluralTranslations.Finders.GetPluralTranslation

  def render(assigns) do
    ~H'<span>Hi from POWriter</span>'
  end

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    {:ok, socket}
  end
end
