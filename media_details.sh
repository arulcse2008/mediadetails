#!/bin/bash
#set -x

# Media info parameters
mediaHeader=('General Complete name' 'General Format' 'General Format profile' \
	 'General Codec ID' 'General File size' 'General Duration' 'General Overall bit rate mode' \
	 'General Overall bit rate' 'General Encoded date' 'General Tagged date' \
	 'Video ID' 'Video Format' 'Video Format/Info' 'Video Format profile' 'Video Format settings' \
	 'Video Format settings, CABAC' 'Video Format settings, ReFrames' 'Video Codec ID' \
	 'Video Codec ID/Info' 'Video Duration' 'Video Bit rate' 'Video Width' 'Video Height' \
	 'Video Display aspect ratio' 'Video Frame rate mode' 'Video Frame rate' 'Video Color space' \
	 'Video Chroma subsampling' 'Video Bit depth' 'Video Scan type' 'Video Bits/(Pixel*Frame)' \
	 'Video Stream size' 'Video Writing library' 'Video Encoding settings' \
	 'Video Encoded date' 'Video Tagged date' 'Video Color range' 'Video Color primaries' \
	 'Video Transfer characteristics' 'Video Matrix coefficients' 'Audio ID' \
	 'Audio Format' 'Audio Format/Info' 'Audio Format profile' 'Audio Codec ID' 'Audio Duration' \
	 'Audio Bit rate mode' 'Audio Bit rate' 'Audio Channel(s)' 'Audio Channel positions' \
	 'Audio Sampling rate' 'Audio Frame rate' 'Audio Compression mode' 'Audio Stream size' \
	 'Audio Encoded date' 'Audio Tagged date')

declare  mediaData
output_file="output.csv"
extended_data=false
single_file=true


#Check whether the mediainfo utility is installed in the system or not?
which mediainfo > /dev/null
if [ $? != 0 ]
then
	echo "mediainfo utility is missing, Kindly install them using 'sudo apt-get install mediainfo'"
	exit 1
fi

create_header ()
{
	header=""
	echo "Creating file and pushing headers"

	for eachColumn in "${mediaHeader[@]}"; do
		column=$(echo $eachColumn | xargs echo -n)
		header+=$eachColumn"\t"
	done
	echo -e $header > $output_file
}

# function to print usage
usage ()
{
    echo "Usage: $0 -s|-m <Media file / text file> <-full(optional)>"
    echo "eg: $0 -s video.mp4"
    echo "eg: $0 -m list_of_mediafiles.txt"
    exit 1
}

processMetadata ()
{
	#Check whether input video file is available or not?
	if [ -e $1 ]
	then
		tmpfile=$(mktemp /tmp/metadata.XXXXXX)

		# for detailed meta data
		if [ $extended_data = "true" ]
		then
			mediainfo  -f $1 > "$tmpfile"
		else
			mediainfo $1 > "$tmpfile"
		fi

		mediaInfoLen="${#mediaHeader[@]}"
		#Initialize mediaData array
		count=0
		while [[ $count -lt $mediaInfoLen ]]
		do
			mediaData[$count]="0"
			#increase the count
			count=$((count+1))
		done

		output=""
		# Process one by one field
		while IFS=':' read -r param value
		do
			if [[ $param = "General" || $param = "Video" || $param = "Audio" ]]; then
				#Add headers to each field as there are common factors b/w video/audio
				appendStr="$param "
			fi

			# skip headers like General, Video, Audio from mediainfo output
			if [ -z "$value" ]; then
				continue
			else
				count=0
				# Remove white space from the fields
				param=$(echo $appendStr$param | xargs echo -n)

				while [[ $count -lt $mediaInfoLen ]]
				do
					if [[ $param = ${mediaHeader[$count]} ]]; then
						value=$(echo $value | xargs echo -n)
						mediaData[$count]=$value
						break;
					fi

					#increase the count
					count=$((count+1))
				done
			fi
		done < $tmpfile

		data=""
		#dumping data into the row for the file
		for eachColumn in "${mediaData[@]}"; do
			data+=$eachColumn"\t"
		done

		# writing the details to output file
		echo -e $data >> $output_file


		# cleanup temporary files
		rm "$tmpfile"
	else
		echo "$1 is not found, Please check the file name"
		exit 1
	fi
}

# check input arguments
if (( $# != 2 && $# != 3))
then
	usage
fi

#validate for single media file
if [ "$1" = "-s" ]
then
	single_file=true
#validate for list of media file
elif [ "$1" = "-m" ]
then
	single_file=false
else
	echo "Invalid arguments $1"
	usage
fi

if [ ! -f $2 ]
then
	echo "File $2 is not found, Please check the file name / path"
	exit 1
fi

if [ "$3" = "-full" ];
then
	extended_data=true
	echo "'$3' option is yet to be implemented"
	exit 1
fi

# Create a file header for output file
create_header $output_file
fileCount=0
if [ $single_file = "true" ]
then
	processMetadata $2 $fileCount
else
	while read -r eachMediaFile
	do
		#Check whether input video file is available or not
		if [ -e $eachMediaFile ]
		then
			processMetadata $eachMediaFile $fileCount
			fileCount+=1
		else
			echo "'$eachMediaFile' File not available"
		fi
	done < $2
fi
echo "Extracting meta details are done."
exit 0
