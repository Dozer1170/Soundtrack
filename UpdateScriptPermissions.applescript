set pathToMe to Â
	quoted form of Â
	POSIX path of Â
	(path to me)

set updateExecutePerms to Â
	{"cd $(dirname ", pathToMe, Â
		"); chmod u+x ./GenerateMyLibrary.command ./Mp3FrameHeaderReader.bash ./Id3TagReader.bash;"} as string

do shell script updateExecutePerms

