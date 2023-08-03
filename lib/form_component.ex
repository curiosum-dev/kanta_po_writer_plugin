defmodule Kanta.POWriter.Plugin.FormComponent do
  @moduledoc """
  Phoenix LiveComponent for Kanta translation form
  """

  use Phoenix.LiveComponent

  def render(assigns) do
    ~H'<span>Hi from POWriter</span>'
  end

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    {:ok, socket}
  end
end
