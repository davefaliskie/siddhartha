# When called with a question query, this will return a Question object that contains the answer.
class Ask < ApplicationService
  include PromptData
  require 'matrix'

  MAX_SECTION_LEN = 500
  SEPARATOR = "\n* ".freeze
  SEPARATOR_LEN = 3

  COMPLETION_TEMP = 0.0
  COMPLETION_MAX_TOKENS = 150
  COMPLETION_MODEL = "text-davinci-003".freeze

  def initialize(query, filename = "siddhartha-full.pdf")
    @query = format_query(query)
    @embeddings_functions = EmbeddingsFunctions.new(filename)
  end

  def call
    # if the query was already asked, return the cached Question
    existing_questions = Question.where(question: @query).first
    if existing_questions.present?
      existing_questions.update(ask_count: existing_questions.ask_count += 1)
      return existing_questions
    end

    # find the answer with openAI
    # first generate an embedding for the query
    @query_embedding = @embeddings_functions.get_embedding(@query)

    # get hash of the pre-generated embeddings, where the page# is the key & the embedding is the value
    @document_embeddings = @embeddings_functions.load_document_embeddings

    # generate the prompt using the embeddings to determine the most relevant book context
    prompt_data = construct_prompt_with_page_text
    @prompt = prompt_data[:prompt]
    @context = prompt_data[:page_text]

    # Make the call to OpenAI
    @answer = answer_query

    # save & return the Question
    Question.create(
      question: @query,
      answer: @answer,
      context: @context,
      ask_count: 1
    )
  end

  private

  # strip extra white space, lowercase all text, add trailing '?'
  def format_query(query)
    q = query.strip.downcase
    q.ends_with?("?") ? q : "#{q}?"
  end

  # returns the dot product of query_embedding & param embedding
  def query_embedding_similarity(embedding)
    @query_embedding.zip(embedding).reduce(0) { |sum, (a, b)| sum + (a * b) }
  end

  # return the document embeddings ordered by relavence (higher dot product between query embeddings)
  def order_document_sections_by_query_similarity
    document_similarities = []

    @document_embeddings.each do |key, value|
      similarity = query_embedding_similarity(value)
      document_similarities.push([similarity, key])
    end

    document_similarities.sort_by { |item| item[0] }.reverse
  end

  # # returns the prompt for completion & chosen page text as hash
  def construct_prompt_with_page_text
    chosen_sections = []
    chosen_sections_len = 0
    chosen_sections_indexes = []

    # Rails.logger.debug {"order_document_sections_by_query_similarity: #{order_document_sections_by_query_similarity}"}

    order_document_sections_by_query_similarity.each do |_, page_index|
      # get the page content by page_index
      section_text, tokens = @embeddings_functions.get_page_content(page_index)

      chosen_sections_len += (tokens + SEPARATOR_LEN)
      if chosen_sections_len > MAX_SECTION_LEN
        space_left = MAX_SECTION_LEN - chosen_sections_len - SEPARATOR.length
        chosen_sections.push("#{SEPARATOR} #{section_text[...space_left]}")
        chosen_sections_indexes.append(page_index.to_s)
        break
      end

      chosen_sections.push(SEPARATOR + section_text)
      chosen_sections_indexes.push(page_index.to_s)
    end

    # Rails.logger.debug { "chosen_sections_indexes: #{chosen_sections_indexes}" }
    chosen_pages_text = chosen_sections.join
    prompt = "#{PROMPT_HEADER} #{chosen_pages_text} #{Q1} #{Q2} #{Q3} #{Q4} #{Q5} \n\n\nQ: #{@query} \n\nA: "

    { prompt: prompt, page_text: chosen_pages_text }
  end

  # return the query answer
  def answer_query
    response = OpenAI::Client.new.completions(
      parameters: {
        prompt: @prompt,
        temperature: COMPLETION_TEMP,
        max_tokens: COMPLETION_MAX_TOKENS,
        model: COMPLETION_MODEL
      }
    )

    # Rails.logger.debug { "response: #{response}" }
    response["choices"].first["text"].delete("\n").strip
  end
end
