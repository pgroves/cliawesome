#cliawesome#

Ruby command line arguments, config file, and documentation engine. For building
properly documented command line applications with config files in ruby.

##Overview##

 - Focuses on documentation of the app created
 - Parameters can be specified in a YAML config file or on the commandline
 - Generates a nice man-page style help screen when the end user runs
   the app with the -h option. [Here's one generated for the example app.](https://gist.github.com/3874687)
 - Generates a nicely documented config file with all possible parameters set, but commented
   out. [Here's one generated for the example app](https://gist.github.com/3874687)
 - Parameters are first set as defaults, then overwritten by any values in
   the config file, then overwritten by any commandline arguments
 - Final values are returned in a hash map of strings values.
 - Also returns an "open list" of any trailing arguments on the commandline. This
   contains any wildcard expansions the shell may do.


##Basics##

cliawesome is a lightweight way to manage configuration options and parameters
that may appear in either a config file or be specified as commandline
arguments. The idea is to read in a config file with all the mandatory
confg-options set, then override them if the user specifies different args on
the commandline. The config file's location can be given explicitly by the user
on the command line. However, if not specified, the developer can dictate if the file
is looked for in the user's home directory or to traverse up the directory tree
looking for the first file it finds with a given name (like my_app_config.yml). 
The config file's are YAML, but all
options are present in the generated template files, with the unused options
commented out so the user doesn't really need to understand YAML.

To disambguate configuration units here from Ruby's built in arguments
(ARGV's), we call them Options. Before worrying about API specifics, lets talk
in general terms. Options can have one or more of the following
characteristics:

 - *Mandatory*: The Option must be specified somewhere by the *user*, either in
   the config file or commandline, or the program aborts
 
 - *Defaultable*: The Option is required, but there is a developer specified
   default. This includes flags/switches, that are one of several possible
   values.  
   
 - *Switches*: Options without an associated value are switches. All switches
   are XOR style, which means there are several predefined possible values for
   a switch. The implication is that simple boolean flags are really Switches
   with one of two values. Most obvious example is Verbosity, with
   flags --verbose and --quiet, which negate each other. 
   When multiple values for one switch are encountered, commandline args
   override config file settings, and the most recent on either is given
   precedence over that respective set.
 
 - *Have values*: If an option needs N values they are assumed to be the N
   tokens after the option is given on the commandline. Such Options *cannot*
   have a variable number of inputs. Only the Open List (discussed below) can
   have a variable number of options.  CLIAwesome does not use equal signs "="
   to bind a value to an Option on the commandline. There is a builtin option
   that uses this, the "--config-file" Option takes one value, which specifies where the
   config file is from the commandline. For example, the useage could end up
   looking like 
   
   > \>myLittleApp --config-file some\_config.yaml -v
   
   to specify the config file "some\_config.yaml" and turn verbose on.

 - *Config File Only*: The developer can tell cliawesome that an
    option should only be specified in a config file.   
 
 - *Command Line Only*: Same idea as "Config File Only." 

 - *Open List*: After all the options declared by the developer have been read
   in on the commandline, anything else goes into an "Open List", which means
   it can have any number of values, and you don't have to put it in
   parenthesis and separate them by commas or anything like that. Because it
   sucks up any leftover commandline arguments, there is always exactly one
   Open List, but it may be of any length (including zero length).  
 
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

##Builtin Options##

 - *Verbose (-v)* if set, cliawesome will print out all the parameter values
 it has gathered from the commandline and config file. Can also be -q for
 "quiet".

 - *Generate Config (-gt)* creates a config file with option descriptions 
 as comments, and default values if supplied by the developer.

 - *Print Help (-h)* print a help screen and exit.
 
##Finding the config file##

If there are no mandatory, config-file-only
options, then the config-file is not necessary but can still be looked for.
The developer dictates what the default name for a config-file is
(convention is appName.yml), and where to look for it. The options for
where to look are

1. User's home directory
2. Traverse up the directory tree from the current-working-directory and using the first
encountered filename with the default config-file name. 
3. Fixed Location. For instance, you may put a standard config file in /usr/share/myApp.
3. None (don't look for a config file).

Of course, the user can
over-ride the location specified by the developer by directly specifying the location of the config
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

Examples of calling navelgazer from the commandline 


<pre>
    > cd examples/ 
    > ./navelgazer --generate-config
    generating config file: './navelgazer.yml'
    done.
</pre>

The resulting navelgazer.yml can be seen here: https://gist.github.com/3874659 

<pre>
    > ./navelgazer -b * 
	Switch A was set to Case 1
	Switch B is On
	Values for C are: [blue, green]
	The open_list values are:
	 - navelgazer
	 - navelgazer.yml
</pre> 

<pre>
    > ./navelgazer --help
</pre>

The resulting help page from running with the help option is here: https://gist.github.com/3874687

##Dependencies##

cliawesome is pure Ruby and only relies on the text/highlight gem to do bold and underlining on the
commandline.

    > gem install text-highlight