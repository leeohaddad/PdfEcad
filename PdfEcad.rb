require 'pdf-reader'

module Importers
     class Importers::PdfEcad
          CATEGORIES = {"CA" => "Author", "E" => "Publisher", "V" => "Versionist", "SE" => "SubPublisher"}
          
          def initialize(filePath)
               @pdfPath=filePath
          end
          
          def works
               reader = PDF::Reader.new(@pdfPath)
               reader.pages.each do |page|
                    pageLines = page.text.split("\n")
                    # pageLines[0]:  RELATÓRIO ANALÍTICO DE TITULAR AUTORAL E SUAS OBRAS
                    # pageLines[1]: 
                    # pageLines[2]: 
                    # pageLines[3]: 
                    # pageLines[4]: 
                    # pageLines[5]:  ASSOCIAÇÃO: ABRAMUS - ASSOCIACAO BRASILEIRA DE MÚSICA
                    # pageLines[6]:  TITULAR: 4882   CARLOS DE SOUZA   PSEUDÔNIMO: CARLOS CAREQA   CATEGORIA: TODAS
                    # pageLines[7]: 
                    # pageLines[8]: 
                    # pageLines[9]: 
                    # pageLines[10]: CÓD. OBRA   ISWC   TÍTULO PRINCIPAL DA OBRA   SITUAÇÃO*   INCLUSÃO
                    # pageLines[11]: CONTRATO
                    # pageLines[12]: CÓDIGO   NOME DO TITULAR   PSEUDÔNIMO   CAE   ASSOCIAÇÃO CAT (%)   INÍCIO / FIM   LINK
                    # pageLines[13]: 
                    # pageLines[14]: 
                    loop_pivot = 15
                    while loop_pivot < pageLines.count-1 do
                         if pageLines[loop_pivot].strip.length > 0
                              work(pageLines[loop_pivot])
                         end
                         loop_pivot += 1
                    end
                    # pageLines[count-1]: 04/03/2015 - 16:35 *Situação da Obra : LB-LIBERADO / BL-BLOQUEADA / DU-DUPLICIDADE / HO-HOMONIMA / DP-DOMINIO PUBLICO / DE-DERIVADA / COPágina 4A / EC-EM CONFLITO
                    puts ' '
                    puts ' '
               end
          end
          
          def right_holder(line)
               puts "right_holder line:|#{line}|"
          end
          
          def work(line)
               puts "work line:|#{line}|"
          end

     end
end