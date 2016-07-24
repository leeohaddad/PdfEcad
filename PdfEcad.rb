require 'pdf-reader'

module Importers
     class Importers::PdfEcad
          CATEGORIES = {"CA" => "Author", "E" => "Publisher", "V" => "Versionist", "SE" => "SubPublisher"}
          
          def initialize(filePath)
               @pdfPath=filePath
          end
          
          def works
               $counter = 0
               hashes = []
               reader = PDF::Reader.new(@pdfPath)
               state = 0 # "Seeking work"
               workLine = ""
               # iterate over pages
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
                    # iterate over lines of each page
                    while loop_pivot < pageLines.length-1 do
                         # catch only valid lines
                         if pageLines[loop_pivot].length > 0 && numeric?(pageLines[loop_pivot][0]) != nil then
                              if (state == 0) then # new work
                                   workLine = pageLines[loop_pivot]
                                   loop_pivot += 1
                                   state = 1 # "Adding right holders"
                              else
                                   if (pageLines[loop_pivot][pageLines[loop_pivot].length-5] == '/') then # last work finished at end of page
                                        state = 2 # "Preparing to call work()"
                                        hashes.push(work(workLine))
                                        state = 0 # "Seeking work"
                                   else # the work is present/described in both pages
                                        workLine += pageLines[loop_pivot]
                                        loop_pivot += 1
                                        state = 1 # "Adding right holders"
                                   end
                              end
                              while state == 1 do # keep registering right holders
                                   while (pageLines[loop_pivot].length == 0) do # skip empty lines
                                        loop_pivot += 1
                                   end
                                   if numeric?(pageLines[loop_pivot][0]) != nil && numeric?(pageLines[loop_pivot][pageLines[loop_pivot].length-1]) != nil && pageLines[loop_pivot][pageLines[loop_pivot].length-5]!='/' then
                                        # register a right holder
                                        workLine += ' | ' + pageLines[loop_pivot]
                                        if pageLines[loop_pivot].length < 8 then # fix for specific error
                                             loop_pivot += 1
                                             workLine += pageLines[loop_pivot]
                                        end
                                        loop_pivot += 1
                                   else
                                        if (loop_pivot < pageLines.length-1)
                                             state = 2 # "Preparing to call work()"
                                             hashes.push(work(workLine))
                                             state = 0 # "Seeking work"
                                        else
                                             state = 3 # "Work transcending pages"
                                             workLine += ' | '
                                        end
                                   end
                              end
                         else
                              loop_pivot += 1
                         end
                    end
                    # pageLines[count-1]: 04/03/2015 - 16:35 *Situação da Obra : LB-LIBERADO / BL-BLOQUEADA / DU-DUPLICIDADE / HO-HOMONIMA / DP-DOMINIO PUBLICO / DE-DERIVADA / COPágina 4A / EC-EM CONFLITO
               end
               puts "total: #{$counter}"
          end
          
          def right_holder(line)
               puts "right_holder line:|#{line}|"
          end
          
          def work(line)
               $counter += 1
               components = line.split(' | ')
               # step 1: parse informations about the work
               workDs = components[0]
               informations = workDs.split('   ')
               workHash = Hash.new
               index = 0
               # get external_id
               while informations[index].length == 0 do
                    index += 1
               end
               external_ids = []
               external_id = Hash.new
               external_id["source_name"] = "Ecad"
               external_id["source_id"] = informations[index].strip
               external_ids.push(external_id)
               workHash["external_ids"] = external_ids
               index += 1
               # get iswc
               while informations[index].length == 0 do
                    index += 1
               end
               workHash["iswc"] = informations[index].strip
               index += 1
               while informations[index].length == 0 do
                    index += 1
               end
               # if there is no iswc for this work, iswc is "- . . -"
               while  informations[index] == '.' || informations[index] == '-' do
                    workHash["iswc"] += ' ' + informations[index].strip
                    index += 1
               end
               # get title
               while informations[index].length == 0 do
                    index += 1
               end
               workHash["title"] = informations[index].strip
               # get situation
               index += 1
               while informations[index].length == 0 do
                    index += 1
               end
               workHash["situation"] = informations[index].strip
               index += 1
               # get created_at
               while informations[index].length == 0 do
                    index += 1
               end
               workHash["created_at"] = informations[index].strip
          end

          def numeric?(lookAhead)
               lookAhead =~ /[[:digit:]]/
          end

     end
end