Quick Setup

NOTE: MyTracks.lua GENERATION PROCESS HAS CHANGED 12/5/2022. You no longer need to copy MyTracks.lua to the Soundtrack folder,
and you don't need to install java or python to run the tools. 

1. Create a folder named SoundtrackMusic in the Addons folder.
   (World of Warcraft\_retail\Interface\AddOns\SoundtrackMusic)

2. Copy your mp3s to that folder, and close WoW if it's already open. 
   Files added while WoW is running won't be noticed until you restart it.
   You can organize your music into subfolders, e.g. 
    \SoundtrackMusic\Lord of the Rings\
    \SoundtrackMusic\Pokemon\
    \SoundtrackMusic\Public Enemy\
    and so on.

3. To make your mp3s available in the game:
    a. Windows: Run GenerateMyLibrary.ps1 (Right click -> Run with Powershell)
    b. Mac/Linux: Run GenerateMyLibrary.bash (In terminal, cd to your SoundtrackMusic directory then run "bash GenerateMyLibrary.bash").

    You should now have a MyTracks.lua file in your SoundtrackMusic directory. If so then you are good to go!

Troubleshooting steps for powershell (credit Mrwario52):
1. Start menu -> type powershell -> right click powershell and select Run as administrator.
2. Check the current script execution policy by using the Get-ExecutionPolicy cmdlet. To do this, input “Get-ExecutionPolicy” (without quotes) and press Enter on your keyboard. PowerShell may return a value of Restricted.
3. To change the script execution policy, use the Set-ExecutionPolicy cmdlet. Input “Set-ExecutionPolicy unrestricted” (without quotes) and press Enter on your keyboard.
4. To ensure that the script execution policy has been changed, use the Get-ExecutionPolicy cmdlet again. PowerShell should return a value of Unrestricted.
5. You should now be able to run your PowerShell scripts.
6. Find where you music addon is for me its C:\World of Warcraft\_retail_\Interface\AddOns\Soundtrack
7. Type cd "C:\World of warcraft_retail\Interface\AddOns\Soundtrack" (or where ever your folder is located)
8. Now type .\GenerateMyLibrary.ps1
9. If it succeeds, then in the future you can just right click -> run with powershell on GenerateMyLibrary.ps1
10. If you are still having issues make a post on the curseforge page for help: https://www.curseforge.com/wow/addons/soundtrack/comments