defmodule ExpenseTrackerWeb.ExpenseLive.ReceiptUploadComponent do
  use ExpenseTrackerWeb, :live_component

  alias ExpenseTracker.{Expenses, Workers.ProcessReceiptWorker}

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Upload Receipt
        <:subtitle>Upload a receipt image to automatically extract expense information.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="receipt-upload-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="col-span-full">
          <label class="block text-sm font-medium leading-6 text-gray-900">
            Receipt Image
          </label>
          <div class="mt-2 flex justify-center rounded-lg border border-dashed border-gray-900/25 px-6 py-10">
            <div class="text-center">
              <.live_file_input upload={@uploads.receipt} class="sr-only" />
              <svg class="mx-auto h-12 w-12 text-gray-300" viewBox="0 0 24 24" fill="currentColor">
                <path
                  fill-rule="evenodd"
                  d="M1.5 6a2.25 2.25 0 012.25-2.25h13.5A2.25 2.25 0 0119.5 6v12a2.25 2.25 0 01-2.25 2.25H3.75A2.25 2.25 0 011.5 18V6zM3 16.06V18c0 .414.336.75.75.75h16.5A.75.75 0 0021 18v-1.94l-2.69-2.689a1.5 1.5 0 00-2.12 0l-.88.879.97.97a.75.75 0 11-1.06 1.06l-5.16-5.159a1.5 1.5 0 00-2.12 0L3 16.061zm10.125-7.81a1.125 1.125 0 112.25 0 1.125 1.125 0 01-2.25 0z"
                  clip-rule="evenodd"
                />
              </svg>
              <div class="mt-4 flex text-sm leading-6 text-gray-600">
                <label
                  for={@uploads.receipt.ref}
                  class="relative cursor-pointer rounded-md bg-white font-semibold text-indigo-600 focus-within:outline-none focus-within:ring-2 focus-within:ring-indigo-600 focus-within:ring-offset-2 hover:text-indigo-500"
                >
                  <span>Upload a file</span>
                </label>
                <p class="pl-1">or drag and drop</p>
              </div>
              <p class="text-xs leading-5 text-gray-600">PNG, JPG, GIF, PDF up to 10MB</p>
              <p class="text-xs leading-5 text-blue-600 mt-1">
                Supports receipts, invoices, and MPESA statements
              </p>
            </div>
          </div>

          <%= for entry <- @uploads.receipt.entries do %>
            <div class="mt-4">
              <div class="flex items-center justify-between">
                <div class="flex items-center">
                  <svg class="h-5 w-5 text-gray-400" viewBox="0 0 20 20" fill="currentColor">
                    <path
                      fill-rule="evenodd"
                      d="M15.621 4.379a3 3 0 00-4.242 0l-7 7a3 3 0 004.241 4.243h.001l.497-.5a.75.75 0 011.064 1.057l-.498.501-.002.002a4.5 4.5 0 01-6.364-6.364l7-7a4.5 4.5 0 016.368 6.36l-3.455 3.553A2.625 2.625 0 119.52 9.52l3.45-3.451a.75.75 0 111.061 1.06l-3.45 3.451a1.125 1.125 0 001.587 1.595l3.454-3.553a3 3 0 000-4.242z"
                      clip-rule="evenodd"
                    />
                  </svg>
                  <span class="ml-2 text-sm text-gray-600">{entry.client_name}</span>
                </div>
                <button
                  type="button"
                  phx-click="cancel-upload"
                  phx-value-ref={entry.ref}
                  phx-target={@myself}
                  class="text-red-600 hover:text-red-500"
                >
                  <svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                    <path d="M6.28 5.22a.75.75 0 00-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 101.06 1.06L10 11.06l3.72 3.72a.75.75 0 101.06-1.06L11.06 10l3.72-3.72a.75.75 0 00-1.06-1.06L10 8.94 6.28 5.22z" />
                  </svg>
                </button>
              </div>

              <div class="mt-1 flex items-center">
                <div class="flex-1 bg-gray-200 rounded-full h-2">
                  <div class="bg-blue-600 h-2 rounded-full" style={"width: #{entry.progress}%"}></div>
                </div>
                <span class="ml-2 text-xs text-gray-500">{entry.progress}%</span>
              </div>

              <%= for err <- upload_errors(@uploads.receipt, entry) do %>
                <p class="mt-2 text-sm text-red-600">{error_to_string(err)}</p>
              <% end %>
            </div>
          <% end %>

          <%= for err <- upload_errors(@uploads.receipt) do %>
            <p class="mt-2 text-sm text-red-600">{error_to_string(err)}</p>
          <% end %>
        </div>

        <:actions>
          <.button phx-disable-with="Processing..." disabled={@uploads.receipt.entries == []}>
            Process Receipt
          </.button>
          <.button
            type="button"
            phx-click="cancel"
            phx-target={@myself}
            class="bg-gray-500 hover:bg-gray-600"
          >
            Cancel
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{action: :upload_receipt} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, to_form(%{}, as: :receipt))
     |> allow_upload(:receipt,
       accept: ~w(.jpg .jpeg .png .gif .pdf),
       max_entries: 1,
       # 10MB
       max_file_size: 10_000_000,
       auto_upload: true,
       progress: &handle_progress/3
     )}
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :receipt, ref)}
  end

  def handle_event("cancel", _params, socket) do
    notify_parent(:cancel)
    {:noreply, socket}
  end

  def handle_event("save", _params, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :receipt, fn %{path: path}, entry ->
        dest =
          Path.join([
            "priv",
            "static",
            "uploads",
            "receipts",
            "#{entry.uuid}.#{get_file_extension(entry.client_name)}"
          ])

        # Ensure the directory exists
        dest |> Path.dirname() |> File.mkdir_p!()

        # Copy the file
        File.cp!(path, dest)

        {:ok,
         %{
           filename: "#{entry.uuid}.#{get_file_extension(entry.client_name)}",
           original_name: entry.client_name,
           path: dest
         }}
      end)

    case uploaded_files do
      [file_info] ->
        # Create receipt record and start background job
        case create_receipt_and_process(file_info) do
          {:ok, receipt} ->
            notify_parent({:receipt_uploaded, receipt})

            {:noreply,
             socket
             |> put_flash(:info, "Receipt uploaded successfully! Processing in background...")
             |> assign(:form, to_form(%{}, as: :receipt))}

          {:error, reason} ->
            {:noreply,
             socket
             |> put_flash(:error, "Failed to process receipt: #{inspect(reason)}")}
        end

      [] ->
        {:noreply,
         socket
         |> put_flash(:error, "Please select a file to upload")}

      _multiple ->
        {:noreply,
         socket
         |> put_flash(:error, "Please upload only one file at a time")}
    end
  end

  defp handle_progress(:receipt, entry, socket) do
    if entry.done? do
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  defp create_receipt_and_process(file_info) do
    receipt_attrs = %{
      filename: file_info.filename,
      processing_status: "pending"
    }

    with {:ok, receipt} <- Expenses.create_receipt(receipt_attrs),
         {:ok, _job} <- Oban.insert(ProcessReceiptWorker.new(%{receipt_id: receipt.id})) do
      {:ok, receipt}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp get_file_extension(filename) do
    filename
    |> Path.extname()
    |> String.trim_leading(".")
    |> String.downcase()
  end

  defp error_to_string(:too_large), do: "File is too large (max 10MB)"

  defp error_to_string(:not_accepted),
    do: "File type not accepted (only JPG, PNG, GIF, PDF allowed)"

  defp error_to_string(:too_many_files), do: "Too many files (max 1)"
  defp error_to_string(err), do: "Upload error: #{inspect(err)}"

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
