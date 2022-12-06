
import java.io.File;
import java.io.IOException;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.swing.JFileChooser;
import javax.swing.JOptionPane;

/**
 * SoundtrackMusicGUI.java
 * @author Lunaqua
 * @credits yess
 * Main frame for Soundtrack Music Manager
 */
public class MusicManager extends javax.swing.JFrame {

    private Junction junc;
    private Soundtrack st;
    private File curAddDir;
    private boolean enableJunc;


    /** Creates new form SoundtrackMusicGUI */
    public MusicManager(){
        initComponents();

        try {junc = new Junction(TextArea);}
        catch (Exception ex) {Logger.getLogger(MusicManager.class.getName()).log(Level.SEVERE, null, ex);}
        enableJunc = junc.osSupportsJunctions();
        EnableJunctions.setEnabled(enableJunc);
        st = new Soundtrack(TextArea);

        if(st.getWrongFolder()){
            JOptionPane.showMessageDialog(this,
                    "SoundtrackMusic addon is in " + st.getMusicDir() + ".\n" +
                    "SoundtrackMusic addon must be in your World of Warcraft\\(_retail_ or _classic_)\\Interface\\Addons.\n\n" +
                    "Please move SoundtrackMusic to the correct folder, then run Music Manager.",
                    "SoundtrackMusic in wrong location", JOptionPane.ERROR_MESSAGE);
            System.exit(0);
        }
        String junctions = "Junctions disabled (not supported by operating system).\n";
        if (enableJunc) {
            junctions = "Junctions disabled. Click Junctions > Enable Junctions to change.\n";
        
        } else if (junc.xpNoJunctions()) {
            junctions = "Junctions disabled. Install junctions.exe to \n" + 
                    "World of Warcraft\\Interface\\AddOns\\Soundtrack\\Music Manager\\junction";
        }
        JOptionPane.showMessageDialog(this, "Welcome to Soundtrack Music Manager!\n\n" +
                junctions +
                "Click Junctions > About Junctions for more information.");

        /*String curDir = System.getProperty("user.dir");
        String linkname = curDir + "\\j-SoundtrackMusic";
        File link = new File(linkname);
        try {
            if(!link.exists()){
                junc.createLink(curDir + "\\j-SoundtrackMusic", st.getMusicDir().getPath());
            }
        } catch (IOException ex) {
            Logger.getLogger(SoundtrackMusicGUI.class.getName()).log(Level.SEVERE, null, ex);
        }*/
    }

    /** This method is called from within the constructor to
     * initialize the form.
     * WARNING: Do NOT modify this code. The content of this method is
     * always regenerated by the Form Editor.
     */
    @SuppressWarnings("unchecked")
    // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
    private void initComponents() {

        ScrollPanel = new javax.swing.JScrollPane();
        TextArea = new javax.swing.JTextArea();
        AddFile = new javax.swing.JLabel();
        AddFolder = new javax.swing.JLabel();
        DeleteFile = new javax.swing.JLabel();
        DeleteFolder = new javax.swing.JLabel();
        UpdateSoundtrackMusic = new javax.swing.JLabel();
        jSeparator3 = new javax.swing.JSeparator();
        jSeparator4 = new javax.swing.JSeparator();
        jSeparator5 = new javax.swing.JSeparator();
        GenerateLibrary = new javax.swing.JLabel();
        LibraryErrors = new javax.swing.JLabel();
        MenuBar = new javax.swing.JMenuBar();
        JunctionsMenu = new javax.swing.JMenu();
        EnableJunctions = new javax.swing.JCheckBoxMenuItem();
        AboutJunctions = new javax.swing.JMenuItem();

        setDefaultCloseOperation(javax.swing.WindowConstants.EXIT_ON_CLOSE);
        setTitle("Soundtrack Music Manager");
        setFocusCycleRoot(false);
        setForeground(java.awt.Color.white);
        setLocationByPlatform(true);

        TextArea.setEditable(false);
        TextArea.setColumns(20);
        TextArea.setRows(5);
        TextArea.setText("Music Manager\n  Created by Lunaqua\n  Source Code by Yess (Epic Music Player)\n\nSoundtrack: Music Addon for World of Warcraft\n  Created by Morricone\n  Maintenance by FluffyBearLina, ScizCT\n  Maintained by Lunaqua\n\nFound at:\nhttp://www.curse.com/addons/wow/soundtrack\n");
        ScrollPanel.setViewportView(TextArea);

        AddFile.setIcon(new javax.swing.ImageIcon(getClass().getResource("/Icons/Add File.png"))); // NOI18N
        AddFile.setToolTipText("Add MP3 or OGG file(s)");
        AddFile.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseClicked(java.awt.event.MouseEvent evt) {
                AddFileMouseClicked(evt);
            }
        });

        AddFolder.setIcon(new javax.swing.ImageIcon(getClass().getResource("/Icons/Add Folder.png"))); // NOI18N
        AddFolder.setToolTipText("Add folder(s)");
        AddFolder.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseClicked(java.awt.event.MouseEvent evt) {
                AddFolderMouseClicked(evt);
            }
        });

        DeleteFile.setIcon(new javax.swing.ImageIcon(getClass().getResource("/Icons/Delete File.png"))); // NOI18N
        DeleteFile.setToolTipText("Delete MP3 or OGG file(s)");
        DeleteFile.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseClicked(java.awt.event.MouseEvent evt) {
                DeleteFileMouseClicked(evt);
            }
        });

        DeleteFolder.setIcon(new javax.swing.ImageIcon(getClass().getResource("/Icons/Delete Folder.png"))); // NOI18N
        DeleteFolder.setToolTipText("Delete folder(s)");
        DeleteFolder.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseClicked(java.awt.event.MouseEvent evt) {
                DeleteFolderMouseClicked(evt);
            }
        });

        UpdateSoundtrackMusic.setIcon(new javax.swing.ImageIcon(getClass().getResource("/Icons/Add SoundtrackMusic Folder.png"))); // NOI18N
        UpdateSoundtrackMusic.setToolTipText("Update SoundtrackMusic");
        UpdateSoundtrackMusic.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseClicked(java.awt.event.MouseEvent evt) {
                UpdateSoundtrackMusicMouseClicked(evt);
            }
        });

        jSeparator3.setOrientation(javax.swing.SwingConstants.VERTICAL);

        jSeparator4.setOrientation(javax.swing.SwingConstants.VERTICAL);

        jSeparator5.setOrientation(javax.swing.SwingConstants.VERTICAL);

        GenerateLibrary.setIcon(new javax.swing.ImageIcon(getClass().getResource("/Icons/Generate Library.png"))); // NOI18N
        GenerateLibrary.setToolTipText("Generate Library");
        GenerateLibrary.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseClicked(java.awt.event.MouseEvent evt) {
                GenerateLibraryMouseClicked(evt);
            }
        });

        LibraryErrors.setIcon(new javax.swing.ImageIcon(getClass().getResource("/Icons/Generate Library Errors.png"))); // NOI18N
        LibraryErrors.setToolTipText("List library error(s)");
        LibraryErrors.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseClicked(java.awt.event.MouseEvent evt) {
                LibraryErrorsMouseClicked(evt);
            }
        });

        JunctionsMenu.setText("Junctions");

        EnableJunctions.setSelected(true);
        EnableJunctions.setText("Enable Junctions");
        EnableJunctions.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                EnableJunctionsActionPerformed(evt);
            }
        });
        JunctionsMenu.add(EnableJunctions);

        AboutJunctions.setText("About Junctions");
        AboutJunctions.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                AboutJunctionsActionPerformed(evt);
            }
        });
        JunctionsMenu.add(AboutJunctions);

        MenuBar.add(JunctionsMenu);

        setJMenuBar(MenuBar);

        javax.swing.GroupLayout layout = new javax.swing.GroupLayout(getContentPane());
        getContentPane().setLayout(layout);
        layout.setHorizontalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(layout.createSequentialGroup()
                .addContainerGap()
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                    .addComponent(ScrollPanel, javax.swing.GroupLayout.DEFAULT_SIZE, 760, Short.MAX_VALUE)
                    .addGroup(layout.createSequentialGroup()
                        .addComponent(AddFile)
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                        .addComponent(AddFolder)
                        .addGap(10, 10, 10)
                        .addComponent(jSeparator4, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.UNRELATED)
                        .addComponent(DeleteFile, javax.swing.GroupLayout.PREFERRED_SIZE, 32, javax.swing.GroupLayout.PREFERRED_SIZE)
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                        .addComponent(DeleteFolder)
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.UNRELATED)
                        .addComponent(jSeparator3, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.UNRELATED)
                        .addComponent(UpdateSoundtrackMusic)
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.UNRELATED)
                        .addComponent(jSeparator5, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.UNRELATED)
                        .addComponent(GenerateLibrary)
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.UNRELATED)
                        .addComponent(LibraryErrors)
                        .addGap(0, 0, Short.MAX_VALUE)))
                .addContainerGap())
        );
        layout.setVerticalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(javax.swing.GroupLayout.Alignment.TRAILING, layout.createSequentialGroup()
                .addContainerGap()
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                    .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING, false)
                        .addComponent(UpdateSoundtrackMusic, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                        .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                            .addComponent(AddFile)
                            .addComponent(AddFolder))
                        .addComponent(jSeparator3)
                        .addComponent(jSeparator4, javax.swing.GroupLayout.Alignment.TRAILING)
                        .addComponent(DeleteFile, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                        .addComponent(DeleteFolder, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                        .addComponent(jSeparator5))
                    .addComponent(GenerateLibrary)
                    .addComponent(LibraryErrors))
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addComponent(ScrollPanel, javax.swing.GroupLayout.DEFAULT_SIZE, 239, Short.MAX_VALUE)
                .addContainerGap())
        );

        pack();
    }// </editor-fold>//GEN-END:initComponents


    private void EnableJunctionsActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_EnableJunctionsActionPerformed
        if(EnableJunctions.isSelected()){
            enableJunc = true;
        } else {
            enableJunc = false;
        }
    }//GEN-LAST:event_EnableJunctionsActionPerformed

    private void AboutJunctionsActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_AboutJunctionsActionPerformed
        JOptionPane.showMessageDialog(this,
            "Junctions create a link from one folder to another folder.\n\n" +
            "To delete a junction, go to SoundtrackMusic and manually delete it.\n\n" +
            "WARNING: In Windows XP, when deleting a Junction Point or \n" +
            "a folder containing a Junction Point, ALWAYS use Shift+Del \n" + 
            "to safely delete the link. If not, it is possible to delete the \n" +
            "linked folder, and thus the music inside of the folder.\n\n" +
            "For more information, see:\n" +
            "http://en.wikipedia.org/wiki/NTFS_junction_point",
            "About Junctions", JOptionPane.PLAIN_MESSAGE);
    }//GEN-LAST:event_AboutJunctionsActionPerformed

    private void AddFileMouseClicked(java.awt.event.MouseEvent evt) {//GEN-FIRST:event_AddFileMouseClicked
        TextArea.setText("");
        
        JFileChooser jf = new JFileChooser();
        jf.setFileSelectionMode(JFileChooser.FILES_AND_DIRECTORIES);
        jf.setMultiSelectionEnabled(true);
        if(curAddDir == null){
            jf.setCurrentDirectory(curAddDir);
        }
        int returnVal = jf.showOpenDialog(this);
        curAddDir = jf.getCurrentDirectory();
        File[] files = jf.getSelectedFiles();

        if (returnVal == JFileChooser.APPROVE_OPTION) {
            for (int i = 0; i < files.length; i++){
                File f = files[i];
                String srcpath = f.getPath();
                String musFileName = f.getName();
                String destpath = st.getMusicDir().getPath() + "\\" + musFileName;
                st.addFiles(srcpath, destpath);
            }
        }
        st.log("Summary: Added " + st.getMusicCount() + " music file(s).\n");
    }//GEN-LAST:event_AddFileMouseClicked

    private void AddFolderMouseClicked(java.awt.event.MouseEvent evt) {//GEN-FIRST:event_AddFolderMouseClicked
        TextArea.setText("");
        
        JFileChooser jf = new JFileChooser();
        jf.setFileSelectionMode(JFileChooser.DIRECTORIES_ONLY);
        jf.setMultiSelectionEnabled(true);
        if(curAddDir == null){
            jf.setCurrentDirectory(curAddDir);
        }
        int returnVal = jf.showOpenDialog(this);
        curAddDir = jf.getCurrentDirectory();
        File[] files = jf.getSelectedFiles();

        int junccount = 0;
        if (returnVal == JFileChooser.APPROVE_OPTION) {
            if(enableJunc){  // Create junctions to each folder
                try {
                    for(int i=0; i < files.length; i++){
                        File destf = new File(st.getMusicDir() + "\\" + files[i].getName());
                        String linkname = destf.getParentFile() + "\\j-" + destf.getName();
                        junc.createLink(linkname, files[i].getPath());
                        st.log("Creating junction to " + destf.getPath());
                        junccount++;
                    }
                } catch (IOException ex) {
                    Logger.getLogger(MusicManager.class.getName()).log(Level.SEVERE, null, ex);
                }
            }
            if(!enableJunc){
                for (int i = 0; i < files.length; i++){
                    File f = files[i];
                    String psrcpath = f.getPath();
                    String musDirName = f.getName();
                    String destpath = st.getMusicDir().getPath() + "\\" + musDirName;
                    st.addFiles(psrcpath, destpath);
                }
            }
        }
        if(junccount > 0){
            st.log("Summary: Added " + junccount + " junction(s).\n");
        } else{
            st.log("Summary: Added " + st.getMusicCount() + " music file(s).\n");
        }
    }//GEN-LAST:event_AddFolderMouseClicked

    private void DeleteFileMouseClicked(java.awt.event.MouseEvent evt) {//GEN-FIRST:event_DeleteFileMouseClicked
        TextArea.setText("");
        
        JFileChooser jf = new JFileChooser();
        jf.setFileSelectionMode(JFileChooser.FILES_AND_DIRECTORIES);
        jf.setMultiSelectionEnabled(true);
        jf.setCurrentDirectory(st.getMusicDir());
        int returnVal = jf.showOpenDialog(this);
        File[] files = jf.getSelectedFiles();

        if (returnVal == JFileChooser.APPROVE_OPTION) {
            for (int i = 0; i < files.length; i++){
                File f = files[i];
                String musFileName = f.getName();
                String destpath = st.getMusicDir().getPath() + "\\" + musFileName;
                st.deleteFiles(destpath);
            }
        }
        
        st.log("Summary: Deleted " + st.getMusicCount() + " music file(s).\n");
    }//GEN-LAST:event_DeleteFileMouseClicked

    private void DeleteFolderMouseClicked(java.awt.event.MouseEvent evt) {//GEN-FIRST:event_DeleteFolderMouseClicked
        TextArea.setText("");
        
        JFileChooser jf = new JFileChooser();
        jf.setFileSelectionMode(JFileChooser.DIRECTORIES_ONLY);
        jf.setMultiSelectionEnabled(true);
        jf.setCurrentDirectory(st.getMusicDir());
        int returnVal = jf.showOpenDialog(this);
        File[] files = jf.getSelectedFiles();

        int junccount = 0;
        if (returnVal == JFileChooser.APPROVE_OPTION) {
            for (int i = 0; i < files.length; i++){
                if(files[i].getName().contains("j-") || files[i].getName().contains("junction-")){
                    boolean deleted = files[i].delete();
                    junccount++;
                } else{
                    File f = files[i];
                    String musDirName = f.getName();
                    File destpath = new File(st.getMusicDir().getPath() + "\\" + musDirName);
                    //JOptionPane.showMessageDialog(this, "Deleting " + destpath);
                    st.deleteFiles(destpath.getPath());
                    destpath.delete();
                }
            }
        }

        st.log("Summary: Deleted " + junccount + " junction(s).");
        st.log("Summary: Deleted " + st.getMusicCount() + " music file(s).\n");
    }//GEN-LAST:event_DeleteFolderMouseClicked

    private void UpdateSoundtrackMusicMouseClicked(java.awt.event.MouseEvent evt) {//GEN-FIRST:event_UpdateSoundtrackMusicMouseClicked
        TextArea.setText("");
        // st.addFiles(st.getMusicDir().getPath(), st.getMusicDir().getPath());
        st.log("SoundtrackMusic updated.");
    }//GEN-LAST:event_UpdateSoundtrackMusicMouseClicked

    private void GenerateLibraryMouseClicked(java.awt.event.MouseEvent evt) {//GEN-FIRST:event_GenerateLibraryMouseClicked
        GenerateLibrary.setEnabled(false);
        TextArea.setText("");
        st.generateMyLibrary();
        GenerateLibrary.setEnabled(true);
    }//GEN-LAST:event_GenerateLibraryMouseClicked

    private void LibraryErrorsMouseClicked(java.awt.event.MouseEvent evt) {//GEN-FIRST:event_LibraryErrorsMouseClicked
        TextArea.setText("");
        st.getGenLibErrors();
    }//GEN-LAST:event_LibraryErrorsMouseClicked

    /**
    * @param args the command line arguments
    */
    public static void main(String args[]) {
        java.awt.EventQueue.invokeLater(new Runnable() {
            public void run() {
                new MusicManager().setVisible(true);
            }
        });
    }
    // Variables declaration - do not modify//GEN-BEGIN:variables
    private javax.swing.JMenuItem AboutJunctions;
    private javax.swing.JLabel AddFile;
    private javax.swing.JLabel AddFolder;
    private javax.swing.JLabel DeleteFile;
    private javax.swing.JLabel DeleteFolder;
    private javax.swing.JCheckBoxMenuItem EnableJunctions;
    private javax.swing.JLabel GenerateLibrary;
    private javax.swing.JMenu JunctionsMenu;
    private javax.swing.JLabel LibraryErrors;
    private javax.swing.JMenuBar MenuBar;
    private javax.swing.JScrollPane ScrollPanel;
    private javax.swing.JTextArea TextArea;
    private javax.swing.JLabel UpdateSoundtrackMusic;
    private javax.swing.JSeparator jSeparator3;
    private javax.swing.JSeparator jSeparator4;
    private javax.swing.JSeparator jSeparator5;
    // End of variables declaration//GEN-END:variables

}