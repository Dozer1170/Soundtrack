#!/bin/bash

#Shell script to read ID3v1.x Tag from an mp3 audio file
#Known Issue: Because the '\0' are replaced with ' ' blankspaces. The Genre value 0 will be replaced by 32
#To get it right instead of storing the tag string in a variable direct access is needed

# ID3v2 constants
tag_header_size_characters=20
frame_header_size_characters=20

function debug() {
  if [ $DEBUG -eq 1 ]
  then
    echo "$1"
  fi
}

function error() {
  >&2 echo $1
}

function hex_str_to_int() {
  echo $(printf "%d" 0x$1)
}

function print_id3v2_version() {
  id3=$1
  debug "ID3 Header: $id3"
  id3v2_ver=${id3:6:2}
  id3v2_ver=$(hex_str_to_int $id3v2_ver)

  id3v2_rev=${id3:8:2}
  id3v2_rev=$(hex_str_to_int $id3v2_rev)
  debug "ID3v2.$id3v2_ver.$id3v2_rev Tag present"
}

shifted_size=0
function read_and_shift_tag_byte() {
  id3=$1
  shift_amount=$2
  character_read_start=$3
  character_read_end=$(($character_read_start+1))
  size=$(echo $id3 | cut -c$character_read_start-$character_read_end)
  debug "Before decode value: $size"
  size=$(hex_str_to_int $size)
  debug "Decimal size before bit shift: $size"
  size=$(($size<<$shift_amount))
  debug "Decimal size after bit shift: $size"
  shifted_size=$size
}

id3v2_size=0
function parse_id3v2_tag_size() {
  id3=$1
  read_and_shift_tag_byte $id3 21 13
  id3v2_size_1=$shifted_size
  read_and_shift_tag_byte $id3 14 15
  id3v2_size_2=$shifted_size
  read_and_shift_tag_byte $id3 7 17
  id3v2_size_3=$shifted_size
  read_and_shift_tag_byte $id3 0 19
  id3v2_size_4=$shifted_size
  id3v2_size=$(($id3v2_size_1+$id3v2_size_2+$id3v2_size_3+$id3v2_size_4))
  id3v2_size_characters=$(($id3v2_size*2))

  debug "Total tag size: $id3v2_size"
}

while [ -n "$1" ]
 do

  file="$1"

  if [ ! -f "$file" ]
  then
    error "File \"$file\" does not exist"
    shift 1
    continue
  fi

  tag=$(tail -c128 "$file" | tr '\0' ' ') # Replace NULL with spaces
  id3=$(head -c10 "$file" | tr '\0' ' ') # NULLs are being omitted

  id3v1_sig=${tag0:3}
  id3v2_sig=${id3:0:3}

  if [ "$id3v1_sig" = "TAG" ]
  then
      debug "ID3v1.x Tag present"
  fi

  if [ "$id3v2_sig" = "ID3" ]
  then
    xxd -p "$file" | tr -d '\n' > .hexdumptmp
    id3=$(head -c$tag_header_size_characters .hexdumptmp)
    print_id3v2_version $id3
    parse_id3v2_tag_size $id3

    i=$frame_header_size_characters
    while [ $i -lt $id3v2_size_characters ]
    do
      frame_header_end_index=$(($i+$frame_header_size_characters))
      debug "Getting header bytes from $i to $frame_header_end_index"

      frame_header_bytes=$(head -c$frame_header_end_index .hexdumptmp | tail -c$frame_header_size_characters)
      debug "Frame header bytes: $frame_header_bytes"

      frame_id_end_index=$i+$frame_id_size
      frame_id=$(echo "${frame_header_bytes:0:8}" | xxd -r -p | tr -d '\0')
      debug "Frame Id: $frame_id"

      frame_size=${frame_header_bytes:8:8}
      debug "Frame size bytes: $frame_size"
      frame_size=$(hex_str_to_int $frame_size)
      debug "Frame Size: $frame_size"
      frame_size_characters=$(($frame_size*2))

      if [ -z "$frame_id" ] || [ $frame_size -eq 0 ]
      then
        error "Bailing early from $file, invalid frame id or frame size"
        break
      fi

      if [[ $frame_id == T* ]]
      then
        frame_body_end_index=$(($frame_header_end_index+$frame_size_characters))
        frame_body_bytes=$(head -c$frame_body_end_index .hexdumptmp | tail -c$frame_size_characters)
        frame_body_text=$(echo $frame_body_bytes | xxd -r -p | tr -d '\0')
        debug "Frame body text: $frame_body_text"

        echo $frame_id $frame_body_text
      fi

      i=$(($i+$frame_header_size_characters+$frame_size_characters))
    done
  elif [ "$id3v1_sig" = "TAG" ]
  then
      song_name=${tag:3:30}
      artist=${tag:33:30}
      album=${tag:63:30}
      year=${tag:93:4}
      comment=${tag:97:28}
      #The second last byte of the Comment field ie the 126th byte of the tag is always zero in ID3v1.1
      album_track=${tag:126:1} #Last two bytes of comment field was reserved for album track no. in ID3v1.1
      album_track=$(hex_str_to_int "'$album_track") #Convert Album Track ASCII to value
      genre=${tag:127:1}
      genre=$(hex_str_to_int "'$genre") #Convert Genre to ASCII value

      #Reads the genre string from the file id3v1_genre_string
      if [ -f id3v1_genre_list ]
      then
        genre_string=$(grep "\<$genre\>" id3v1_genre_list)
      else
        genre_string="Genre Code = $genre"
      fi


      echo -e "Displaying ID3v1 Tag of file \"$file\"\n"
      echo "Song Name   : $song_name"
      echo "Artist      : $artist"
      echo "Album       : $album"
      echo "Year        : $year"
      echo "Comment     : $comment"
      echo "Album Track : $album_track"
      echo "Genre       : $genre_string"

    else
    echo "The file \"$file\" does not contain an ID3v1 tag"
  fi

shift 1
done