/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

/*
 * D4Module.java
 *
 * Created on Oct 14, 2011, 9:39:33 AM
 */
package app.lt_module;

import app.oc_module.*;


/**
 *
 * @author gregd
 */
public class LtModulePanel extends javax.swing.JPanel {

    /** Creates new form D4Module */
    public LtModulePanel() {
        initComponents();
    }

    /** This method is called from within the constructor to
     * initialize the form.
     * WARNING: Do NOT modify this code. The content of this method is
     * always regenerated by the Form Editor.
     */
    @SuppressWarnings("unchecked")
    // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
    private void initComponents() {

        displayText = new javax.swing.JTextField();

        setBackground(new java.awt.Color(97, 97, 75));
        setBorder(javax.swing.BorderFactory.createLineBorder(new java.awt.Color(0, 0, 0)));
        setMaximumSize(new java.awt.Dimension(320, 80));
        setMinimumSize(new java.awt.Dimension(320, 80));
        setPreferredSize(new java.awt.Dimension(320, 80));
        setVerifyInputWhenFocusTarget(false);

        displayText.setBackground(java.awt.Color.darkGray);
        displayText.setEditable(false);
        displayText.setFont(new java.awt.Font("Monospaced", 1, 29)); // NOI18N
        displayText.setForeground(java.awt.Color.red);
        displayText.setText("PYRMD OR KG BX");
        displayText.setDoubleBuffered(true);
        displayText.setMaximumSize(new java.awt.Dimension(210, 40));
        displayText.setMinimumSize(new java.awt.Dimension(210, 40));
        displayText.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                displayTextActionPerformed(evt);
            }
        });

        javax.swing.GroupLayout layout = new javax.swing.GroupLayout(this);
        this.setLayout(layout);
        layout.setHorizontalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(layout.createSequentialGroup()
                .addGap(39, 39, 39)
                .addComponent(displayText, javax.swing.GroupLayout.DEFAULT_SIZE, 231, Short.MAX_VALUE)
                .addGap(48, 48, 48))
        );
        layout.setVerticalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(layout.createSequentialGroup()
                .addGap(12, 12, 12)
                .addComponent(displayText, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                .addGap(22, 22, 22))
        );
    }// </editor-fold>//GEN-END:initComponents

  private void displayTextActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_displayTextActionPerformed
    // TODO add your handling code here:
  }//GEN-LAST:event_displayTextActionPerformed



    // Variables declaration - do not modify//GEN-BEGIN:variables
    private javax.swing.JTextField displayText;
    // End of variables declaration//GEN-END:variables
}