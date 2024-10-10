class CsvUploader < ApplicationRecord
  belongs_to :campaign
  has_one_attached :csv_file
end
