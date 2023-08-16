#!/usr/bin/python

import sys;

community_list_filename = sys.argv[1]
default_tracks_filename = sys.argv[2]
output_file = sys.argv[3]

print(f'Loading {community_list_filename} and {default_tracks_filename}')

music_files = []

with open(community_list_filename) as file:
    for line in file:
        if line.find('sound/music') > 0:
            music_files.append(line)

print(f'Found {len(music_files)} music files')

def matches_track_name(music_file_line, default_track_line):
    music_split_by_slashes = music_file_line.split('/')
    last_slash = music_split_by_slashes[len(music_split_by_slashes) - 1]
    music_track_name = last_slash.split('.')[0].replace(' ', '')

    full_default_track_path = default_track_line.split('"')[1]
    track_split_by_backslash = full_default_track_path.split('\\')
    default_track_name = track_split_by_backslash[len(track_split_by_backslash) - 1]

    return music_track_name == default_track_name


print(f'Patching track ids in {default_tracks_filename}')
new_file = []

with open(default_tracks_filename) as file:
    for line in file:
        if line.find('Soundtrack.Library.AddDefaultTrack') == -1:
            new_file.append(line)
            continue

        matching_id_line = next((x for x in music_files if matches_track_name(x, line)), None)
        if matching_id_line is None:
            print(f"No matching track for {line}")
        else:
            file_data_id = matching_id_line.split(';')[0]

            index = line.find('",')
            adjusted_line = line[:index] + f"////{file_data_id}" + line[index:]
            new_file.append(adjusted_line)

with open(output_file, "w") as file:
    file.writelines(new_file)

print(f"Output file to {output_file}")
