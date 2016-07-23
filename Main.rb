require 'rails'
require_relative 'PdfEcad'

filePath = "#{Rails.root}/spec/lib/importers/careqa.pdf"
filePath = "#{File.expand_path(File.dirname(File.dirname(__FILE__)))}/careqa.pdf"
instance = Importers::PdfEcad.new(filePath)
instance.works