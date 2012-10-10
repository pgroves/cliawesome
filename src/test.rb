#!/usr/bin/ruby

require 'rubygems'

require 'text/highlight'
require 'cliawesome'

#tell the highlighter to use ansi. ANSI is used to format help screens
String.highlighter = Text::ANSIHighlighter.new

if __FILE__ == $0
	#str = ARGV[0]
	#termDims = `stty size`.split.map { |x| x.to_i }.reverse
	#$TERMINAL_WIDTH = termDims[0]
	#$TERMINAL_WIDTH = 72 if ($TERMINAL_WIDTH.nil? || $TERMINAL_WIDTH == 0)
	#puts str.bold
	#centered = str.center($TERMINAL_WIDTH)
	#puts centered

	#puts centered.bold()
	summ = %{ blah blaha lajlj a;lkjf lelekj e klej ej ke e iclka. oi e laki
	 lakjs al kfi elk aie kejkejk ei eklejlekjlkjelekkje e ielkeeoajc; c ;askeji
	 elkj lsei kej lskicidk  eje e ee ejd lksjie  . ejlaskjdpw o23kj o5i3l , j;
	 laksjel kje kcode}
	
	optsDef = ConfigDef.new("myLittleApp", "tester.yml", summ)
	optsDef.deduceOptions(ARGV)
	
	argHash = optsDef.getArgumentHash()
	puts "\n\n\nReturned Option Hash:".bold()
	argHash.each {|key, value| puts "#{key} is #{value}" }

	puts "\nOpen List:".bold
	openList = optsDef.getOpenList()
	openList.each { |x| puts x}

	puts "\ntest done".bold

end
