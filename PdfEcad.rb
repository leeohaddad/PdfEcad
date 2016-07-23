require 'pdf-reader'

module Importers
     class Importers::PdfEcad
          CATEGORIES = {"CA" => "Author", "E" => "Publisher", "V" => "Versionist", "SE" => "SubPublisher"}
          
          def initialize(filePath)
               @pdfPath=filePath
          end
          
          def works
               puts "works"
          end
          
          def right_holder(line)
               puts "right_holder line:|#{line}|"
          end
          
          def work(line)
               puts "work line:|#{line}|"
          end

     end
end
