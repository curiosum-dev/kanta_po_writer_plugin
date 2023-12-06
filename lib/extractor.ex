defmodule Kanta.POWriter.Extractor do
  @moduledoc false

  use Gradient.TypeAnnotation

  alias Kanta.Translations

  @default_priv "priv/gettext"

  @type error() :: atom() | binary()
  @type result(value) :: {:ok, value} | {:error, error()}
  @type result_or_value(value) :: result(value) | value
  @type domain() :: binary()
  @type domain_id() :: integer()
  @type locale() :: binary()
  @type domain_tuple() :: {domain(), domain_id()}

  @spec translate_messages(message :: result_or_value(Expo.Messages.t()), domain_id :: domain_id(), locale :: locale()) ::
          result(Expo.Messages.t())
  def translate_messages({:ok, messages}, domain_id, locale), do: translate_messages(messages, domain_id, locale)

  def translate_messages(%Expo.Messages{} = messages, domain_id, locale) do
    new_messages =
      messages.messages
      |> Stream.map(&translate_message(&1, domain_id, locale))
      |> Stream.filter(fn
        {:ok, _} -> true
        _ -> false
      end)
      |> Stream.map(&unwrap!/1)
      |> Enum.to_list()

    messages =
      assert_type(
        %Expo.Messages{messages | messages: new_messages},
        Expo.Messages.t()
      )

    {:ok, messages}
  end

  def translate_messages(rest, _, _), do: rest

  @spec translate_message(
          message :: Expo.Message.Singular.t() | Expo.Message.Plural.t(),
          domain_id :: domain_id(),
          locale :: locale()
        ) :: result(Expo.Message.Singular.t() | Expo.Message.Plural.t())
  def translate_message(%Expo.Message.Singular{} = msg, domain_id, locale) do
    # not sure why expo has ["my_message_id"] instead of "my_message_id"
    # maybe find for each msgid ???
    # how to resolve conflicts then ???
    msgid = List.first(msg.msgid)

    with {:ok, kanta_msg} <-
           Translations.get_message(
             filter: [msgid: msgid, domain_id: domain_id],
             preloads: [singular_translations: :locale]
           ) do
      translations = kanta_msg.singular_translations

      new_msgstr =
        translations
        |> Enum.filter(fn translation -> translation.locale.iso639_code == locale end)
        |> Enum.map(&(&1.translated_text || &1.original_text || ""))

      msg =
        assert_type(
          %Expo.Message.Singular{msg | msgstr: new_msgstr},
          Expo.Message.Singular.t()
        )

      {:ok, msg}
    end
  end

  # TODO: Plural messages
  def translate_message(%Expo.Message.Plural{} = msg, _, _), do: {:ok, msg}

  @spec write_messages(messages :: result_or_value(Expo.Messages.t()), path :: result_or_value(binary())) ::
          result(Expo.Messages.t())
  def write_messages({:ok, msgs}, path), do: write_messages(msgs, path)
  def write_messages(msgs, {:ok, path}), do: write_messages(msgs, path)

  def write_messages(%Expo.Messages{} = msgs, path) do
    iodata = Expo.PO.compose(msgs)
    dir = Path.dirname(path)

    File.mkdir_p!(dir)

    with :ok <- File.write!(path, iodata) do
      {:ok, msgs}
    end
  end

  def write_messages(rest, _), do: rest

  @spec po_file_path(domain :: domain(), locale :: locale()) :: result(binary())
  def po_file_path(domain, locale) do
    priv = Application.get_env(:kanta, :priv, @default_priv)
    path = Path.join(priv, "#{locale}/LC_MESSAGES/#{domain}.po")

    if File.exists?(path) do
      {:ok, path}
    else
      {:error, "Path #{inspect(path)} doesn't exist"}
    end
  end

  def parse_po_file({:ok, path}), do: Expo.PO.parse_file(path)
  def parse_po_file(rest), do: rest

  @spec unwrap!(result(any())) :: any()
  defp unwrap!({:ok, thing}), do: thing
  defp unwrap!({:error, msg}), do: raise(inspect(msg))
end
