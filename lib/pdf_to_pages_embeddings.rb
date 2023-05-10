class PdfToPagesEmbeddings
  require 'csv'

  COMPLETIONS_MODEL = 'text-davinci-003'.freeze
  MODEL_NAME = 'curie'.freeze # if changed, update EMBEDDING_DIMENSIONS
  EMBEDDING_DIMENSIONS = 4096 # directly related to the MODEL_NAME
  DOC_EMBEDDINGS_MODEL = "text-search-#{MODEL_NAME}-doc-001".freeze

  def initialize(filename)
    # run the process to generate the two CSV files,
    #  - one with the pages & their token count
    #  - one with the pages embeddings
    @filename = filename
    @pages_data = extract_pages
    make_pages_csv
    make_embeddings_csv
  end

  private

  # Given a string input, this returns the estimated tokens as an int
  # Use Estimate: 1 token ~= 4 characters https://help.openai.com/en/articles/4936856-what-are-tokens-and-how-to-count-them
  # Adding 5% buffer to be safe.
  def count_tokens(input)
    buffer = 0.05
    token_estimate = (input.to_s.length / 4)
    (token_estimate + (token_estimate * buffer)).round
  end

  # Returns a 2d array with each page in filename formatted as a row
  # [title, page content string, token count]
  def extract_pages
    csv_rows = []
    reader = PDF::Reader.new("./#{@filename}")

    reader.pages.each_with_index do |page, index|
      title = "Page #{index + 1}"
      content = page.text.squish
      tokens = count_tokens(page.text)

      # Only include rows where tokens is less than 2046
      csv_rows << [title, content, tokens] if tokens < 2046
    end

    csv_rows
  end

  # Takes the pdf and generates a csv with cols [title, content, tokens]. Where each row is a page from the pdf
  def make_pages_csv
    csv_rows = @pages_data.clone
    csv_rows.insert(0, %w[title content tokens])

    csv_file = CSV.generate(headers: true) do |csv|
      csv_rows.each { |row| csv << row }
    end

    # write to file
    path = Rails.root + "./#{@filename}.pages.csv"
    File.write(path, csv_file)
  end

  # returns an array of length EMBEDDING_DIMENSIONS for the embeddings for the given input
  def get_embedding(text)
    result = OpenAI::Client.new.embeddings(
      parameters: {
        model: DOC_EMBEDDINGS_MODEL,
        input: text
      }
    )
    result.dig("data", 0, "embedding")
  end

  # Generates a csv with a row for each page in the pdf (filename)
  # cols will be the page text embeddings.
  def make_embeddings_csv
    csv_rows = [["title"] + (0..EMBEDDING_DIMENSIONS).to_a]

    # get embeddings for each page. data[0] is the title, data[1] is the page string content
    @pages_data.each do |data|
      csv_rows << ([data[0].to_s] + get_embedding(data[1]))
    end

    csv_file = CSV.generate(headers: true) do |csv|
      csv_rows.each { |row| csv << row }
    end

    # write to file
    path = Rails.root + "./#{@filename}.embeddings.csv"
    File.write(path, csv_file)
  end
end
