require 'rubygems'
require 'text/highlight'
require 'set'
require 'wordwrap'
require 'optiondef'
require 'yamlfilemanager'
require 'commandlinemanager'



#tell the highlighter to use ansi. ANSI is used to format help screens
String.highlighter = Text::ANSIHighlighter.new

class ConfigDef

	def initialize(appName, appSummary, clManager, yamlManager)
		@name= appName
		@mainSummary = appSummary
		@optionDefs = []
		@commandLineManager = clManager
		@configFileManager = yamlManager
		@loudness = :quiet

		initBuiltinOptions()
	end

	def setYamlManager(mngr)
		@configFileManager = mngr
	end

	def yaml_manager()
		return @configFileManager
	end

	def addFlagDef(flagDef)
		@optionDefs << flagDef
	end

	def getCommandLineManager()
		return @commandeLineManager
	end

	def deduceOptions(commandLineArgs)

		#create optionHash of those options present on the commandline
		@commandLineManager.processArgs(commandLineArgs, @optionDefs)
		clOptionHash = @commandLineManager.getOptionHash()
		if(clOptionHash.include?(:verbosity))
			@loudness = clOptionHash[:verbosity]
		end

		if(@loudness == :verbose)
			puts "\nOptions from commandline:"
			puts (hashString clOptionHash)
		end

		#check for cliawesome options that divert control flow
		if(clOptionHash.include?(:help))
			printCommandLineHelp()
			return
		end
		if(clOptionHash.include?(:genConfig))
			@configFileManager.generateConfigFile(@name, @mainSummary, @optionDefs)
			return
		end

		#find the config file if it's location wasn't on the commandline
		if(clOptionHash.include?(@configFileFlagDef.getKey()))
			configFileLocation = clOptionHash[@configFileFlagDef.getKey()]
		else
			configFileLocation = @configFileManager.getPathname()
		end
		#create an optionHash of those options in the config file
		@configFileManager.loadConfigFile(configFileLocation, @optionDefs)
		fileOptionHash = @configFileManager.getOptionHash()

		if(@loudness == :verbose)
			puts "\nOptions from config file \'#{configFileLocation}\':"
			puts (hashString fileOptionHash)
		end
		
		#create an optionHash of default values
		defaultOptionHash = makeDefaultOptionHash()

		if(@loudness == :verbose)
			puts "\nDefault Options:"
			puts (hashString defaultOptionHash)
		end

		#merge the option hashes so that commandline overwrites configfile 
		#overwrites defaults
		@optionHash = (defaultOptionHash.merge(fileOptionHash)).merge(clOptionHash)
		if(@loudness == :verbose)
			puts "\nFinal Option Set:"
			puts (hashString @optionHash)
		end

		#check that all mandatory options have been accounted for
		ensureMandatoryOptionsAreSet()

	end

	def ensureMandatoryOptionsAreSet()
		#puts "\n\ninside ensureMandatoryOptions..."
		#puts "\nObject variable Hash:"
		#puts (hashString @optionHash)

		@optionDefs.each do |optDef|
			#puts "testing optdef: #{optDef.getName()}"
			if(optDef.isMandatory?())
				#puts "isMandatory:true: #{optDef.getName()}"
				optKey = optDef.getKey()
				#puts "key: \'#{optKey}\' has type: \'#{optKey.class}\'"
				optVal = @optionHash[(optDef.getKey())]
				#puts "key: \'#{optDef.getKey()}\' has value: \'#{optVal}\'"
				if(optVal.nil?)
					abortOnError("Missing Option: \"#{optDef.getName()}\" is " +
					"required but is not in the config file, " +
					"was not specified on the command line, and has no default.")
				end
			end
		end
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

	def printCommandLineHelp()
		@commandLineManager.printCommandLineHelp(@name, @mainSummary, 
					@optionDefs, @configFileManager)
	end

	def getArgumentHash()
		return @optionHash
	end
	
	def getOpenList()
		return @commandLineManager.getOpenList()
	end

	def abortOnError(errMessage)
		puts ("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
		puts ("OPTION ERROR: " + errMessage)
		puts ("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
		#printCommandLineHelp()
		exit(1)
	end

	def initBuiltinOptions()

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
				"The name of a config file to use other than the default")
		@configFileFlagDef.setCommandLineOnly()
		@configFileFlagDef.setValueDocLabels(["filename"])
		addFlagDef(@configFileFlagDef)

		#the built in help option
		helpFlagDef = SwitchDef.new(:help, "Print Help", "")
		helpFlagDef.addCase(:present, "h", "help", "Prints this help message")
		helpFlagDef.setCommandLineOnly()
		addFlagDef(helpFlagDef)

		#the built in generate-template option
		templateFlagDef = SwitchDef.new(:genConfig, "Generate Config File", "")
		templateFlagDef.addCase(:present, "gt", "generate-config", 
				"Generates an example config file and places it at "+
				@configFileManager.templateTargetDocName())
		templateFlagDef.setCommandLineOnly()
		addFlagDef(templateFlagDef)

	end

	def hashString(hsh)
		str = "\{"
		hsh.each do |ky, vl|
			str += " #{ky} => #{vl} ,"
		end
		str.chop!()
		str += "\}"
		return str
	end

end
