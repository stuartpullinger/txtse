#!/bin/bash -x

TXTSE_IN_DIR=$PWD
TXTSE_OUT_DIR=$PWD
TXTSE_TEMP_DIR=/tmp
TXTSE_CONF_FILE=$HOME/.txtse.conf
TXTSE_MIME_PROGRAM="file -b --mime-type \$TXTSE_SOURCE_FILE"
TXTSE_PDF_TO_TEXT="pdftotext \$TXTSE_SOURCE_FILE \$TXTSE_TXT_FILE"
TXTSE_HTML_TO_TEXT="html2text -o \$TXTSE_TXT_FILE \$TXTSE_SOURCE_FILE"
TXTSE_TEX_TO_TEXT="detex \$TXTSE_SOURCE_FILE > \$TXTSE_TXT_FILE"
TXTSE_USE_EDITOR=true
#TXTSE_EDITOR=$EDITOR
TXTSE_EDITOR="vi"
TXTSE_TXT_TO_SPEECH_TO_PIPE="espeak -v en-rp -f \$TXTSE_TXT_FILE --stdout"
TXTSE_PIPE_TO_MP3_TO_PIPE="lame --tt \$TXTSE_TITLE --ta \$TXTSE_AUTHOR --tl \$TXTSE_ALBUM - -"
TXTSE_OUT_DIR_FORMAT="$TXTSE_AUTHOR/$TXTSE_TITLE"

source $TXTSE_CONF_FILE

# Test whether infile is specified on command line
if [ -n "$1" ]; then
	# input file or directory specified
	if [ -f $1 ]; then
		TXTSE_IN_FILE=$1
		TXTSE_IN_MODE="FILE"
	elif [ -d $1 ]; then
		TXTSE_IN_DIR=$1
		TXTSE_IN_MODE="DIR"
	fi
else
	TXTSE_IN_MODE="DIR"
fi
# Test whether outfile is specified on command line
if [ -n "$2" ]; then
	# output file or directory specified
	if [ -f $2 ]; then
		TXTSE_OUT_FILE=$2
		TXTSE_OUT_MODE="FILE"
	elif [ -d $2 ]; then
		TXTSE_OUT_DIR=$2
		TXTSE_OUT_MODE="DIR"
	fi
else
	TXTSE_OUT_MODE="DIR"
fi

# Test for file input mode or directory input mode
if [ "$TXTSE_IN_MODE" = "FILE" ]; then
	TXTSE_FILE_LIST=($TXTSE_IN_FILE)
elif [ "$TXTSE_IN_MODE" = "DIR" ]; then
	TXTSE_FILE_LIST=`ls $TXTSE_IN_DIR`
fi

# Main Program Loop
for TXTSE_SOURCE_FILE in $TXTSE_FILE_LIST; do

	# Test mime type of file
	TXTSE_MIME_TYPE=`eval $TXTSE_MIME_PROGRAM`
	#echo  $TXTSE_SOURCE_FILE $TXTSE_MIME_TYPE

	# Assign conversion program based on mime type
	case "$TXTSE_MIME_TYPE" in
		application/pdf)
			TXTSE_SOURCE_TO_TXT=$TXTSE_PDF_TO_TEXT;;
			#echo recognised pdf;;
		text/html)
			TXTSE_SOURCE_TO_TXT=$TXTSE_HTML_TO_TEXT;;
		text/x-tex)
			TXTSE_SOURCE_TO_TXT=$TXTSE_TEX_TO_TEXT;;
		text/plain)
			TXTSE_SOURCE_TO_TXT="true";;
	esac
	#echo $TXTSE_SOURCE_TO_TXT

	# Create temporary text file
	TXTSE_TXT_FILE=`tempfile --directory $TXTSE_TEMP_DIR --prefix TXTSE --suffix .txt`

	# Convert source to text
	#echo $TXTSE_TXT_FILE
	eval $TXTSE_SOURCE_TO_TXT

	# Open file in editor for editing
	if [ $TXTSE_USE_EDITOR ]; then
		eval $TXTSE_EDITOR $TXTSE_TXT_FILE
	fi

	# TODO: split file on lines containing "TXTSE_SPLIT"

	# Edit id3 info
	TXTSE_ID3_FILE=`tempfile --directory $TXTSE_TEMP_DIR --prefix TXTSE --suffix .id3`
	echo -e "TXTSE_TITLE=\nTXTSE_AUTHOR=\nTXTSE_ALBUM=" >> $TXTSE_ID3_FILE
	eval $TXTSE_EDITOR $TXTSE_ID3_FILE
	source $TXTSE_ID3_FILE

	# Convert text file to wav file(s)/mp3 file(s)
	if [ "$TXTSE_OUT_MODE" = "FILE" ]; then
		eval $TXTSE_TXT_TO_SPEECH_TO_PIPE " | " $TXTSE_PIPE_TO_MP3_TO_PIPE " > " $TXTSE_OUT_FILE
	elif [ "$TXTSE_OUT_MODE" = "DIR" ]; then
		eval $TXTSE_TXT_TO_SPEECH_TO_PIPE " | " $TXTSE_PIPE_TO_MP3_TO_PIPE " > " $TXTSE_OUT_DIR/$TXTSE_OUT_DIR_FORMAT/${TXTSE_SOURCE_FILE%.*}.mp3	
	fi

	# Remove temporary files
	rm $TXTSE_ID3_FILE $TXTSE_TXT_FILE
done
