/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package app.bay_module;

/**
 *
 * @author gregd
 */
public class BayModulePanel extends javax.swing.JPanel {

	/**
	 * Creates new form BayModulePanel
	 */
	public BayModulePanel() {
		initComponents();
	}

	/**
	 * This method is called from within the constructor to initialize the
	 * form. WARNING: Do NOT modify this code. The content of this method is
	 * always regenerated by the Form Editor.
	 */
	@SuppressWarnings("unchecked")
    // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
    private void initComponents() {

        lights_panel = new javax.swing.JPanel();
        bay_address = new javax.swing.JLabel();

        setLayout(new javax.swing.BoxLayout(this, javax.swing.BoxLayout.PAGE_AXIS));

        lights_panel.setBackground(new java.awt.Color(0, 0, 0));
        lights_panel.setForeground(new java.awt.Color(255, 255, 255));
        lights_panel.setLayout(new java.awt.GridBagLayout());
        add(lights_panel);

        bay_address.setText("jLabel1");
        bay_address.setVisible(false);
        add(bay_address);
    }// </editor-fold>//GEN-END:initComponents
    // Variables declaration - do not modify//GEN-BEGIN:variables
    private javax.swing.JLabel bay_address;
    private javax.swing.JPanel lights_panel;
    // End of variables declaration//GEN-END:variables
}
