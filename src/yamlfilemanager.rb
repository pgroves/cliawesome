require 'wordwrap'
require 'optiondef'
require 'rubygems'
require 'pathname'
require 'yaml'

class ConfigFileManager

	#configFileBasename is the basename and extension (no path info) of 
	#the configFile. Default behaviour is ascend-directories.
	def initialize()

	end

	def getOptionHash()
		return @optionHash
		
	end

	def generateConfigFile(appTitleStr, appSummaryStr, optionDefs)
		puts "generating config file: \'#{templatePathname()}\'"
		str = "# #{appTitleStr} \n"
		str += leftBlockIndent(appSummaryStr, "# ")
		str += "\n"
		str += "---\n"
		optionDefs.each do |optDef|
			unless (optDef.getPlacement() == :commandLineOnly)
				line = "\#" * (optDef.getName().length() + 6) + "\n"
				str += line
				str += "\#\# #{optDef.getName()} \#\#\n"
				str += line
				str += optDef.generateTemplateSnippet()
			end
		end
		iostream = File.open(templatePathname(), "w")
		iostream.write(str)
		iostream.close()
		puts "done."
	end

	#loads the config file into this configFileManager's optionValueHash
	def loadConfigFile(filename, optionDefs)
		path = Pathname.new(filename)
		rawOptionHash = YAML.load_file(path.to_s)

		#replace string keys from the file with optionDef keys
		@optionHash = Hash.new()
		optionDefs.each do |optDef|
			stringOfOptKey = optDef.getKey().to_s()
			if(rawOptionHash.has_key?(stringOfOptKey))
				stringValue = rawOptionHash[stringOfOptKey]
				realValue = optDef.stringsToOptionValue(stringValue)
				@optionHash[optDef.getKey()] = realValue
			end
		end
	end

end

#do not look for a config file unless specified on the cl
class NoConfigFile < ConfigFileManager

	def initialize()
	end

	def getHelpSnippet()
		return ""
	end

	def processConfigFile()
		return Hash.new()
	end

	def usesConfigFile()
		return false
	end
	def templateTargetDocName()
		return "\|ERROR: No Config File.\|"
	end
end

#look in a developer specified location
class FixedLocationConfigFile < ConfigFileManager

	def initialize(fullname)
		@pathname = Pathname.new(fullname)
	end

	def getHelpSnippet()
		return "The default config file location is #{@filename}"
	end

	def usesConfigFile()
		return true
	end

	def templateTargetDocName()
		return @pathname
	end

	def getPathname()
		return @pathname
	end

	def templatePathname()
		return @pathname
	end
end

#ascend directory tree looking for <appName>.yml
class CrawlUpConfigFile < ConfigFileManager

	def initialize(basename)
		@basename =  basename
	end

	def getHelpSnippet()
		return "The config file used will be the first instance of " +
				"#{@basename} found when ascending the directories of the " +
				"local machine's filesytem, starting at the directory this " +
				"command is run from."
	end

	def crawlUp(dir, base)
		while (dir.exist?)
			#puts dir
			candidate = (dir.join(base))
			if(candidate.exist?)
				return candidate
			end
			if(dir.root?)
				puts "Did not find file #{base} in crawlup"
				exit
			end
			dir = dir.parent()
		end
		puts "Did not find file #{base} in crawlup"
		exit
	end

	def getPathname()
		currentDir = Pathname.getwd()
		return crawlUp(currentDir, @basename)
	end

	def templatePathname()
		return ".\/#{@basename}"
	end

	def usesConfigFile()
		return true
	end

	def templateTargetDocName()
		return ".\/#{@basename}"
	end
end

#look in user's home dir for config file
class HomeDirConfigFile < FixedLocationConfigFile

	def initialize(basename)
		super(Pathname.join(Gem.user_home, basename))
		@basename = basename
	end

	def templateTargetDocName()
		return "\~\/#{@basename}"
	end
	
end
