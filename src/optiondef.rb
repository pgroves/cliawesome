
class FlagDef

	def initialize(key, name, summary)
		@name = name
		@key = key
		@summary = summary
		@matches = []
		@isMandatory = false
		@allowedPlacement = :either
		@defaultValue = nil
	end
	
	def addMatch(commandLineToken)
		@matches << commandLineToken
	end

	def isMandatory?
		return @isMandatory
	end

	def setIsMandatory(isIt) 
		@isMandatory = isIt
	end

	def setDefault(value)
		@defaultValue = value
		setIsMandatory(false)
	end

	def getDefault()
		return @defaultValue
	end

	def getSummary()
		return @summary
	end

	def setCommandLineOnly()
		@allowedPlacement = :commandLineOnly
	end

	def setConfigFileOnly()
		@allowedPlacement = :configFileOnly
	end

	def setEitherPlacement()
		@allowedPlacement = :either
	end

	def getPlacement()
		return @allowedPlacement
	end

	def getKey()
		return @key
	end

	def getName()
		return @name
	end

	def isHandlerOfFlag(argToken)
		@matches.include?(argToken)
	end

	def generateYamlOptComments()
		str = leftBlockIndent(@summary, "## ")
		if(isMandatory?())
			str += "## \+ This option is mandatory.\n"
		else
			str += "## \+ This option may be left unspecified.\n"
		end
		if(getPlacement() == :configFileOnly)
			str += "## \+ It can only be set by a config file.\n"
		else
			str += "## \+ It may be set here or on the command line.\n"
		end
		return str
	end
end



class SwitchDef < FlagDef

	def initialize(key, name, summary)
		super(key, name, summary)
		@summariesHash = Hash.new()
		@matchHash = Hash.new()
		@caseKeys = Set.new()
		@shortNames = Hash.new()
		@longNames = Hash.new()
	end

	def addCase(caseKey, shortMatch, longMatch, summary)
		short = "-#{shortMatch}"
		long = "--#{longMatch}"
		addMatch(short)
		addMatch(long)
		@summariesHash[caseKey] = summary
		@matchHash[long] = caseKey #for commandline
		@matchHash[short] = caseKey #for commandline
		@matchHash[caseKey.to_s] = caseKey #for config file
		@caseKeys.add(caseKey)
		@shortNames[caseKey] = short
		@longNames[caseKey] = long
	end


	def tokenToOptionValue(argToken, remainingArgs)
		@matchHash[argToken]
	end

	def stringsToOptionValue(strs)
		@matchHash[strs]
	end
	def getShortCommandLineHelp()
		str = "\{"
		@shortNames.each_value {|flg| str += "#{flg}\|"}
		str.chop!() #remove trailing bar
		str += "\}"
	end

	def getLongCommandLineHelp()
		str = "" 
		if (not @summary.empty?)
			str += leftBlockIndent(@summary, ($INDENT))
		end
		str += "\n"
		@caseKeys.each do |caseKey|
			str += (($INDENT * 2) + @shortNames[caseKey] + ", " + 
					@longNames[caseKey]).bold
			str += "\n" + leftBlockIndent(@summariesHash[caseKey], $INDENT * 3) 
			str += "\n"
		end
		str.chop!()
		return str
	end

	def generateTemplateSnippet()
		str = generateYamlOptComments()
		if(@caseKeys.size() > 1) 
			expl = "Valid arguments for #{@key} are \["
			@caseKeys.each do |ky| 
				expl += ky.to_s 
				expl += ", "
			end
			expl.chop!().chop!()
			expl += "\]"
			str += leftBlockIndent(expl, "## * ")
		end
		str += "\n" 
		switchYamlName = @key.to_s
		@caseKeys.each do |ky|
			prefix = if(ky == getDefault()) then "" else "#" end
			str += prefix + switchYamlName + ": " + (ky.to_s) + "\n"
		end
		str += "\n\n" 
		return str
	end


end

class ValueDef < FlagDef

	def initialize(key, name, shortName, longName, 
			numSubsequentTokensToConsume, summary)

		super(key, name, summary)
		@numValues = numSubsequentTokensToConsume
		@defaultValues = nil
		@shortName = "-#{shortName}"
		@longName = "--#{longName}"
		addMatch(@shortName)
		addMatch(@longName)
	end

	def tokenToOptionValue(argToken, remainingArgs)
		strVals = []
		@numValues.times {strVals << remainingArgs.shift()}
		return strVals
	end

	def stringsToOptionValue(strs)
		return strs
	end

	def getValuesHelpString()
		str = ""
		if(@valueDocLabels.nil?())
			@numValues.times {|i| str += " \<value_#{i}\>"}
		else
			@valueDocLabels.each {|lbl| str += " \<#{lbl}\>"} 
		end
		return str
	end

	def setValueDocLabels(strs)
		@valueDocLabels = strs
	end

	def getLongCommandLineHelp()
		
		str = "" 
		if (not @summary.empty?)
			str += leftBlockIndent(@summary, ($INDENT))
		end
		str += "\n"
		str += (($INDENT * 2) + @shortName + getValuesHelpString() + ",\n").bold
		str += (($INDENT * 2) + @longName + getValuesHelpString()).bold
		return str
	end

	def getShortCommandLineHelp()
		str = "\{#{@shortName} #{getValuesHelpString()}\}"
	end

	def generateTemplateSnippet()
		#puts "OptionDef: #{getName()}: isMandatory: #{isMandatory?().to_s}"
		str = generateYamlOptComments()
		str += "\n" 
		if(getDefault().nil?)
			if(@valueDocLabels.nil?)
				valueStrs = []
				@numValues.times {|i| valueStrs[i] = "REPLACE_ME"}
			else
				valueStrs = @valueDocLabels
			end
		else
			valueStrs = getDefault
		end
		prefix = if(isMandatory?()) then "" else "\#" end
		str += prefix + "#{@key.to_s}:\n"
		@numValues.times {|i| str += (prefix + " - " + valueStrs[i] + "\n")}
		str += "\n\n" 
		return str
	end

end

