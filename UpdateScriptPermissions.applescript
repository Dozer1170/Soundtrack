set pathToMe to �
	quoted form of �
	POSIX path of �
	(path to me)

set updateExecutePerms to �
	{"cd $(dirname ", pathToMe, �
		"); chmod u+x ./GenerateMyLibrary.command ./Mp3FrameHeaderReader.bash ./Id3TagReader.bash;"} as string

do shell script updateExecutePerms

