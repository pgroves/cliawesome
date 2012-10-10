
class CommandLineManager

	@@allowOpenList = 0 #allowed but not required
	@@forbidOpenList = 1 #straggling arguments result in error/abort
	@@requireOpenList = 2 #at least one token required in open list

	def initialize()
		@useOpenList = @@allowOpenList
	end

	def setOpenListUseage(newUseage)
		@useOpenList = newUseage
	end

	def processArgs(commandLineArgs, optionDefs)
		@optionHash = Hash.new()
		lastArgWasHandled = true
		while (lastArgWasHandled && (not commandLineArgs.empty?))
			lastArgWasHandled = false
			clarg = commandLineArgs[0]
			optionDefs.each do |optDef|
				#puts "optionDef:#{optDef.getName}  clarg:#{clarg}"
				if(optDef.isHandlerOfFlag(clarg))
					lastArgWasHandled = true
					commandLineArgs.shift()
					optionVal = optDef.tokenToOptionValue(clarg, commandLineArgs)
					#puts ("assinging val:#{optionVal} from arg:#{clarg} " +
					#		"to #{optDef.getKey()}")
					@optionHash[optDef.getKey()] = optionVal
				end
			end
		end
		@openList = commandLineArgs #might be empty
	end

	def getOptionHash()
		return @optionHash
	end

	def getOpenList()
		return @openList

	end

	def printCommandLineHelp(appName, appSummary, optionDefs, yamlManager)
		#return string
		rs = ""

		#try to get teh terminal width. if it fails set it back to 72
		initTermWidth()
		term_width = $WRAP_WIDTH

		#Title Bar
		title = "\n" + appName.center(term_width).bold() + "\n"
		rs += title + "\n"
		
		#Command line short summary
		shortFlags = []
		optionDefs.each do |optDef| 
			if(not (optDef.getPlacement == :configFileOnly))
				shortFlags << optDef.getShortCommandLineHelp()
			end
		end
		
		rs += "\nSynopsis\n".bold() + "\n"
		lineSumm =  $INDENT + appName.downcase.bold
		shortFlags.each do |str|
			if((str.length() + lineSumm.length()) > (term_width - $INDENT.length()))
				rs += lineSumm + "\n"
				lineSumm = ($INDENT + str)
			else
				lineSumm += (" " + str)
			end
		end
		rs += lineSumm  + "\n"

		#AppSummary
		rs+= "\nDescription".bold + "\n\n"
		rs += leftBlockIndent(appSummary, $INDENT) + "\n"

		#Option section header
		rs += "\nOptions".bold + "\n"


		#asterisk explanation
		rs += ($INDENT + "\'+\' indicates option can be set in config file.\n\n")
		
		#Long Option for each summary
		optionDefs.each do |optDef|
			case optDef.getPlacement()
				when :commandLineOnly 
					rs += ($INDENT + ("_" * (optDef.getName().length))) + "\n"
					rs += $INDENT + (optDef.getName()).underline + "\n"
					rs += optDef.getLongCommandLineHelp() + "\n"
				when :either 
					rs += ($INDENT + "_" * (optDef.getName().length)) + "\n"
					rs += " + " + (optDef.getName()).underline + "\n"
					rs += optDef.getLongCommandLineHelp() + "\n"
			end
			#rs += "" 
		end

		
		
		#Config File explanation
		if(yamlManager.usesConfigFile())
			rs += "\nConfig File".bold() + "\n"
			s1 = yamlManager.getHelpSnippet() + "\n"
			s1 += "Use --generate-config to create a template config file " +
					"at \'#{yamlManager.templateTargetDocName()}\'."
			rs += leftBlockIndent(s1, $INDENT) + "\n"
			lstr = ""  #local string buffer
			optionDefs.each do |optDef|
				case optDef.getPlacement()
					when :configFileOnly 
						lstr += ($INDENT + ("_" * (optDef.getName().length))) 
						lstr += "\n"
						lstr += $INDENT + (optDef.getName()).underline + "\n"
						lstr += leftBlockIndent(optDef.getSummary(), $INDENT * 2)
						lstr += "\n"
				end
			#rs += "" 
			end
			unless (lstr == "")
				rs += "Config File Only Options".bold() + "\n"
				s2 = "These options can only be set through a config file."
				rs += leftBlockIndent(s2, $INDENT) + "\n"
				rs += lstr
			end
		end
		
		#Config File additional options
		#
		#
		rs += "-\/end help"
		puts rs
	end

end
