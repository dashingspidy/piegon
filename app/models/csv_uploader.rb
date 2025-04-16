class CsvUploader < ApplicationRecord
  belongs_to :contact
  has_one_attached :csv_file
end
