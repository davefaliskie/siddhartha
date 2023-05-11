class CreateQuestions < ActiveRecord::Migration[7.0]
  def change
    create_table :questions do |t|
      t.string :question
      t.text :context
      t.text :answer
      t.integer :ask_count
      t.string :audio_src_url
      t.timestamps
    end
  end
end
