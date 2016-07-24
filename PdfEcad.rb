require 'pdf-reader'

module Importers
     class Importers::PdfEcad
          DEFAULT_AUTHOR = "CARLOS DE SOUZA"
          CATEGORIES = {"CA" => "Author", "E" => "Publisher", "V" => "Versionist", "SE" => "SubPublisher"}
          
          def initialize(filePath)
               @pdfPath=filePath
          end
          
          def works
               worksHashes = []
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
                                        worksHashes.push(work(workLine))
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
                                        # fix for specific error: for unknown reason, some right_holders are separated from theis CÓDIGO field
                                        if pageLines[loop_pivot].length < 8 then
                                             loop_pivot += 1
                                             workLine += pageLines[loop_pivot]
                                        end
                                        loop_pivot += 1
                                   else
                                        if (loop_pivot < pageLines.length-1)
                                             state = 2 # "Preparing to call work()"
                                             worksHashes.push(work(workLine))
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
               return worksHashes
          end
          
          def right_holder(line)
               informations = line.split('  ')
               right_holder = Hash.new
               index = 0
               # get external_id
               while informations[index].length == 0 do
                    index += 1
               end
               external_ids = []
               external_id = Hash.new
               external_id[:source_name] = 'Ecad'
               external_id[:source_id] = informations[index].strip
               external_ids.push(external_id)
               right_holder[:external_ids] = external_ids
               index += 1
               # get right_holder name
               while informations[index].length == 0 do
                    index += 1
               end
               right_holder[:name] = informations[index].strip
               index +=1
               # get right_holder pseudo
               pseudos = []
               information_checker = 0
               while informations[index].length == 0 do
                    index += 1
                    information_checker += 1
               end
               # if there is no pseudos, information_checks detects too many empty elements in informations array after right_holder name
               if information_checker < 15 then
                    pseudo = Hash.new
                    pseudo[:name] = informations[index].strip
                    pseudo[:main] = true
                    pseudos.push(pseudo)
                    index += 1
               end
               right_holder[:pseudos] = pseudos
               # get right_holder cae/ipi and society_name
               while informations[index].length == 0 do
                    index += 1
               end
               caeEAssociacao = informations[index].split(' ')
               if numeric?(caeEAssociacao[0][0]) != nil then
                    right_holder[:ipi] = caeEAssociacao[0]
                    right_holder[:ipi] = right_holder[:ipi].tr('.', '')
                    index += 1
               else 
                    right_holder[:ipi] = nil
               end
               if caeEAssociacao.length > 1 && numeric?(caeEAssociacao[1][0]) == nil then
                    right_holder[:society_name] = caeEAssociacao[1].strip
               end
               # get right_holder role and share
               if numeric?(informations[index][informations[index].length-1]) == nil then
                    index += 1
               end
               while informations[index].length == 0
                    index += 1
               end
               catESPorcentagem = informations[index].split(' ')
               right_holder[:role] = CATEGORIES[catESPorcentagem[0].strip]
               if catESPorcentagem.length > 1
                    right_holder[:share] = catESPorcentagem[1].strip
               else
                    index += 1
                    right_holder[:share] = informations[index].strip
               end
               # fix for specific error: remove date from category E works
               if right_holder[:share].length > 6 then
                    right_holder[:share] = right_holder[:share][0, right_holder[:share].length - 8].strip
               end
               if right_holder[:share][right_holder[:share].length-1] == ',' then
                    right_holder[:share] += '00'
               end
               right_holder[:share] = right_holder[:share].tr(',','.').to_f
               if right_holder[:name] == nil || right_holder[:role] == nil || right_holder[:share] == nil then
                    return nil
               end
               return right_holder
          end
          
          def work(line)
               components = line.split(' | ')
               # step 1: parse informations about the work
               workDs = components[0]
               informations = workDs.split('  ')
               workHash = Hash.new
               index = 0
               # get external_id
               while informations[index].length == 0 do
                    index += 1
               end
               external_ids = []
               external_id = Hash.new
               external_id[:source_name] = 'Ecad'
               external_id[:source_id] = informations[index].strip
               external_ids.push(external_id)
               workHash[:external_ids] = external_ids
               index += 1
               # get iswc
               while informations[index].length == 0 do
                    index += 1
               end
               workHash[:iswc] = informations[index].strip
               index += 1
               while informations[index].length == 0 do
                    index += 1
               end
               # if there is no iswc for this work, iswc is null
               if workHash[:iswc] == '-'
                    workHash[:iswc] = nil
                    index += 3
               end
               # get title
               while informations[index].length == 0 do
                    index += 1
               end
               workHash[:title] = informations[index].strip
               index += 1
               # get situation
               while informations[index].length == 0 do
                    index += 1
               end
               workHash[:situation] = informations[index].strip
               index += 1
               # get created_at
               while informations[index].length == 0 do
                    index += 1
               end
               workHash[:created_at] = informations[index].strip
               # step 2: parse informations about the right_holders
               rh_index = 1
               right_holders = []
               while rh_index < components.length do
                    this_right_holder = right_holder(components[rh_index])
                    right_holders.push(this_right_holder)
                    rh_index += 1
               end
               workHash[:right_holders] = right_holders
               return workHash
          end

          def debug_log(worksHashes)
               length = worksHashes.length
               puts "Works Hashes (#{length}):"
               puts ""
               while index < length
                    if worksHashes[index][:iswc] != nil
                         puts "iswc: #{worksHashes[index][:iswc]}"
                    else
                         puts 'iswc: null'
                    end
                    puts "title: #{worksHashes[index][:title]}"
                    puts "external_id: #{worksHashes[index][:external_ids][0][:source_name] + ' | ' + worksHashes[index][:external_ids][0][:source_id]}"
                    puts "situation: #{worksHashes[index][:situation]}"
                    puts "created_at: #{worksHashes[index][:created_at]}"
                    puts "right_holders (#{worksHashes[index][:right_holders].length.to_s}):"
                    worksHashes[index][:right_holders].each do |right_holder|
                         puts '-------------------------' 
                         puts "RH.name: #{right_holder[:name]}"
                         puts "RH.pseudos (#{right_holder[:pseudos].length.to_s}):"
                         if right_holder[:pseudos].length > 0 then
                              puts "  RH.pseudo: #{right_holder[:pseudos][0][:name]}"
                         end
                         puts "RH.ipi: #{right_holder[:ipi]}"
                         puts "RH.share: #{right_holder[:share]}"
                         puts "RH.role: #{right_holder[:role]}"
                         puts "RH.society_name: #{right_holder[:society_name]}"
                    end
                    puts ""
                    index += 1
               end
          end

          def numeric?(lookAhead)
               lookAhead =~ /[[:digit:]]/
          end

     end
end