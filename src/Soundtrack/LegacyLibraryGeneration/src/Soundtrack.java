import java.io.BufferedWriter;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.channels.FileChannel;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.sound.sampled.UnsupportedAudioFileException;

import javazoom.spi.mpeg.sampled.convert.MpegFormatConversionProvider;
import tag.MpegInfo;
import tag.OggVorbisInfo;

/**
 * Soundtrack.java
 * @author Lunaqua
 * Holds the Soundtrack and SoundtrackMusic directories
 */
public class Soundtrack {
    private File musicDir;
    private boolean wrongFolder;
    private int musicCount;
    private int folderCount;
    private javax.swing.JTextArea TextArea;
    private String libraryErrors = "";

    /**
     * Creates a Soundtrack object with a JTextArea to log to.
     * @param jta JTextArea for logging
     */
    public Soundtrack(javax.swing.JTextArea jta){
        setDirectories();
        resetCounts();
        setTextArea(jta);
    }

    /**
     * Sets the Soundtrack and SoundtrackMusic directories,
     * sets wrongFolder to true if Soundtrack is not in AddOns folder.
     */
    private void setDirectories(){
        wrongFolder = false;

        String curDir = System.getProperty("user.dir");
        curDir = curDir.replace("\\LegacyLibraryGeneration", "");

        // Check if Soundtrack is in Addons folder
        if(!curDir.toLowerCase().endsWith("addons\\soundtrackmusic")){
            wrongFolder = true;
        }

        musicDir = new File(curDir);
        if(!musicDir.exists()) {
            musicDir.mkdir();
        }
    }

    /**
     * Returns the SoundtrackMusic directory as a File object.
     * @return SoundtrackMusic directory
     */
    public File getMusicDir(){
        return musicDir;
    }

    /**
     * Returns folder count.
     * @return foldercount
     */
    public int getFolderCount(){
        return folderCount;
    }

    /**
     * Returns mp3 count.
     * @return mp3Count
     */
    public int getMusicCount(){
        return musicCount;
    }

    /**
     * Resets the counters.
     */
    public void resetCounts(){
        musicCount = 0;
        folderCount = 0;
    }

    /**
     * Returns if Soundtrack is not in AddOns folder.
     * @return wrongFolder
     */
    public boolean getWrongFolder(){
        return wrongFolder;
    }

    /**
     * Sets the TextArea for logging.
     * @param jta JTextArea
     */
    private void setTextArea(javax.swing.JTextArea jta){
        TextArea = jta;
    }
    
    private boolean isValidFile(File src) {
        String filename = src.getName().toUpperCase();
        return filename.endsWith(".MP3") || filename.endsWith(".OGG") || 
                filename.endsWith(".TOC");
    }
    
    private boolean isMusicFile(File src) {
        String filename = src.getName().toUpperCase();
        return filename.endsWith(".MP3") || filename.endsWith(".OGG");
    }
    
    private String getMusicFilepath(File src) {
        String filePath = src.getPath();
        filePath = filePath.substring(musicDir.getPath().length()+1);
        for(int i=0; i<filePath.length(); i++){
            if (filePath.charAt(i) == '\\') {
                StringBuffer sb = new StringBuffer(filePath);
                sb.insert(i, "\\");
                filePath = sb.toString();
                i++;
            }
        }
        filePath = filePath.substring(0, filePath.length()-4);
        return filePath;
    }
    
    private String getMusicTitle(File src) throws IOException, UnsupportedAudioFileException{
        String ext = src.getName().toUpperCase();
        String title = "";
        
        if (ext.endsWith(".MP3")){
            MpegInfo mp3i = new MpegInfo();
            mp3i.load(src);
            title = mp3i.getTitle();
        } else if (ext.endsWith(".OGG")){
            OggVorbisInfo oggi = new OggVorbisInfo();
            oggi.load(src);
            title = oggi.getTitle();
        }
        
        if (title == null || title.equals("")){
            title = src.getName().substring(0, src.getName().length()-4);
        }
        for(int i=0; i<title.length(); i++){
            if (title.charAt(i) == '\"') {
                StringBuffer sb = new StringBuffer(title);
                sb.insert(i, "\\");
                title = sb.toString();
                i++;
            }
        }
        
        return title;
    }
    
    private String getMusicArtist(File src) throws IOException, UnsupportedAudioFileException{
        String ext = src.getName().toUpperCase();
        String artist = "";
        
        if (ext.endsWith(".MP3")) {
            MpegInfo mp3i = new MpegInfo();
            mp3i.load(src);
            artist = mp3i.getArtist();
        } else if (ext.endsWith(".OGG")){
            OggVorbisInfo oggi = new OggVorbisInfo();
            oggi.load(src);
            artist = oggi.getArtist();
        }
        
        if (artist == null || artist.equals("")){
            artist = "null";
        }
        for(int i=0; i<artist.length(); i++){
            if (artist.charAt(i) == '\"') {
                StringBuffer sb = new StringBuffer(artist);
                sb.insert(i, "\\");
                artist = sb.toString();
                i++;
            }
        }
        
        return artist;
    }
    
    private String getMusicAlbum(File src) throws IOException, UnsupportedAudioFileException{
        String ext = src.getName().toUpperCase();
        String album = "";
        
        if (ext.endsWith(".MP3")) {
            MpegInfo mp3i = new MpegInfo();
            mp3i.load(src);
        } else if (ext.endsWith(".OGG")) {
            OggVorbisInfo oggi = new OggVorbisInfo();
            oggi.load(src);
            album = oggi.getAlbum();
        }
        
        if (album == null || album.equals("")){
            File parent = new File(src.getParent());
            album = parent.toString().substring(parent.getParent().length()+1);
        }
        for(int i=0; i<album.length(); i++){
            if (album.charAt(i) == '\"') {
                StringBuffer sb = new StringBuffer(album);
                sb.insert(i, "\\");
                album = sb.toString();
                i++;
            }
        }
        
        return album;
    }
    
    private int getMusicLength(File src) throws IOException, UnsupportedAudioFileException{
        String ext = src.getName().toUpperCase();
        int length = 0;
        
        if (ext.endsWith(".MP3")) {
            MpegInfo mp3i = new MpegInfo();
            mp3i.load(src);
            length = (int) mp3i.getPlayTime();
            if (length == 0) {
                length = 1;
            }
        } else if (ext.endsWith(".OGG")){
            OggVorbisInfo oggi = new OggVorbisInfo();
            oggi.load(src);
            length = (int) oggi.getPlayTime();
            if (length == 0) {
                length = 1;
            }
        }
        
        return length;
    }
    
    
    
    /**
     * Copies files from strpath to dstpath.
     * NB: Call resetCounts() before this function.
     * @param srcPath String source path for files/folders to copy
     * @param dstPath String copy destination path
     */
    public void addFiles(String srcPath, String dstPath){
        resetCounts();
        final String src = srcPath;
        final String dst = dstPath;
        class ThreadAddFiles implements Runnable{
            @Override
            public void run(){
                threadAddFiles(src, dst);
                log("--- --- ---");
                log(musicCount + " music files added.");
                log(folderCount+" folders added.");
            }
        }
        Runnable runnable = new ThreadAddFiles();
        Thread thread = new Thread(runnable);
        thread.start();
    }

    /**
     * Copies files from strpath to dstpath.
     * Called in addFiles().
     * @param srcPath String source path for files/folders to copy
     * @param dstPath String copy destination path
     */
    private void threadAddFiles(String srcPath, String dstPath) {

        File src = new File(srcPath);
        File dest = new File(dstPath);

        if (src.isDirectory()) {
            boolean created = dest.mkdirs();
            String list[] = src.list();
            folderCount++;
            for (int i = 0; i < list.length; i++) {
                String dest1 = dest.getAbsolutePath() + File.separator + list[i];
                String src1 = src.getAbsolutePath() + File.separator + list[i];
                threadAddFiles(src1, dest1);
            }
        } else {
            try {
                if (isValidFile(src)) {
                    if(isMusicFile(src)){
                        log("Copying " + src.getName() + "   (" + src.getPath() + ")");
                        musicCount++;
                    }
                    FileChannel sourceChannel = new FileInputStream(src).getChannel();
                    FileChannel targetChannel = new FileOutputStream(dest).getChannel();
                    sourceChannel.transferTo(0, sourceChannel.size(), targetChannel);
                    sourceChannel.close();
                    targetChannel.close();
                } else {
                    log("Error: Cannot add "+src.getName());
                }

            } catch (IOException ex) {
                Logger.getLogger(Soundtrack.class.getName()).log(Level.SEVERE, null, ex);
            }
        }
    }

    
    
    
    /**
     * Deletes the files at srcPath.
     * NB: Call resetCounts() before this function.
     * @param srcPath String source path
     */
    public void deleteFiles(String srcPath) {
        resetCounts();
        final String src = srcPath;
        class ThreadDeleteFiles implements Runnable {
            public void run() {
                threadDeleteFiles(src);
                log("--- --- ---");
                log(musicCount + " music files deleted.");
                log(folderCount+" folders deleted.");
            }
        }
        Runnable runnable = new ThreadDeleteFiles();
        Thread thread = new Thread(runnable);
        thread.start();
    }

    /**
     * Deletes the files at the strpath.
     * Called in deleteFiles().
     * @param strPath delete path
     */
    private void threadDeleteFiles(String strPath){

        File src = new File(strPath);

        if (src.isDirectory()) {
            String list[] = src.list();

            for (int i = 0; i < list.length; i++) {
                String src1 = src.getAbsolutePath() + File.separator + list[i];
                deleteFiles(src1);
                folderCount++;
                src.delete();
            }
        } else {
            if (isMusicFile(src)) {
                log("Deleting " + src.getName() + "   (" + src.getPath() + ")");
                musicCount++;
                src.delete();
            } 
        }
    }

    

    /**
     * Generates MyTracks.lua
     */
    public void generateMyLibrary() {
        resetCounts();
        String mytracks = musicDir + "\\MyTracks.lua";
        libraryErrors = "";
        try{
            // Create file
            FileWriter fstream = new FileWriter(mytracks);
            final BufferedWriter out = new BufferedWriter(fstream);
            final File source = musicDir;
            class ThreadGenMyLib implements Runnable {
                public void run() {
                    try {
                        log("Starting MyTracks.lua");
                        out.write("-- This file is automatically generated\n");
                        out.write("-- Please do not edit it.\n");
                        out.write("function Soundtrack_LoadMyTracks()\n");
                        threadWriteTracks(source, out);
                        out.write("end\n");
                        out.close();
                        log("--- --- ---");
                        log("MyTracks.lua COMPLETE!");
                        log("Number of tracks: " + musicCount);
                    } catch (IOException ex) {
                        log("Error: " + ex.toString());
                        Logger.getLogger(Soundtrack.class.getName()).log(Level.SEVERE, null, ex);
                    } catch (UnsupportedAudioFileException ex) {
                        log("Error: " + ex.toString());
                        Logger.getLogger(Soundtrack.class.getName()).log(Level.SEVERE, null, ex);
                    }
                }
            }
            Runnable runnable = new ThreadGenMyLib();
            Thread thread = new Thread(runnable);
            thread.start();
        }catch (Exception e){//Catch exception if any
            log("Error@generateMyLibrary: " + e.getMessage());
        }
    }

    /**
     * Writes tracks to MyTracks.lua, called in generateMyLibrary
     * @param src source file/folder
     * @param out file to write to
     * @throws IOException
     * @throws UnsupportedAudioFileException
     */
    private void threadWriteTracks(File src, BufferedWriter out)
            throws IOException, UnsupportedAudioFileException {
        if (src.isDirectory()) {
            String list[] = src.list();
            for(int i=0; i<list.length; i++){
                String nextSrcPath = src.getAbsolutePath() + File.separator + list[i];
                File nextSrc = new File(nextSrcPath);
                threadWriteTracks(nextSrc, out);
            }
        }else {
            if (isMusicFile(src)) {
                //log("--- --- ---");
                // Get file path
                String filePath = getMusicFilepath(src);
                /*
                String filePath = src.getPath();
                filePath = filePath.substring(musicDir.getPath().length()+1);
                for(int i=0; i<filePath.length(); i++){
                    if (filePath.charAt(i) == '\\') {
                        StringBuffer sb = new StringBuffer(filePath);
                        sb.insert(i, "\\");
                        filePath = sb.toString();
                        i++;
                    }
                }
                filePath = filePath.substring(0, filePath.length()-4);
                */
                
                // Get title
                String title = getMusicTitle(src);
                /*
                String title = mp3i.getTitle();
                if (title == null || title.equals("")){
                    title = src.getName().substring(0, src.getName().length()-4);
                }
                for(int i=0; i<title.length(); i++){
                    if (title.charAt(i) == '\"') {
                        StringBuffer sb = new StringBuffer(title);
                        sb.insert(i, "\\");
                        title = sb.toString();
                        i++;
                    }
                }
                */
                
                // Get artist
                String artist = getMusicArtist(src);
                /*
                String artist = mp3i.getArtist();
                if (artist == null || artist.equals("")){
                    artist = "null";
                }
                for(int i=0; i<artist.length(); i++){
                    if (artist.charAt(i) == '\"') {
                        StringBuffer sb = new StringBuffer(artist);
                        sb.insert(i, "\\");
                        artist = sb.toString();
                        i++;
                    }
                }
                */

                // Get album
                String album = getMusicAlbum(src);
                /*
                String album = mp3i.getAlbum();
                if (album == null || album.equals("")){
                    File parent = new File(src.getParent());
                    album = parent.toString().substring(parent.getParent().length()+1);
                }
                for(int i=0; i<album.length(); i++){
                    if (album.charAt(i) == '\"') {
                        StringBuffer sb = new StringBuffer(album);
                        sb.insert(i, "\\");
                        album = sb.toString();
                        i++;
                    }
                }
                */
                
                // Get length
                int length = getMusicLength(src);
                /*
                int length = (int) mp3i.getPlayTime();
                if (length == 0) {
                    length = 1;
                }
                */

                musicCount++;
                out.write("    Soundtrack.Library.AddTrack(\""+filePath+"\","+length+",\""
                        +title+"\",\""+artist+"\",\""+album+"\")\n");
                log(musicCount + ". " + filePath + ": " + title + ", " + artist + ", " + album + ", "
                        + length + "s");
            } else if (!src.getPath().contains("LegacyLibraryGeneration")) {
                //log("--- --- ---");
                log("ERROR: Cannot add "+src.getPath());
                libraryErrors = libraryErrors + src.getPath() + "\n";
            }
        }
    }



    /**
     * Generates DefaultTracks.lua
     */
    public void generateDefaultLibrary() {
        resetCounts();
        String defaulttracks = musicDir+"\\DefaultTracks.lua";
        libraryErrors = "";
        try{
            // Create file
            FileWriter fstream = new FileWriter(defaulttracks);
            final BufferedWriter out = new BufferedWriter(fstream);
            final File source = musicDir;
            class ThreadGenDefaultLib implements Runnable {
                public void run() {
                    try {
                        log("Starting DefaultTracks.lua");
                        out.write("function Soundtrack_LoadDefaultTracks()\n");
                        threadWriteDefaultTracks(source, out);
                        out.write("   Soundtrack.SortTracks()\n");
                        out.write("end\n");
                        out.close();
                        log("--- --- ---");
                        log("DefaultTracks.lua COMPLETE!");
                        log("Number of tracks: " + musicCount);
                    } catch (IOException ex) {
                        Logger.getLogger(Soundtrack.class.getName()).log(Level.SEVERE, null, ex);
                    } catch (UnsupportedAudioFileException ex) {
                        Logger.getLogger(Soundtrack.class.getName()).log(Level.SEVERE, null, ex);
                    }
                }
            }
            Runnable runnable = new ThreadGenDefaultLib();
            Thread thread = new Thread(runnable);
            thread.start();
        }catch (Exception e){//Catch exception if any
            log("Error@generateDefaultLibrary: " + e.getMessage());
        }
    }

    /**
     * Writes tracks to DefaultTracks.lua, called in generateMyLibrary
     * @param src source file/folder
     * @param out file to write to
     * @throws IOException
     * @throws UnsupportedAudioFileException
     */
    private void threadWriteDefaultTracks(File src, BufferedWriter out)
            throws IOException, UnsupportedAudioFileException {
        if (src.isDirectory()) {
            String list[] = src.list();
            for(int i=0; i<list.length; i++){
                String nextSrcPath = src.getAbsolutePath() + File.separator + list[i];
                File nextSrc = new File(nextSrcPath);
                threadWriteDefaultTracks(nextSrc, out);
            }
        }else {
            if (isMusicFile(src)) {
                log("--- --- ---");
                
                // Get filepath
                String filePath = getMusicFilepath(src);
                /*
                String filePath = src.getPath();
                filePath = filePath.substring(musicDir.getPath().length()+1);
                for(int i=0; i<filePath.length(); i++){
                    if (filePath.charAt(i) == '\\') {
                        StringBuffer sb = new StringBuffer(filePath);
                        sb.insert(i, "\\");
                        filePath = sb.toString();
                        i++;
                    }
                }
                filePath = filePath.substring(0, filePath.length()-4);
                */
                
                // Get title
                String title = getMusicTitle(src);
                /*
                String title = mp3i.getTitle();
                if (title == null || title.equals("")){
                    title = src.getName().substring(0, src.getName().length()-4);
                }
                for(int i=0; i<title.length(); i++){
                    if (title.charAt(i) == '\"') {
                        StringBuffer sb = new StringBuffer(title);
                        sb.insert(i, "\\");
                        title = sb.toString();
                        i++;
                    }
                }
                */
                
                // Get artist
                String artist = getMusicArtist(src);
                /*
                String artist = mp3i.getArtist();
                if (artist == null || artist.equals("")){
                    artist = "null";
                }
                for(int i=0; i<artist.length(); i++){
                    if (artist.charAt(i) == '\"') {
                        StringBuffer sb = new StringBuffer(artist);
                        sb.insert(i, "\\");
                        artist = sb.toString();
                        i++;
                    }
                }
                */

                // Get album
                String album = getMusicAlbum(src);
                /*
                String album = mp3i.getAlbum();
                if (album == null || album.equals("")){
                    File parent = new File(src.getParent());
                    album = parent.toString().substring(parent.getParent().length()+1);
                }
                for(int i=0; i<album.length(); i++){
                    if (album.charAt(i) == '\"') {
                        StringBuffer sb = new StringBuffer(album);
                        sb.insert(i, "\\");
                        album = sb.toString();
                        i++;
                    }
                }
                */
                
                // Get length
                int length = getMusicLength(src);
                /*
                int length = (int) mp3i.getPlayTime();
                if (length == 0) {
                    length = 1;
                }
                */

                musicCount++;
                out.write("    Soundtrack.Library.AddDefaultTrack(\""+filePath+"\","+length+",\""
                        +title+"\",\""+artist+"\",\""+album+"\")\n");
                log(musicCount + ": " + filePath + " = \"" + title + "\"; \"" + artist + "\"; \"" + album + "\"; "
                        + length + " seconds");
            } else {
                log("--- --- ---");
                log("ERROR: Cannot add "+src.getPath());
                libraryErrors = libraryErrors + src.getPath() + "\n";
            }
        }
    }


    /**
     * Generates DefaultSounds.lua
     */
    public void generateSoundsLibrary() {
        resetCounts();
        String mytracks = musicDir+"\\DefaultSounds.lua";
        libraryErrors = "";
        try{
            // Create file
            FileWriter fstream = new FileWriter(mytracks);
            final BufferedWriter out = new BufferedWriter(fstream);
            final File source = musicDir;
            class ThreadGenSoundsLib implements Runnable {
                public void run() {
                    try {
                        log("Starting DefaultSounds.lua");
                        out.write("function Soundtrack_LoadDefaultSounds()\n");
                        threadWriteOggTracks(source, out);
                        out.write("   Soundtrack.SortTracks()\n");
                        out.write("end\n");
                        out.close();
                        log("--- --- ---");
                        log("DefaultSounds.lua COMPLETE!");
                        log("Number of tracks: " + musicCount);
                    } catch (IOException ex) {
                        Logger.getLogger(Soundtrack.class.getName()).log(Level.SEVERE, null, ex);
                    } catch (UnsupportedAudioFileException ex) {
                        Logger.getLogger(Soundtrack.class.getName()).log(Level.SEVERE, null, ex);
                    }
                }
            }
            Runnable runnable = new ThreadGenSoundsLib();
            Thread thread = new Thread(runnable);
            thread.start();
        }catch (Exception e){//Catch exception if any
            log("Error@generateDefaultLibrary: " + e.getMessage());
        }
    }

    /**
     * Writes OGG files to DefaultSounds.lua. 
     * @param src source file
     * @param out file to write to
     * @throws IOException
     * @throws UnsupportedAudioFileException
     */
    private void threadWriteOggTracks(File src, BufferedWriter out)
            throws IOException, UnsupportedAudioFileException {
        if (src.isDirectory()) {
            String list[] = src.list();
            for(int i=0; i<list.length; i++){
                String nextSrcPath = src.getAbsolutePath() + File.separator + list[i];
                File nextSrc = new File(nextSrcPath);
                threadWriteTracks(nextSrc, out);
            }
        }else {
            String ext = src.getName().toUpperCase();
            log(ext);
            if (ext.endsWith(".OGG")) {
                log("--- --- ---");
                
                // Get filepath
                String filePath = getMusicFilepath(src);
                /*
                String filePath = src.getPath();
                filePath = filePath.substring(musicDir.getPath().length()+1);
                for(int i=0; i<filePath.length(); i++){
                    if (filePath.charAt(i) == '\\') {
                        StringBuffer sb = new StringBuffer(filePath);
                        sb.insert(i, "\\");
                        filePath = sb.toString();
                        i++;
                    }
                }
                filePath = filePath.substring(0, filePath.length()-4);
                */
                
                // Get title
                String title = getMusicTitle(src);
                /*
                String title = oggi.getTitle();
                if (title == null || title.equals("")){
                    title = src.getName().substring(0, src.getName().length()-4);
                }
                for(int i=0; i<title.length(); i++){
                    if (title.charAt(i) == '\"') {
                        StringBuffer sb = new StringBuffer(title);
                        sb.insert(i, "\\");
                        title = sb.toString();
                        i++;
                    }
                }
                */

                // Get artist
                String artist = getMusicArtist(src);
                /*
                String artist = oggi.getArtist();
                if (artist == null || artist.equals("")){
                    artist = "null";
                }
                for(int i=0; i<artist.length(); i++){
                    if (artist.charAt(i) == '\"') {
                        StringBuffer sb = new StringBuffer(artist);
                        sb.insert(i, "\\");
                        artist = sb.toString();
                        i++;
                    }
                }
                */
                
                // Get album
                String album = getMusicAlbum(src);
                /*
                String album = oggi.getAlbum();
                if (album == null || album.equals("")){
                    File parent = new File(src.getParent());
                    album = parent.toString().substring(parent.getParent().length()+1);
                }
                for(int i=0; i<album.length(); i++){
                    if (album.charAt(i) == '\"') {
                        StringBuffer sb = new StringBuffer(album);
                        sb.insert(i, "\\");
                        album = sb.toString();
                        i++;
                    }
                }
                */
                
                // Get length
                int length = getMusicLength(src);
                /*
                int length = (int) oggi.getPlayTime();
                if (length == 0) {
                    length = 1;
                }
                */
                
                musicCount++;
                out.write("    Soundtrack.Library.AddDefaultSound(\""+filePath+"\","+length+",\""
                        +title+"\",\""+artist+"\",\""+album+"\")\n");
                log(musicCount + ": " + filePath + " = \"" + title + "\"; \"" + artist + "\"; \"" + album + "\"; "
                        + length + " seconds");
            } else {
                log("--- --- ---");
                log("ERROR: Cannot add "+src.getPath());
                libraryErrors = libraryErrors + src.getPath() + "\n";
            }
        }
    }
    

    /**
     * Logs a string to the TextArea.
     * @param str string to log
     */
    public void log(String str) {
        TextArea.append(str+"\n");
        TextArea.validate();
    }

    /**
     * Lists file errors from the last run of generate library.
     */
    public void getGenLibErrors() {
        //log("--- --- ---");
        log("ERROR FILES:");
        log(libraryErrors);
    }

} // end of class