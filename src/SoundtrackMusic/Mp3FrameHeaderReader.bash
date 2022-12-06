#!/bin/bash

DEBUG=1

function debug() {
  if [ ! -z "$DEBUG" ] && [ $DEBUG -ne 0 ]
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

declare -A layer_map=(
  [1]=3 # Layer III
  [2]=2 # Layer II
  [3]=1 # Layer I
)

# Constants for sampling rate lookup
# Form of  (sampling_rate_index)_(mpeg_version)
# for simplicity mpeg 2.5 is 3 in the map
declare -A sampling_rate_map=(
  ["0_1"]=44100 # index 0 mpeg 1
  ["0_2"]=22050 # index 0 mpeg 2
  ["0_3"]=11025 # index 0 mpeg 2.5

  ["1_1"]=48000 # index 1 mpeg 1
  ["1_2"]=24000 # index 1 mpeg 2
  ["1_3"]=12000 # index 1 mpeg 2.5

  ["2_1"]=32000 # index 2 mpeg 1
  ["2_2"]=16000 # index 2 mpeg 2
  ["2_3"]=8000 # index 2 mpeg 2.5
)

# Constants for bit rate lookup
# Form of  (bit_rate_index)_(mpeg_version)_(layer)
# for simplicity mpeg 2.5 is 3 in the map
declare -A bit_rate_map=(
  ["1_1_1"]=32 ["1_1_2"]=32 ["1_1_3"]=32 ["1_2_1"]=32 ["1_2_2"]=8 ["1_2_3"]=8 ["1_3_1"]=32 ["1_3_2"]=8 ["1_3_3"]=8
  ["2_1_1"]=64 ["2_1_2"]=48 ["2_1_3"]=40 ["2_2_1"]=48 ["2_2_2"]=16 ["2_2_3"]=16 ["2_3_1"]=48 ["2_3_2"]=16 ["2_3_3"]=16
  ["3_1_1"]=96 ["3_1_2"]=56 ["3_1_3"]=48 ["3_2_1"]=56 ["3_2_2"]=24 ["3_2_3"]=24 ["3_3_1"]=56 ["3_3_2"]=24 ["3_3_3"]=24
  ["4_1_1"]=128 ["4_1_2"]=64 ["4_1_3"]=56 ["4_2_1"]=64 ["4_2_2"]=32 ["4_2_3"]=32 ["4_3_1"]=64 ["4_3_2"]=63 ["4_3_3"]=32
  ["5_1_1"]=160 ["5_1_2"]=80 ["5_1_3"]=64 ["5_2_1"]=80 ["5_2_2"]=40 ["5_2_3"]=40 ["5_3_1"]=80 ["5_3_2"]=40 ["5_3_3"]=40
  ["6_1_1"]=192 ["6_1_2"]=96 ["6_1_3"]=80 ["6_2_1"]=96 ["6_2_2"]=48 ["6_2_3"]=48 ["6_3_1"]=96 ["6_3_2"]=48 ["6_3_3"]=48
  ["7_1_1"]=224 ["7_1_2"]=112 ["7_1_3"]=96 ["7_2_1"]=112 ["7_2_2"]=56 ["7_2_3"]=56 ["7_3_1"]=112 ["7_3_2"]=56 ["7_3_3"]=56
  ["8_1_1"]=256 ["8_1_2"]=128 ["8_1_3"]=112 ["8_2_1"]=128 ["8_2_2"]=64 ["8_2_3"]=64 ["8_3_1"]=128 ["8_3_2"]=64 ["8_3_3"]=64
  ["9_1_1"]=288 ["9_1_2"]=160 ["9_1_3"]=128 ["9_2_1"]=144 ["9_2_2"]=80 ["9_2_3"]=80 ["9_3_1"]=144 ["9_3_2"]=80 ["9_3_3"]=80
  ["10_1_1"]=320 ["10_1_2"]=192 ["10_1_3"]=160 ["10_2_1"]=160 ["10_2_2"]=96 ["10_2_3"]=96 ["10_3_1"]=160 ["10_3_2"]=96 ["10_3_3"]=96
  ["11_1_1"]=352 ["11_1_2"]=224 ["11_1_3"]=192 ["11_2_1"]=176 ["11_2_2"]=112 ["11_2_3"]=112 ["11_3_1"]=176 ["11_3_2"]=112 ["11_3_3"]=112
  ["12_1_1"]=384 ["12_1_2"]=256 ["12_1_3"]=224 ["12_2_1"]=192 ["12_2_2"]=128 ["12_2_3"]=128 ["12_3_1"]=192 ["12_3_2"]=128 ["12_3_3"]=128
  ["13_1_1"]=416 ["13_1_2"]=320 ["13_1_3"]=256 ["13_2_1"]=224 ["13_2_2"]=144 ["13_2_3"]=144 ["13_3_1"]=224 ["13_3_2"]=144 ["13_3_3"]=144
  ["14_1_1"]=448 ["14_1_2"]=384 ["14_1_3"]=320 ["14_2_1"]=256 ["14_2_2"]=160 ["14_2_3"]=160 ["14_3_1"]=256 ["14_3_2"]=160 ["14_3_3"]=160
)

file=$1

if [ ! -f "$file" ]
then
  error "File \"$file\" does not exist"
fi

# Constants
frame_header_byte_size=4
frame_header_size_characters=$(($frame_header_byte_size * 2))

xxd -p "$file" | tr -d '\n' > .hexdumptmp

file_size_characters=$(wc -c < .hexdumptmp)
debug "File size in characters: $file_size_characters"

i=0;
while [ $i -lt $file_size_characters ]
do
  #debug "-------------Start Frame----------------"
  #debug "Character index: $i"

  frame_header_end_index=$(($i + $frame_header_size_characters))
  frame_header_hex=$(head -c$frame_header_end_index .hexdumptmp | tail -c$frame_header_size_characters)


  sync_word=${frame_header_hex:0:3}
  #debug "Sync word: $sync_word"

  if [[ $sync_word == fff ]] || [[ $sync_word == ffe ]]
  then
    debug "Found potential mp3 frame: $sync_word at character $i"
    debug "  Potential Frame header: $frame_header_hex"

    # Hex character 4 represents: 1 bit for MPEG version, 2 bits for Layer index, 1 bit for protection
    {
      hex_character_four=${frame_header_hex:3:1}
      character_four_int=$(hex_str_to_int $hex_character_four)

      mpeg_version_bit=$((($character_four_int & 2#1000) >> 3))

      layer_index=$((($character_four_int & 2#0110) >> 1))
      layer="${layer_map[$layer_index]}"

      protected=$(($character_four_int & 2#0001))
    }

    # Hex character 5 represents: Bit rate index, need to lookup value into table of constants
    {
      bit_rate_hex=${frame_header_hex:4:1}
    }

    # Hex character 6 represents: 2 bits for sampling rate index, 1 bit for padding, 1 bit for private bit
    {
      hex_character_six=${frame_header_hex:5:1}
      character_six_int=$(hex_str_to_int $hex_character_six)

      sampling_rate_index=$((($character_six_int & 2#1100) >> 2))
      sampling_rate_key="${sampling_rate_index}_${mpeg_version_bit}"
      sampling_rate=${sampling_rate_map[$sampling_rate_key]}

      padding_bit=$((($character_six_int & 2#0010) >> 1))

      private_bit=$(($character_six_int & 2#0001))
    }

    # Hex character 7 represents: 2 bits for channel mode, 2 bits for mode extension
    {
      hex_character_seven=${frame_header_hex:6:1}
      character_seven_int=$(hex_str_to_int $hex_character_seven)

      channel_mode=$((($character_seven_int & 2#1100) >> 2))

      channel_mode_extension=$(($character_seven_int & 2#0011))
    }

    # Hex character 8 represents: 1 bit for copyright, 1 bit for original, 2 bits for emphasis
    {
      hex_character_eight=${frame_header_hex:6:1}
      character_eight_int=$(hex_str_to_int $hex_character_eight)

      copyright_bit=$((($character_eight_int & 2#1000) >> 3))

      original_bit=$((($character_eight_int & 2#0100) >> 2))

      emphasis=$(($character_eight_int & 2#0011))
    }

    debug "  ($hex_character_four) MPEG version: $mpeg_version_bit, Layer: $layer, Protected: $protected"
    debug "  ($bit_rate_hex) Bit rate hex: $bit_rate_hex"
    debug "  ($hex_character_six) Sampling rate: (key = $sampling_rate_key) ${sampling_rate}Hz, Padding: $padding_bit, Private: $private_bit"
    debug "  ($hex_character_seven) Channel mode: $channel_mode, Channel mode extension: $channel_mode_extension"
    debug "  ($hex_character_eight) Copyright: $copyright_bit, Original: $original_bit, Emphasis: $emphasis"

    if [ $mpeg_version_bit -ne 1 ] || [ $layer -eq 0 ]
    then
      debug "  This is not an mpeg1 frame header, moving to next word boundary"
      i=$(($i + 4))
      continue
    fi

    exit
  else
    # Seek to the next word boundary
    i=$(($i + 4))
  fi

  #debug "-------------End Frame----------------"
done
