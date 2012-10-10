require 'rubygems'
require 'text/highlight'
require 'set'
require 'wordwrap'
require 'configfinder'

$INDENT = "   "

#tell the highlighter to use ansi. ANSI is used to format help screens
String.highlighter = Text::ANSIHighlighter.new

class ConfigDef

	@@allowOpenList = 0 #allowed but not required
	@@forbidOpenList = 1 #straggling arguments result in error/abort
	@@requireOpenList = 2 #at least one token required in open list
	
	@@antStyleFindConfig = 0 #ascend directory tree looking for <appName>.yml
	@@homeDirFindConfig = 1 #look in user's home dir for config file
	@@otherDirFindConfig = 2 #look in a developer specified location
	@@noFindConfig = 3 #do not look for a config file unless specified on the cl

	def initialize(appName, configFileName, appSummary)
		@name= appName
		@mainSummary = appSummary
		@optionDefs = []
		@observedArgsHash = Hash.new()
		@useOpenList = @@allowOpenList 

		#the built in verbosity option
		verbosityFlagDef = SwitchDef.new(:verbosity, "Verbosity", 
				"How much info to print during execution")
		verbosityFlagDef.addCase(:quiet, "q", "quiet", "Print errors only")
		verbosityFlagDef.addCase(:verbose, "v", "verbose", 
			"Print full config report on init, plus other info")
		verbosityFlagDef.setDefault(:quiet)
		addFlagDef(verbosityFlagDef)

		#the built in config file location option
		@configFileFlagDef = ValueDef.new(:configFile, "Config File Location", 
				"f", "config-file", 1, 
				"The location of the #{configFileName} to use")
		@configFileFlagDef.setCommandLineOnly()
		addFlagDef(@configFileFlagDef)

		#the built in help option
		helpFlagDef = SwitchDef.new(:help, "Print Help", "")
		helpFlagDef.addCase(:present, "h", "help", "Prints this help message")
		helpFlagDef.setCommandLineOnly()
		addFlagDef(helpFlagDef)

		#the built in generate-template option
		templateFlagDef = SwitchDef.new(:genConfig, "Generate Config File", "")
		templateFlagDef.addCase(:present, "gt", "generate-config", 
				"Generates an example config file and places it XXXXXXX")
		templateFlagDef.setCommandLineOnly()
		addFlagDef(templateFlagDef)
	end

	def setUseOpenList(newStatus)
		@useOpenList = newStatus
	end

	def addFlagDef(flagDef)
		@optionDefs << flagDef
	end

	def deduceOptions(commandLineArgs)

		#create optionHash of those options present on the commandline
		clOptionHash = parseCommandLineArgs(commandLineArgs)
		@optionHash = clOptionHash

		#check for cliawesome options that divert control flow
		if(@optionHash.include?(:help))
			printCommandLineHelp()
			return
		end
		if(@optionHash.include?(:genConfig))
			generateConfigFile()
			return
		end

		return 

		#find the config file if it's location wasn't on the commandline
		if(clOptionHash.include?(@configFileFlagDef.getKey())
			configFileLocation = clOptionHash[@configFileFlagDef.getKey()]
		else
			configFileLocation = findConfigFile()
		end
		#create an optionHash of those options in the config file
		fileOptionHash = parseConfigFile(configFileLocation)
		
		#create an optionHash of default values
		defaultOptionHash = makeDefaultOptionHash()

		#merge the option hashes so that commandline overwrites configfile 
		#overwrites defaults
		@optionHash = (defaultOptionHash.merge(fileOptionHash)).merge(clOptionHash)

		#check that all mandatory options have been accounted for
		ensureMandatoryOptionsAreSet()

	end



	def generateConfigFile()
		puts "YAML CONFIG"
		puts getLeftJustBlock(@mainSummary, "# ")
		puts "\n"
		@optionDefs.each do |optDef|
			line = "\#" * (optDef.getName().length() + 6)
			puts line
			puts "\#\# #{optDef.getName()} \#\# "
			puts line
			puts optDef.generateYamlTemplate()
		end
	end

	def ensureMandatoryOptionsAreSet()
		@optionDefs.each do |optDef|
			if(optDef.isMandatory?())
				optVal = @optionHash[optDef.getKey()]
				if(optVal.nil?)
					abortOnError("Missing Option: \"#{optDef.getName()}\" is " +
					"required but has no default, is not in the config file, " +
					"and was not specified on the command line.")
				end
			end
		end
	end

	def parseCommandLineArgs(commandLineArgs)
		clOptionHash = Hash.new()
		lastArgWasHandled = true
		while (lastArgWasHandled && (not commandLineArgs.empty?))
			lastArgWasHandled = false
			clarg = commandLineArgs[0]
			@optionDefs.each do |optDef|
				puts "optionDef:#{optDef.getName}  clarg:#{clarg}"
				if(optDef.isHandlerOfFlag(clarg))
					lastArgWasHandled = true
					commandLineArgs.shift()
					optionVal = optDef.tokenToOptionValue(clarg, commandLineArgs)
					puts ("assinging val:#{optionVal} from arg:#{clarg} " +
							"to #{optDef.getKey()}")
					clOptionHash[optDef.getKey()] = optionVal
				end
			end
		end
		@openList = commandLineArgs #might be empty
		return clOptionHash
	end

	def parseConfigFile(filename)
		confHash = Hash.new()
		
		return confHash
	end

	#this makes a hash of all optionsKey,optionValue pairs for those options
	#that have default values
	def makeDefaultOptionHash()
		optionHash = Hash.new()
		@optionDefs.each do |optDef|
			default = optDef.getDefault()
			unless default.nil?
				optionHash[optDef.getKey()] = default
			end
		end
		return optionHash
	end

	def getOpenList()
		return @openList
	end

	def getFileOpenList() 

	end

	def getArgumentHash()
		return @optionHash
	end

	def abortOnError(errMessage)
		puts ("OPTION ERROR: " + errMessage)
		puts ("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
		printCommandLineHelp()
		exit(1)
	end

	def printCommandLineHelp()
		#try to get teh terminal width. if it fails set it back to 72
		initTermWidth()
		term_width = $TERMINAL_WIDTH

		#Title Bar
		title = "\n" + @name.center($TERMINAL_WIDTH).bold() + "\n"
		puts title
		
		#Command line short summary
		shortFlags = []
		@optionDefs.each do |optDef| 
			if(not (optDef.getPlacement == :configFileOnly))
				shortFlags << optDef.getShortCommandLineHelp()
			end
		end
		
		puts "\nSynopsis\n".bold()
		lineSumm =  $INDENT + @name.downcase.bold
		shortFlags.each do |str|
			if((str.length() + lineSumm.length()) > (term_width - $INDENT.length()))
				puts lineSumm
				lineSumm = ($INDENT + str)
			else
				lineSumm += (" " + str)
			end
		end
		puts lineSumm

		#AppSummary
		puts "\nDescription".bold
		puts getLeftJustBlock(@mainSummary, $INDENT)

		#Option section header
		puts "\nOptions".bold

		#asterisk explanation
		puts ($INDENT + "\'+\' indicates option can be set in config file.\n\n")
		
		#Long Option for each summary
		@optionDefs.each do |optDef|
			case optDef.getPlacement()
				when :commandLineOnly 
					puts ($INDENT + ("_" * (optDef.getName().length)))
					puts $INDENT + (optDef.getName()).underline
					puts optDef.getLongCommandLineHelp()
				when :either 
					puts ($INDENT + "_" * (optDef.getName().length))
					puts " + " + (optDef.getName()).underline
					puts optDef.getLongCommandLineHelp()
			end
			#puts "" 
		end

		
		
		#Config File explanation
		puts "\nFiles\n".bold()
		
		#Config File additional options
		#
		#
		puts "-\/end help"
	end

end
