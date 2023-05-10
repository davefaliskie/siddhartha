module PdfToPagesEmbeddings
  require 'csv'

  COMPLETIONS_MODEL = 'text-davinci-003'
  MODEL_NAME = 'curie' #if changed, update EMBEDDING_DIMENSIONS
  EMBEDDING_DIMENSIONS = 4096 #directly related to the MODEL_NAME
  DOC_EMBEDDINGS_MODEL = "text-search-#{MODEL_NAME}-doc-001"

  # Given a string input, this returns the estimated tokens as an int
  # Use Estimate: 1 token ~= 4 characters https://help.openai.com/en/articles/4936856-what-are-tokens-and-how-to-count-them
  # Adding 5% buffer to be safe.
  def count_tokens(input)
    buffer = 0.05
    token_estimate = (input.to_s.length / 4)
    return (token_estimate + (token_estimate * buffer)).round
  end


  # Returns a 2d array with each page in filename formatted as a row
  # [title, page content string, token count]
  def extract_pages(filename)
    csv_rows = []
    reader = PDF::Reader.new("./#{filename}")

    reader.pages.each_with_index do |page, index|
      title = "Page #{index + 1}"
      content = page.text.squish
      tokens = count_tokens(page.text)

      # Only include rows where tokens is less than 2046
      if tokens < 2046
        csv_rows << [title, content, tokens]
      end
    end

    return csv_rows
  end

  # Takes the pdf and generates a csv with cols [title, content, tokens]. Where each row is a page from the pdf
  def make_pages_csv(filename)
    csv_rows = extract_pages(filename)
    csv_rows.insert(0, ["title", "content", "tokens"])

    csv_file = CSV.generate(headers: true) do |csv|
      csv_rows.each {|row| csv << row}
    end

    # write to file
    path = Rails.root + "./#{filename}.pages.csv"
    File.open(path, 'w') { |f| f.write(csv_file) }
  end

  # returns an array of length EMBEDDING_DIMENSIONS for the embeddings for the given input
  def get_embedding(input)
    result = OpenAI::Client.new.embeddings(
      parameters: {
        model: DOC_EMBEDDINGS_MODEL,
        input: input
      }
    )
    return result.dig("data", 0, "embedding")
  end

  # Generates a csv with a row for each page in the pdf (filename) 
  # cols will be the page text embeddings.
  def make_embeddings_csv(filename)  
    csv_rows = [["title"] + (0..EMBEDDING_DIMENSIONS).to_a]

    # pull only the text from the pages.csv data (2nd col)
    inputs = extract_pages(filename).map{ |page| page[1] }

    # get embeddings for each page
    inputs.each_with_index do |input, index|
      csv_rows << ["Page #{index + 1}"] + get_embedding(input)
    end

    csv_file = CSV.generate(headers: true) do |csv|
      csv_rows.each {|row| csv << row}
    end

    # write to file
    path = Rails.root + "./#{filename}.embeddings.csv"
    File.open(path, 'w') { |f| f.write(csv_file) }
  end

end
