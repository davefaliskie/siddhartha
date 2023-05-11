## Setup

1. Create and fill in `config/local_env.yml` using `config/local_env_example.yml` as an example.

   _Note: Using local_env.yml instead of credentials for ease of testing_

2. run `bundle install` to install required dependencies

3. Turn your PDF into embeddings for GPT-3

   Add your PDF (book.pdf) to the project root directory and run the following in `rails console`

   ```
   EmbeddingsFunctions.new("book.pdf").make_csvs
   ```

_Note: A few initial commits were lost for the setup & functions to convert the PDF to CSV. This is because I regenerated the project with Rails 7._
