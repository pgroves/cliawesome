#cliawesome#

Ruby Command line argument parsing and config file resolver

##Overview##

 - Focuses on documentation of the app created
 - Parameters can be specified in a YAML config file or on the commandline
 - Autogenerates a nice man-page style help screen when the end user runs
   the app with the -h option.
 - Generates a config file with all possible parameters set, but commented
   out.


##Basics##

cliawesome is a lightweight way to manage configuration options and parameters
that may appear in either a config file or be specified as commandline
arguments. The idea is to read in a config file with all the mandatory
confg-options set, then override them if the user specifies different args on
the commandline. The config file's location can be given explicitly by the user
on the command line, but if none is given the developer can dictate if the file
is looked for in the user's home directory or to traverse up the directory tree
looking for the first file it finds with the default config-file name (like how
Ant searches for a build.xml file to use). The config file's are YAML, but all
options are present in the files with the unused ones commented out (editing
the config files doesn't require knowledge of YAML, what to cut and paste is
obvious). 

To disambguate configuration units here from Ruby's built in arguments
(ARGV's), we call them Options. Before worrying about API specifics, lets talk
in general terms. Options can have one or more of the following
characteristics:

 - *Mandatory*: The Option must be specified somewhere by the *user*, either in
   the config file or commandline, or the program aborts
 
 - *Defaultable*: The Option is required, but there is a developer specified
   default. This includes flags/switches, that are one of several possible
   values.  NOTE: We don't bother calling any Options truly "optional", as
   there is always some type of default value - switches can be "false", lists
   of files can be an empty list, etc.
   
 - *Switches*: Options without an associated value are switches. All switches
   are XOR style, which means there are several predefined possible values for
   a switch. The implication is that simple boolean flags are really Switches
   with one of two values. Most obvious example is --verbose and --quiet, which
   negate each other. The order of precedence when multiple switches are given
   is last on commandline, last in config file. (That is, commandline args
   override config file settings, and the most recent on either is given
   precedence over that respective set.)
 
 - *Have values*: If an option needs N values they are assumed to be the N
   tokens after the option is given on the commandline. Such Options *cannot*
   have a variable number of inputs. Only the Open List (discussed below) can
   have a variable number of options.  CLIAwesome does not use equal signs "="
   to bind a value to an Option on the commandline. There is a builtin option
   that uses this, the "-f" / "--config-file" Option which specifies where the
   config file is from the commandline. For example, the useage could end up
   looking like 
   
   > \>myLittleApp --config-file some\_config.yaml -v
   
   to specify the config file "some\_config.yaml" and turn verbose on.

 - *Config File Only*: Some options can only be specified in a config file.
   Usually this is good idea if there are several options whose acceptable
   values depend on what the other Options are set to, and the chances of the
   user making an error on the commandline are high.
 
 - *Command Line Only*: Some options are not really "global" options for the
   application so it doesn't make sense to include them in a config file. For
   instance, if you create an app that creates a tarball given the name
   of a directory, you wouldn't put the name of the target directory in a 
   config file in your home directory.

 - *Open List*: After all the options declared by the developer have been read
   in on the commandline, anything else goes into an "Open List", which means
   it can have any number of values, and you don't have to put it in
   parenthesis and separate them by commas or anything like that. Because it
   sucks up any leftover commandline arguments, there is always exactly one
   Open List, but it may be of length zero.  This is for behaviour such as how
   the "tar" utility works, where you specify your options, the output
   filename, and then list as many files or directories as you want to tar up.
 
 - *Open File List*: A convenience method of the Open List is provided for apps
   whose open list is a list of filenames. If the Open List is treated as a
   File List, it will do wildcard filename expansion on the Open List Options,
   including the very convenient "/\*\*/" recursive operator, which expands
   directory names recursively. For instance a cli app could be called with
   something like 

   > \> myLittleApp -v \*\*/\*.html \*\*/\*.css
	
   and cliawesome would end up providing all the .html and .css files in any
   subdirectory of the current directory to myLittleApp when it requested the
   filename-expanded openList.
 
##Other Behaviours##

Finding the config file. If there are no mandatory, config-file-only
options, then the config-file is not necessary but can still be looked for.
The developer dictates what the default name for a config-file is
(convention is appName.yaml), and where to look for it. The options for
where to look are the user's home directory, or to traverse up the
directory tree from the current-working-directory and using the first
encountered filename with the default config-file name. The developer can
also dictate to not use config files at all. Of course, the user can
over-ride this location by directly specifying the location of the config
file on the commandline using the "-f" option when the app is run. 
 	
 	
##Tutorial/Manual (building "myLittleApp")##
 
Defining an executable that uses the  cliAwesome library is three steps:

1. Define a cliAwesome.ConfigDef object, which will contain what options
myLittleApp can handle and their properties, where the config file is, etc.

2. Run ConfigDef.deduceOptions(ARGV), which finds the config file, does all the
parsing and conflict resolution and returns a hash of (option keywords) =>
(string values). This hash is what the developer queries to get the parameters
set by the end user.

3. Run the myLittleApp program logic using the returned optionHash

##Example##

 - examples/navelgazer.rb is a simple executable that prints out it's
   process id and the name of the config file it's using, if any
 - examples/navelgazer.yml is the default config file generated by running

   > \> ruby navelgazer.rb 
