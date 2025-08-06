defmodule ExpenseTracker.OpenAI.ReceiptProcessor do
  @moduledoc """
  AI service for processing receipt images and extracting expense information.
  Uses OpenAI GPT-4 Vision API for text extraction and categorization.
  """

  require Logger

  @openai_api_url "https://api.openai.com/v1/chat/completions"
  @confidence_threshold 0.7

  def process_receipt(image_path) do
    # Temporary mock response for testing - matches actual OpenAI API response format
    # mock_response = %{
    #   "choices" => [
    #     %{
    #       "message" => %{
    #         "content" => "{\"type\":\"single\",\"amount\":35.50,\"description\":\"Shopping at Carrefour\",\"merchant\":\"Carrefour\",\"category\":\"Food & Dining\",\"date\":\"2025-08-06\",\"confidence\":0.92}"
    #       }
    #     }
    #   ]
    # }

    # parse_ai_response(mock_response)
    with {:ok, image_base64} <- encode_image(image_path),
         {:ok, response} <- call_openai_api(image_base64),
         {:ok, parsed_data} <- parse_ai_response(response) do
      {:ok, parsed_data}
    else
      {:error, reason} ->
        Logger.error("Receipt processing failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp encode_image(image_path) do
    case File.read(image_path) do
      {:ok, image_data} ->
        base64_image = Base.encode64(image_data)
        {:ok, base64_image}

      {:error, reason} ->
        {:error, "Failed to read image: #{reason}"}
    end
  end

  defp call_openai_api(image_base64) do
    api_key = get_openai_api_key()

    if is_nil(api_key) or api_key == "" do
      {:error, "OpenAI API key not configured"}
    else
      headers = [
        {"Authorization", "Bearer #{api_key}"},
        {"Content-Type", "application/json"}
      ]

      body = %{
        "model" => "gpt-4o-mini",
        "messages" => [
          %{
            "role" => "user",
            "content" => [
              %{
                "type" => "text",
                "text" => get_prompt()
              },
              %{
                "type" => "image_url",
                "image_url" => %{
                  "url" => "data:image/jpeg;base64,#{image_base64}"
                }
              }
            ]
          }
        ],
        "max_tokens" => 1500,
        "temperature" => 0.1
      }

      case Req.post(@openai_api_url, headers: headers, json: body) do
        {:ok, %{status: 200, body: response_body}} ->
          {:ok, response_body}

        {:ok, %{status: status, body: body}} ->
          {:error, "API request failed with status #{status}: #{inspect(body)}"}

        {:error, reason} ->
          {:error, "HTTP request failed: #{inspect(reason)}"}
      end
    end
  end

  defp get_prompt do
    """
    Analyze this financial document (receipt, invoice, or MPESA statement) and extract expense information.

    For single transactions (receipts/invoices), respond with:
    {
      "type": "single",
      "amount": 25.99,
      "description": "Lunch at McDonald's",
      "merchant": "McDonald's",
      "category": "Food & Dining",
      "date": "2024-08-06",
      "confidence": 0.95
    }

    For MPESA statements with multiple transactions, respond with:
    {
      "type": "multiple",
      "transactions": [
        {
          "amount": 500.00,
          "description": "Payment to SuperMarket",
          "merchant": "SuperMarket",
          "category": "Food & Dining",
          "date": "2024-08-06",
          "confidence": 0.90,
          "transaction_type": "outgoing"
        },
        {
          "amount": 200.00,
          "description": "Payment to Matatu",
          "merchant": "Matatu",
          "category": "Transportation",
          "date": "2024-08-06",
          "confidence": 0.85,
          "transaction_type": "outgoing"
        }
      ]
    }

    Rules:
    - amount: transaction amount as a number (positive)
    - description: brief description of the transaction
    - merchant: recipient/business name
    - category: one of "Food & Dining", "Transportation", "Entertainment", "Shopping", "Healthcare", "Utilities", "Travel", "Other"
    - date: transaction date in YYYY-MM-DD format, or null if unclear
    - confidence: your confidence level (0.0 to 1.0) in accuracy
    - transaction_type: "outgoing" for expenses, "incoming" for money received (ignore incoming for expense tracking)
    - Only include outgoing transactions (expenses) in the response
    - For MPESA: Look for "Paid to", "Buy Goods", "Paybill" transactions
    - Ignore balance inquiries, deposits, money received

    If document is unclear, set confidence to 0.1 and use "Other" for category.
    """
  end

  defp parse_ai_response(%{"choices" => [%{"message" => %{"content" => content}} | _]}) do
    case Jason.decode(String.trim(content)) do
      {:ok, %{"type" => "single"} = data} ->
        # amount = parse_amount(data["amount"])

        date = parse_date(data["date"])

        confidence = data["confidence"] || 0.1

        needs_review = confidence < @confidence_threshold

        parsed_data = %{
          type: :single,
          amount: data["amount"],
          description: data["description"] || "Unknown expense",
          merchant: data["merchant"] || "Unknown merchant",
          category: data["category"] || "Other",
          date: date,
          confidence: confidence,
          needs_review: needs_review
        }

        {:ok, parsed_data}

      {:ok, %{"type" => "multiple", "transactions" => transactions}} when is_list(transactions) ->
        # Multiple transactions (MPESA statement)
        parsed_transactions =
          transactions
          # Only expenses
          |> Enum.filter(fn t -> t["transaction_type"] == "outgoing" end)
          |> Enum.map(fn transaction ->
            %{
              amount: transaction["amount"],
              # amount: parse_amount(transaction["amount"]),
              description: transaction["description"] || "MPESA Payment",
              merchant: transaction["merchant"] || "Unknown",
              category: transaction["category"] || "Other",
              date: parse_date(transaction["date"]),
              confidence: transaction["confidence"] || 0.1,
              needs_review: (transaction["confidence"] || 0.1) < @confidence_threshold
            }
          end)

        parsed_data = %{
          type: :multiple,
          transactions: parsed_transactions,
          total_transactions: length(parsed_transactions)
        }

        {:ok, parsed_data}

      {:ok, data} ->
        # Fallback for old format (backward compatibility)
        parsed_data = %{
          type: :single,
          amount: data["amount"],
          # amount: parse_amount(data["amount"]),
          description: data["description"] || "Unknown expense",
          merchant: data["merchant"] || "Unknown merchant",
          category: data["category"] || "Other",
          date: parse_date(data["date"]),
          confidence: data["confidence"] || 0.1,
          needs_review: (data["confidence"] || 0.1) < @confidence_threshold
        }

        {:ok, parsed_data}

      {:error, _reason} ->
        {:error, "Failed to parse AI response as JSON"}
    end
  end

  defp parse_ai_response(_), do: {:error, "Unexpected API response format"}

  # defp parse_amount(amount) when is_number(amount) do
  #   result = Decimal.new(amount)
  #   result
  # end
  # defp parse_amount(amount) when is_binary(amount) do
  #   case Decimal.parse(amount) do
  #     {decimal, _} ->
  #       decimal
  #     :error ->
  #       Decimal.new("0.00")
  #   end
  # end
  # defp parse_amount(other) do
  #   Decimal.new("0.00")
  # end

  defp parse_date(nil), do: Date.utc_today()

  defp parse_date(date_string) when is_binary(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> date
      {:error, _} -> Date.utc_today()
    end
  end

  defp parse_date(_), do: Date.utc_today()

  defp get_openai_api_key do
    System.get_env("OPENAI_API_KEY") ||
      Application.get_env(:expense_tracker, :openai_api_key)
  end
end
