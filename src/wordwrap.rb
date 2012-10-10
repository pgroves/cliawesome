
$WRAP_WIDTH = 72
$INDENT = "   "

def leftBlockIndent(str, indentStr)
		maxLineLength = $WRAP_WIDTH
		tokens = str.split(" ")
		retStr = ""
		line = indentStr
		tokens.each do |tok|
			if((line.length() + tok.length() + 3 ) > maxLineLength)
				retStr += line + "\n"
				line = indentStr + tok + " "
			else
				line += tok + " "
			end
		end
		retStr += line + "\n"
		return retStr
end

def centerBlock(str)
	str.center($WRAP_WIDTH)
end

def initTermWidth()
#STOLEN FROM RUPORT	    
	term_dimensions = `stty size`.split.map { |x| x.to_i }
	width = 
		if (term_dimensions[1] == 0)
			72
		else
			term_dimensions[1]
		end
	setWrapWidth(width)
end


def setWrapWidth(numChars)
	$WRAP_WIDTH = numChars
end
